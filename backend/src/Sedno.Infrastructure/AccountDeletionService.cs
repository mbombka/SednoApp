using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Google.Cloud.Firestore;
using Sedno.Domain;
using Sedno.Application;

namespace Sedno.Infrastructure;

public interface IIdentityAccountDeletion
{
    Task DeleteAsync(string uid, CancellationToken ct);
    Task<IdentityAccountStatus> GetStatusAsync(string uid, CancellationToken ct);
}

public sealed class FirebaseAccountDeletion(HttpClient client, IPlayAccessTokenSource tokens, string project) : IIdentityAccountDeletion
{
    public async Task<IdentityAccountStatus> GetStatusAsync(string uid, CancellationToken ct)
    {
        using var request = new HttpRequestMessage(HttpMethod.Post,
            $"https://identitytoolkit.googleapis.com/v1/projects/{Uri.EscapeDataString(project)}/accounts:lookup");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", await tokens.GetAsync(ct));
        request.Content = JsonContent.Create(new { localId = new[] { uid } });
        using var response = await client.SendAsync(request, ct);
        response.EnsureSuccessStatusCode();
        using var body = JsonDocument.Parse(await response.Content.ReadAsStringAsync(ct));
        if (body.RootElement.TryGetProperty("users", out var users))
            foreach (var user in users.EnumerateArray())
                if (user.GetProperty("localId").GetString() == uid)
                    return new(!user.TryGetProperty("disabled", out var disabled) || !disabled.GetBoolean(),
                        user.TryGetProperty("validSince", out var since)
                            ? long.Parse(since.GetString()!, System.Globalization.CultureInfo.InvariantCulture) : 0);
        return new(false, 0);
    }

    public async Task DeleteAsync(string uid, CancellationToken ct)
    {
        using var request = new HttpRequestMessage(HttpMethod.Post,
            $"https://identitytoolkit.googleapis.com/v1/projects/{Uri.EscapeDataString(project)}/accounts:delete");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", await tokens.GetAsync(ct));
        request.Content = JsonContent.Create(new { localId = uid });
        using var response = await client.SendAsync(request, ct);
        if (response.IsSuccessStatusCode) return;
        // A retry after Firebase succeeded but the database commit failed is safe.
        if (response.StatusCode == System.Net.HttpStatusCode.BadRequest)
        {
            using var body = JsonDocument.Parse(await response.Content.ReadAsStringAsync(ct));
            if (body.RootElement.TryGetProperty("error", out var error) &&
                error.TryGetProperty("message", out var message) && message.GetString() == "USER_NOT_FOUND") return;
        }
        throw new InvalidOperationException("Identity deletion failed.");
    }
}

public sealed class UnavailableAccountDeletion : IIdentityAccountDeletion
{
    public Task<IdentityAccountStatus> GetStatusAsync(string uid, CancellationToken ct) => Task.FromResult(new IdentityAccountStatus(false, 0));
    public Task DeleteAsync(string uid, CancellationToken ct) =>
        throw new InvalidOperationException("Identity deletion is not configured.");
}

public sealed class AccountDeletionService(FirestoreStore db, IIdentityAccountDeletion identity, TimeProvider clock)
{
    public async Task<bool> DeleteWithReauthenticationAsync(SessionIdentity session, VerifiedIdentity verified, CancellationToken ct)
    {
        if (session.AccountId is not Guid accountId) return false;
        var account = await db.GetAsync<VerifiedAccount>(db.Accounts.Document(FirestoreStore.Id(accountId)), ct);
        var credential = await db.GetAsync<GuestSession>(db.Sessions.Document(FirestoreStore.Id(session.SessionId)), ct);
        var now = clock.GetUtcNow().ToUnixTimeSeconds();
        if (account is null || credential?.FirebaseAuthTime is not long sessionAuthTime ||
            verified.Uid != account.FirebaseUid || verified.AuthTime > now || verified.AuthTime < now - 300 ||
            (verified.Provider == "email" && !verified.EmailVerified)) return false;
        // Always bypass the instance cache, including for a still-valid Sedno bearer.
        var status = await identity.GetStatusAsync(account.FirebaseUid, ct);
        if (!status.Allows(sessionAuthTime) || !status.Allows(verified.AuthTime)) return false;
        await DeleteAsync(session, ct);
        return true;
    }

    public async Task DeleteAsync(SessionIdentity session, CancellationToken ct)
    {
        if (session.AccountId is not Guid accountId) throw new InvalidOperationException("Account required.");
        var reference = db.Accounts.Document(FirestoreStore.Id(accountId));
        var account = await db.GetAsync<VerifiedAccount>(reference, ct);
        if (account is null) return;
        await using var uidLease = await FirestoreLease.AcquireAsync(db, "uid:" + account.FirebaseUid, clock, ct);
        await using var accountLease = await FirestoreLease.AcquireAsync(db, "account:" + accountId.ToString("N"), clock, ct);
        // Persist a tombstone before external I/O. Every writer reads the account or
        // identity in its transaction, so no new child can race physical deletion.
        await db.Database.RunTransactionAsync(async transaction =>
        {
            await uidLease.CheckAsync(transaction, ct);
            await accountLease.CheckAsync(transaction, ct);
            var current = await db.GetAsync<VerifiedAccount>(transaction, reference, ct);
            if (current is null) return;
            current.Deleting = true;
            db.Put(transaction, reference, current);
        }, cancellationToken: ct);
        // Even a timeout may mean Firebase already deleted the user. Keep the
        // tombstone on failure so the hourly job resumes instead of restoring access.
        // The scheduled cleanup resumes if Firebase deletion invalidated the bearer.
        await identity.DeleteAsync(account.FirebaseUid, ct);
        var identities = await db.ListAsync<GuestIdentity>(db.Identities.WhereEqualTo("AccountId", accountId.ToString()), ct);
        foreach (var linked in identities)
        {
            await DeleteQueryAsync(db.Requests.WhereEqualTo("IdentityId", linked.Id.ToString()), ct);
            await DeleteQueryAsync(db.Sessions.WhereEqualTo("IdentityId", linked.Id.ToString()), ct);
        }
        await DeleteQueryAsync(db.Sessions.WhereEqualTo("AccountId", accountId.ToString()), ct);
        await DeleteQueryAsync(db.Purchases.WhereEqualTo("AccountId", accountId.ToString()), ct);
        // Shared installation ledgers may also contain another account's usage.
        // Remove only the deleted identities, retaining other users' allowances.
        var ids = identities.Select(x => FirestoreStore.Id(x.Id)).ToHashSet();
        foreach (var hash in account.InstallationHashes)
        {
            var days = await db.DailyUsage.WhereEqualTo("InstallationHash", hash).GetSnapshotAsync(ct);
            foreach (var day in days.Documents)
                await db.Database.RunTransactionAsync(async transaction =>
                {
                    await accountLease.CheckAsync(transaction, ct);
                    var usage = await db.GetAsync<DailyUsage>(transaction, day.Reference, ct);
                    if (usage is null) return;
                    foreach (var id in ids) usage.Used.Remove(id);
                    foreach (var key in usage.Reservations.Where(x => ids.Contains(FirestoreStore.Id(x.Value.IdentityId))).Select(x => x.Key).ToArray())
                        usage.Reservations.Remove(key);
                    if (usage.Used.Count == 0 && usage.Reservations.Count == 0) transaction.Delete(day.Reference);
                    else db.Put(transaction, day.Reference, usage);
                }, cancellationToken: ct);
        }
        // Keep identities until ledger cleanup finishes, enabling recovery after a
        // process crash. A later DELETE or scheduled cleanup resumes the tombstone.
        await DeleteQueryAsync(db.Identities.WhereEqualTo("AccountId", accountId.ToString()), ct);
        await db.Database.RunTransactionAsync(async transaction =>
        {
            await uidLease.CheckAsync(transaction, ct);
            await accountLease.CheckAsync(transaction, ct);
            transaction.Delete(db.Uids.Document(FirestoreStore.Hash(account.FirebaseUid)));
            transaction.Delete(db.Bindings.Document(SubscriptionService.Binding(accountId)));
            transaction.Delete(reference);
        }, cancellationToken: ct);
    }

    private async Task DeleteQueryAsync(Query query, CancellationToken ct)
    {
        while (true)
        {
            var page = await query.Limit(200).GetSnapshotAsync(ct);
            if (page.Count == 0) return;
            var batch = db.Database.StartBatch();
            foreach (var document in page.Documents) batch.Delete(document.Reference, Precondition.LastUpdated(document.UpdateTime!.Value));
            await batch.CommitAsync(ct);
        }
    }
}
