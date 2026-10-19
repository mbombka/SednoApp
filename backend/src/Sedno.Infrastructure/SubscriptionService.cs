using Microsoft.AspNetCore.DataProtection;
using Sedno.Application;
using Sedno.Domain;

namespace Sedno.Infrastructure;

public sealed class SubscriptionService(FirestoreStore db, IPlayBillingClient play, IDataProtectionProvider protection, TimeProvider clock) : IEntitlementResolver
{
    private readonly IDataProtector _protector = protection.CreateProtector("Sedno.PlayPurchase.v1");
    public static string Binding(Guid accountId) => FirestoreStore.Hash("sedno-account:" + accountId.ToString("N"));
    public static readonly TimeSpan VerificationLifetime = TimeSpan.FromMinutes(15);

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
        var rows = await db.ListAsync<PlayPurchase>(db.Purchases.WhereEqualTo("AccountId", accountId.ToString()).WhereEqualTo("Revoked", false), ct);
        var now = clock.GetUtcNow();
        return rows.Any(x => x.VerifiedAt > now - VerificationLifetime && x.VerifiedAt <= now && x.ExpiresAt > now &&
            x.State is "SUBSCRIPTION_STATE_ACTIVE" or "SUBSCRIPTION_STATE_IN_GRACE_PERIOD" or "SUBSCRIPTION_STATE_CANCELED");
    }

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
            row.State = status.State; row.ExpiresAt = status.ExpiresAt; row.VerifiedAt = clock.GetUtcNow();
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
