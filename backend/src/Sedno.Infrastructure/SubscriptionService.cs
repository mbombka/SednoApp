using Microsoft.AspNetCore.DataProtection;
using Sedno.Application;
using Sedno.Domain;

namespace Sedno.Infrastructure;

public sealed class SubscriptionService(FirestoreStore db, IPlayBillingClient play, IDataProtectionProvider protection, TimeProvider clock) : IEntitlementResolver
{
    private static readonly TimeSpan VerificationLife = TimeSpan.FromMinutes(15);
    private static readonly TimeSpan RefreshRetryDelay = TimeSpan.FromMinutes(1);
    private static readonly TimeSpan RefreshTimeout = TimeSpan.FromSeconds(2);
    private readonly IDataProtector _protector = protection.CreateProtector("Sedno.PlayPurchase.v1");
    public static string Binding(Guid accountId) => FirestoreStore.Hash("sedno-account:" + accountId.ToString("N"));

    public async Task<SubscriptionDto> CurrentAsync(Guid accountId, CancellationToken ct)
    {
        await using var lease = await FirestoreLease.AcquireAsync(db, "account:" + accountId.ToString("N"), clock, ct);
        var rows = await db.ListAsync<PlayPurchase>(db.Purchases.WhereEqualTo("AccountId", accountId.ToString()).WhereEqualTo("Revoked", false), ct);
        SubscriptionDto? best = null;
        foreach (var row in rows)
        {
            var status = await UpdateAsync(accountId, _protector.Unprotect(row.ProtectedToken), lease, null, ct);
            if (best is null || (!best.Active && status.Active) || (status.Active == best.Active && status.ExpiresAt > best.ExpiresAt)) best = status;
        }
        return best ?? new("none", false, null, Binding(accountId));
    }

    public async Task<bool> HasSubscriptionAsync(Guid identityId, CancellationToken ct)
    {
        var identity = await db.GetAsync<GuestIdentity>(db.Identities.Document(FirestoreStore.Id(identityId)), ct);
        if (identity?.AccountId is not Guid accountId) return false;
        var rows = await PurchasesAsync(accountId, ct);
        if (rows.Any(Entitled)) return true;
        // The common path is read-only: no lease, writes or Google calls.
        if (!rows.Any(NeedsRefresh)) return false;

        await using var lease = await FirestoreLease.AcquireAsync(db, "account:" + accountId.ToString("N"), clock, ct);
        // Another replica, RTDN or the subscription screen may have refreshed while
        // we waited. Re-read before deciding whether to contact Google.
        rows = await PurchasesAsync(accountId, ct);
        if (rows.Any(Entitled)) return true;
        foreach (var row in rows.Where(NeedsRefresh))
        {
            var reference = db.Purchases.Document(row.TokenHash);
            try
            {
                // Leave room in the simplification deadline for free-tier fallback.
                using var timeout = new CancellationTokenSource(RefreshTimeout, clock);
                using var refresh = CancellationTokenSource.CreateLinkedTokenSource(ct, timeout.Token);
                if ((await UpdateAsync(accountId, _protector.Unprotect(row.ProtectedToken), lease, null, refresh.Token)).Active)
                    return true;
            }
            catch (Exception ex) when (ex is
                InvalidOperationException or HttpRequestException or IOException or OperationCanceledException or
                System.Text.Json.JsonException or FormatException or KeyNotFoundException or
                System.Security.Cryptography.CryptographicException)
            {
                // Fail closed. Persist a shared cooldown without extending the last
                // successful verification. RTDN bypasses it and still retries errors.
                // Also retain the cooldown if the requesting client disconnects.
                using var failureTimeout = new CancellationTokenSource(RefreshTimeout);
                var failureCt = failureTimeout.Token;
                await db.Database.RunTransactionAsync(async transaction =>
                {
                    await lease.CheckAsync(transaction, failureCt);
                    var current = await db.GetAsync<PlayPurchase>(transaction, reference, failureCt);
                    if (current is null || current.AccountId != accountId || current.Revoked || Fresh(current)) return;
                    current.RefreshNotBefore = clock.GetUtcNow().Add(RefreshRetryDelay);
                    db.Put(transaction, reference, current);
                }, cancellationToken: failureCt);
                ct.ThrowIfCancellationRequested();
            }
        }
        return false;
    }

    private Task<List<PlayPurchase>> PurchasesAsync(Guid accountId, CancellationToken ct) =>
        db.ListAsync<PlayPurchase>(db.Purchases.WhereEqualTo("AccountId", accountId.ToString()).WhereEqualTo("Revoked", false), ct);

    private bool Fresh(PlayPurchase row) => row.VerifiedAt is { } verified &&
        verified <= clock.GetUtcNow() && verified > clock.GetUtcNow().Subtract(VerificationLife);

    private bool Entitled(PlayPurchase row) => !row.Revoked && Fresh(row) &&
        new PlaySubscription(row.State, row.ExpiresAt, true, null).Entitled(clock.GetUtcNow());

    private bool NeedsRefresh(PlayPurchase row) => !row.Revoked && !Fresh(row) &&
        !(row.RefreshNotBefore > clock.GetUtcNow());

    public async Task<SubscriptionDto> VerifyAsync(Guid accountId, string token, CancellationToken ct)
    {
        await using var lease = await FirestoreLease.AcquireAsync(db, "account:" + accountId.ToString("N"), clock, ct);
        return await UpdateAsync(accountId, token, lease, null, ct);
    }

    public async Task NotifyAsync(string messageId, string token, CancellationToken ct)
    {
        var notification = db.PlayNotifications.Document(FirestoreStore.Hash(messageId));
        if ((await notification.GetSnapshotAsync(ct)).Exists) return;
        var row = await db.GetAsync<PlayPurchase>(db.Purchases.Document(FirestoreStore.Hash(token)), ct);
        var accountId = row?.AccountId;
        if (accountId is null)
        {
            var verified = await play.GetAsync(token, ct);
            var pointer = verified.AccountBinding is null ? null : await db.GetAsync<AccountPointer>(db.Bindings.Document(verified.AccountBinding), ct);
            accountId = pointer?.AccountId;
        }
        if (accountId is null) throw new InvalidOperationException("Unknown purchase owner.");
        await using var lease = await FirestoreLease.AcquireAsync(db, "account:" + accountId.Value.ToString("N"), clock, ct);
        if ((await notification.GetSnapshotAsync(ct)).Exists) return;
        await UpdateAsync(accountId.Value, token, lease, messageId, ct);
    }

    private async Task<SubscriptionDto> UpdateAsync(Guid accountId, string token, FirestoreLease lease, string? messageId, CancellationToken ct)
    {
        var accountReference = db.Accounts.Document(FirestoreStore.Id(accountId));
        var account = await db.GetAsync<VerifiedAccount>(accountReference, ct);
        if (account is null || account.Deleting) throw new InvalidOperationException("Account unavailable.");
        var status = await play.GetAsync(token, ct);
        var verifiedAt = clock.GetUtcNow();
        var reference = db.Purchases.Document(FirestoreStore.Hash(token));
        var existing = await db.GetAsync<PlayPurchase>(reference, ct);
        ValidateOwner(existing);
        if (existing?.Revoked != true && status.Entitled(clock.GetUtcNow()) && !status.Acknowledged)
            await play.AcknowledgeAsync(token, ct);
        // No external calls in this retryable callback. The account lease serializes
        // verification, RTDN and deletion; token ownership is checked transactionally.
        return await db.Database.RunTransactionAsync(async transaction =>
        {
            await lease.CheckAsync(transaction, ct);
            var currentAccount = await db.GetAsync<VerifiedAccount>(transaction, accountReference, ct);
            if (currentAccount is null || currentAccount.Deleting) throw new InvalidOperationException("Account unavailable.");
            var row = await db.GetAsync<PlayPurchase>(transaction, reference, ct);
            ValidateOwner(row);
            var oldReference = status.LinkedToken is null ? null : db.Purchases.Document(FirestoreStore.Hash(status.LinkedToken));
            var old = oldReference is null ? null : await db.GetAsync<PlayPurchase>(transaction, oldReference, ct);
            if (old is not null && status.Entitled(clock.GetUtcNow()) && old.AccountId != accountId)
                throw new InvalidOperationException("Linked owner mismatch.");
            row ??= new() { TokenHash = reference.Id, ProtectedToken = _protector.Protect(token), AccountId = accountId };
            row.State = status.State; row.ExpiresAt = status.ExpiresAt; row.VerifiedAt = verifiedAt;
            row.RefreshNotBefore = null;
            if (old is not null && status.Entitled(clock.GetUtcNow())) { old.Revoked = true; db.Put(transaction, oldReference!, old); }
            db.Put(transaction, reference, row);
            if (messageId is not null) db.Put(transaction, db.PlayNotifications.Document(FirestoreStore.Hash(messageId)),
                new PlayNotification { Id = messageId, ProcessedAt = clock.GetUtcNow() });
            return new SubscriptionDto(row.Revoked ? "revoked" : status.State,
                !row.Revoked && status.Entitled(clock.GetUtcNow()), status.ExpiresAt, Binding(accountId));
        }, cancellationToken: ct);

        void ValidateOwner(PlayPurchase? row)
        {
            if (status.AccountBinding != Binding(accountId) && !(row?.AccountId == accountId && status.AccountBinding is null && status.State == "SUBSCRIPTION_STATE_EXPIRED"))
                throw new InvalidOperationException("Purchase owner mismatch.");
            if (row is not null && row.AccountId != accountId) throw new InvalidOperationException("Purchase already owned.");
        }
    }
}
