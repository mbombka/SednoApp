using Google.Cloud.Firestore;
using Sedno.Application;
using Sedno.Domain;

namespace Sedno.Infrastructure;

// Uses the existing Firestore database/IAM identity and account lease. Google and
// Apple are alternate evidence for one entitlement; their daily limits never add.
public sealed class AppleSubscriptionService(FirestoreStore db, IAppleBillingClient apple,
    AppleBillingOptions options, TimeProvider clock) : IEntitlementResolver
{
    private CollectionReference Purchases => db.Database.Collection("apple_purchases");
    private CollectionReference Notifications => db.Database.Collection("apple_notifications");
    private static readonly TimeSpan VerificationLife = TimeSpan.FromMinutes(15);
    public static string Binding(Guid accountId)
    {
        // A UUID accepted by StoreKit appAccountToken, independent of the Google binding.
        var hash = Convert.FromHexString(FirestoreStore.Hash("sedno-apple-account:" + accountId.ToString("N")));
        return new Guid(hash.AsSpan(0, 16)).ToString();
    }
    private string PurchaseKey(string original) => FirestoreStore.Hash(options.Environment + ":" + original);
    private Task<List<ApplePurchase>> RowsAsync(Guid account, CancellationToken ct) =>
        db.ListAsync<ApplePurchase>(Purchases.WhereEqualTo("AccountId", account.ToString()).WhereEqualTo("Environment", options.Environment), ct);
    private bool Fresh(ApplePurchase row) => row.VerifiedAt <= clock.GetUtcNow() && row.VerifiedAt > clock.GetUtcNow() - VerificationLife;
    private bool Entitled(ApplePurchase row) => Fresh(row) && row.Status.Entitled(clock.GetUtcNow());

    public async Task<bool> HasSubscriptionAsync(Guid identityId, CancellationToken ct)
    {
        if (!options.Enabled) return false;
        var identity = await db.GetAsync<GuestIdentity>(db.Identities.Document(FirestoreStore.Id(identityId)), ct);
        if (identity?.AccountId is not Guid accountId) return false;
        var rows = await RowsAsync(accountId, ct);
        if (rows.Any(Entitled)) return true;
        if (!rows.Any(x => !Fresh(x) && !(x.RefreshNotBefore > clock.GetUtcNow()))) return false;
        await using var lease = await FirestoreLease.AcquireAsync(db, "account:" + accountId.ToString("N"), clock, ct);
        rows = await RowsAsync(accountId, ct);
        if (rows.Any(Entitled)) return true;
        foreach (var row in rows.Where(x => !Fresh(x) && !(x.RefreshNotBefore > clock.GetUtcNow())))
        {
            try
            {
                using var timeout = new CancellationTokenSource(TimeSpan.FromSeconds(2), clock);
                using var linked = CancellationTokenSource.CreateLinkedTokenSource(ct, timeout.Token);
                if ((await UpdateAsync(accountId, row.Status.OriginalTransactionId, lease, null, linked.Token)).Active) return true;
            }
            catch (Exception ex) when (ex is InvalidOperationException or HttpRequestException or IOException or
                OperationCanceledException or System.Text.Json.JsonException or FormatException or KeyNotFoundException or
                System.Security.Cryptography.CryptographicException)
            {
                // A failed verification never extends access. Share a short cooldown
                // across API replicas to keep failed store requests out of the AI deadline.
                using var failureTimeout = new CancellationTokenSource(TimeSpan.FromSeconds(2));
                await db.Database.RunTransactionAsync(async transaction =>
                {
                    await lease.CheckAsync(transaction, failureTimeout.Token);
                    var reference = Purchases.Document(PurchaseKey(row.Status.OriginalTransactionId));
                    var current = await db.GetAsync<ApplePurchase>(transaction, reference, failureTimeout.Token);
                    if (current is null || current.AccountId != accountId || Fresh(current)) return;
                    current.RefreshNotBefore = clock.GetUtcNow().AddMinutes(1);
                    db.Put(transaction, reference, current);
                }, cancellationToken: failureTimeout.Token);
                ct.ThrowIfCancellationRequested();
            }
        }
        return false;
    }

    public async Task<SubscriptionDto> CurrentAsync(Guid accountId, CancellationToken ct)
    {
        RequireEnabled();
        await using var lease = await FirestoreLease.AcquireAsync(db, "account:" + accountId.ToString("N"), clock, ct);
        SubscriptionDto? best = null;
        foreach (var row in await RowsAsync(accountId, ct))
        {
            var status = await UpdateAsync(accountId, row.Status.OriginalTransactionId, lease, null, ct);
            if (best is null || (!best.Active && status.Active) || (status.Active == best.Active && status.ExpiresAt > best.ExpiresAt)) best = status;
        }
        return best ?? new("none", false, null, Binding(accountId), "app_store");
    }

    public async Task<SubscriptionDto> VerifyAsync(Guid accountId, string transactionId, CancellationToken ct)
    {
        RequireEnabled();
        await using var lease = await FirestoreLease.AcquireAsync(db, "account:" + accountId.ToString("N"), clock, ct);
        return await UpdateAsync(accountId, transactionId, lease, null, ct);
    }

    public async Task NotifyAsync(string signedPayload, CancellationToken ct)
    {
        RequireEnabled();
        var notification = apple.VerifyNotification(signedPayload);
        if (notification.OriginalTransactionId is null) return; // authenticated TEST
        var notice = Notifications.Document(FirestoreStore.Hash(options.Environment + ":" + notification.Id));
        if ((await notice.GetSnapshotAsync(ct)).Exists) return;
        var row = await db.GetAsync<ApplePurchase>(Purchases.Document(PurchaseKey(notification.OriginalTransactionId)), ct);
        // Unknown purchases grant nothing. First authenticated verification will fetch
        // current store state, so a notification arriving before registration is safe.
        if (row is null) return;
        await using var lease = await FirestoreLease.AcquireAsync(db, "account:" + row.AccountId.ToString("N"), clock, ct);
        if ((await notice.GetSnapshotAsync(ct)).Exists) return;
        // Never apply notification state directly: delayed/out-of-order notifications
        // always cause a new authoritative lookup while holding the account lease.
        await UpdateAsync(row.AccountId, notification.OriginalTransactionId, lease, notification.Id, ct);
    }

    private async Task<SubscriptionDto> UpdateAsync(Guid accountId, string transactionId, FirestoreLease lease,
        string? notificationId, CancellationToken ct)
    {
        var status = await apple.GetAsync(transactionId, ct);
        if (!Guid.TryParse(status.AccountToken, out var token) || token.ToString() != Binding(accountId))
            throw new InvalidOperationException("Apple purchase account mismatch.");
        var verifiedAt = clock.GetUtcNow();
        var reference = Purchases.Document(PurchaseKey(status.OriginalTransactionId));
        return await db.Database.RunTransactionAsync(async transaction =>
        {
            await lease.CheckAsync(transaction, ct);
            var account = await db.GetAsync<VerifiedAccount>(transaction, db.Accounts.Document(FirestoreStore.Id(accountId)), ct);
            var existing = await db.GetAsync<ApplePurchase>(transaction, reference, ct);
            if (account is null || account.Deleting) throw new InvalidOperationException("Account unavailable.");
            if (existing is not null && existing.AccountId != accountId)
                throw new InvalidOperationException("Apple subscription already owned.");
            db.Put(transaction, reference, new ApplePurchase { AccountId = accountId, Environment = options.Environment, Status = status, VerifiedAt = verifiedAt });
            if (notificationId is not null)
                db.Put(transaction, Notifications.Document(FirestoreStore.Hash(options.Environment + ":" + notificationId)),
                    new AppleNotificationRecord { AccountId = accountId, ProcessedAt = clock.GetUtcNow() });
            return new SubscriptionDto(status.State, status.Entitled(clock.GetUtcNow()), status.ExpiresAt, Binding(accountId), "app_store");
        }, cancellationToken: ct);
    }
    private void RequireEnabled() { if (!options.Enabled) throw new InvalidOperationException("Apple billing unavailable."); }
}

public sealed class ApplePurchase
{
    public string Environment { get; set; } = "";
    public Guid AccountId { get; set; }
    public AppleSubscription Status { get; set; } = new("", "", "", "inactive", null, DateTimeOffset.MinValue, false);
    public DateTimeOffset VerifiedAt { get; set; }
    public DateTimeOffset? RefreshNotBefore { get; set; }
}
public sealed class AppleNotificationRecord
{
    public Guid AccountId { get; set; }
    public DateTimeOffset ProcessedAt { get; set; }
}

public sealed class DisabledAppleBillingClient : IAppleBillingClient
{
    public Task<AppleSubscription> GetAsync(string transactionId, CancellationToken ct) => throw new InvalidOperationException("Apple billing unavailable.");
    public AppleNotification VerifyNotification(string signedPayload) => throw new InvalidOperationException("Apple billing unavailable.");
}

public sealed class StoreEntitlementResolver(SubscriptionService play, AppleSubscriptionService apple,
    AppleBillingOptions options, bool playEnabled) : IEntitlementResolver
{
    public async Task<bool> HasSubscriptionAsync(Guid identityId, CancellationToken ct) =>
        (playEnabled && await play.HasSubscriptionAsync(identityId, ct)) ||
        (options.Enabled && await apple.HasSubscriptionAsync(identityId, ct));
}
