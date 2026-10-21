using Google.Cloud.Firestore;
using Google.Api.Gax.Grpc;
using Sedno.Application;
using Sedno.Domain;

namespace Sedno.Infrastructure;

public sealed class UsageStore(FirestoreStore db, IEntitlementResolver entitlements, TimeProvider clock, SimplificationTimings? timings = null) : IUsageStore
{
    private static readonly TimeSpan ReservationLife = TimeSpan.FromMinutes(5);
    // Bound contention retries within the API deadline, including the first write
    // to a daily ledger that several sessions may try to create simultaneously.
    private static readonly TransactionOptions QuotaTransactions = TransactionOptions.ForRetrySettings(
        RetrySettings.FromExponentialBackoff(10, TimeSpan.FromMilliseconds(25),
            TimeSpan.FromMilliseconds(250), 1.5, _ => true));
    // UsageStore is request-scoped. A simplification reads quota at reservation and
    // again after completion; one entitlement lookup per request is sufficient.
    private (Guid IdentityId, bool Paid)? _entitlement;

    private async Task<bool> PaidAsync(Guid identityId, CancellationToken ct)
    {
        if (_entitlement is { } cached && cached.IdentityId == identityId) return cached.Paid;
        var paid = await entitlements.HasSubscriptionAsync(identityId, ct);
        _entitlement = (identityId, paid);
        return paid;
    }

    public async Task<QuotaDto> GetQuotaAsync(Guid identityId, CancellationToken ct)
    {
        var paid = await PaidAsync(identityId, ct);
        await using var gate = await db.LockUsageAsync(identityId, clock, ct);
        return await db.Database.RunTransactionAsync(async transaction =>
            (await SnapshotAsync(transaction, identityId, paid, clock.GetUtcNow(), ct)).Quota, QuotaTransactions, ct);
    }

    public async Task<ReservationOutcome> ReserveAsync(Guid identityId, string requestId, string fingerprint, CancellationToken ct)
    {
        // Refresh stale entitlements before entering the retryable quota transaction.
        // SDK retries can never repeat Google HTTP calls or a model invocation.
        var paid = await PaidAsync(identityId, ct);
        await using var gate = await db.LockUsageAsync(identityId, clock, ct, write: true);
        return await db.Database.RunTransactionAsync(async transaction =>
        {
            await gate.CheckAsync(transaction, ct);
            using var measurement = timings?.Measure(SimplificationStage.QuotaLock);
            var now = clock.GetUtcNow();
            var snapshot = await SnapshotAsync(transaction, identityId, paid, now, ct);
            var reference = db.Request(identityId, requestId);
            var previous = await db.GetAsync<SimplificationRecord>(transaction, reference, ct);
            if (previous is not null)
            {
                if (previous.State == RequestState.Processing && previous.ReservationExpiresAt <= now)
                {
                    previous.State = RequestState.Expired; previous.FinishedAt = now;
                    db.Put(transaction, reference, previous);
                }
                var kind = previous.Fingerprint != fingerprint ? "key_conflict" : previous.State switch
                {
                    RequestState.Processing => "processing", RequestState.Succeeded => "result_unavailable",
                    RequestState.Expired => "expired", _ => "failed"
                };
                return new ReservationOutcome(kind, snapshot.Quota);
            }
            if (snapshot.Quota.Remaining == 0) return new ReservationOutcome("quota_exceeded", snapshot.Quota);
            var day = QuotaPolicy.Day(now);
            var usage = snapshot.Days[snapshot.Identity.InstallationHash];
            usage.Reservations[reference.Id] = new() { IdentityId = identityId, ExpiresAt = now.Add(ReservationLife) };
            db.Put(transaction, db.Day(snapshot.Identity.InstallationHash, day), usage);
            db.Put(transaction, reference, new SimplificationRecord
            {
                IdentityId = identityId, RequestId = requestId, Fingerprint = fingerprint,
                State = RequestState.Processing, CreatedAt = now, ReservationDay = day,
                ReservationExpiresAt = now.Add(ReservationLife)
            });
            return new ReservationOutcome("reserved", snapshot.Quota with { Remaining = snapshot.Quota.Remaining - 1 });
        }, QuotaTransactions, ct);
    }

    public Task<bool> CompleteAsync(Guid identityId, string requestId, CancellationToken ct) => FinishAsync(identityId, requestId, true, ct);
    public async Task FailAsync(Guid identityId, string requestId, CancellationToken ct) => await FinishAsync(identityId, requestId, false, ct);

    private async Task<bool> FinishAsync(Guid identityId, string requestId, bool success, CancellationToken ct)
    {
        var reference = db.Request(identityId, requestId);
        // ReservationDay is immutable. Read a hint outside the transaction so that
        // every transactional path locks identity -> account -> ledger -> request.
        var hint = await db.GetAsync<SimplificationRecord>(reference, ct);
        if (hint is null) return false;
        await using var gate = await db.LockUsageAsync(identityId, clock, ct, write: true);
        return await db.Database.RunTransactionAsync(async transaction =>
        {
            await gate.CheckAsync(transaction, ct);
            var now = clock.GetUtcNow();
            var identity = await ActiveIdentityAsync(transaction, identityId, ct);
            var dayReference = db.Day(identity.InstallationHash, hint.ReservationDay);
            var usage = await db.GetAsync<DailyUsage>(transaction, dayReference, ct);
            var record = await db.GetAsync<SimplificationRecord>(transaction, reference, ct);
            if (record is null || record.State != RequestState.Processing ||
                record.ReservationDay != hint.ReservationDay || usage is null) return false;
            usage.Expire(now);
            usage.Reservations.Remove(reference.Id);
            var completed = success && record.ReservationExpiresAt > now;
            record.State = completed ? RequestState.Succeeded : success ? RequestState.Expired : RequestState.Failed;
            record.FinishedAt = now;
            if (completed)
            {
                var key = FirestoreStore.Id(identityId);
                usage.Used[key] = usage.Used.GetValueOrDefault(key) + 1;
            }
            db.Put(transaction, dayReference, usage);
            db.Put(transaction, reference, record);
            return completed;
        }, QuotaTransactions, ct);
    }

    public async Task<RequestStatusDto?> GetStatusAsync(Guid identityId, string requestId, CancellationToken ct)
    {
        var paid = await PaidAsync(identityId, ct);
        await using var gate = await db.LockUsageAsync(identityId, clock, ct);
        return await db.Database.RunTransactionAsync(async transaction =>
        {
            var now = clock.GetUtcNow();
            var snapshot = await SnapshotAsync(transaction, identityId, paid, now, ct);
            var reference = db.Request(identityId, requestId);
            var record = await db.GetAsync<SimplificationRecord>(transaction, reference, ct);
            if (record is null) return null;
            if (record.State == RequestState.Processing && record.ReservationExpiresAt <= now)
            {
                record.State = RequestState.Expired; record.FinishedAt = now;

            }
            return new RequestStatusDto(record.RequestId, record.State.ToString().ToLowerInvariant(),
                new DateTimeOffset(record.ReservationDay.ToDateTime(TimeOnly.MinValue), TimeSpan.Zero), record.FinishedAt, snapshot.Quota);
        }, QuotaTransactions, ct);
    }

    private async Task<GuestIdentity> ActiveIdentityAsync(Transaction transaction, Guid id, CancellationToken ct)
    {
        var identity = await db.GetAsync<GuestIdentity>(transaction, db.Identities.Document(FirestoreStore.Id(id)), ct)
            ?? throw new InvalidOperationException("Identity unavailable.");
        if (identity.AccountId is Guid accountId)
        {
            var account = await db.GetAsync<VerifiedAccount>(transaction, db.Accounts.Document(FirestoreStore.Id(accountId)), ct);
            if (account is null || account.Deleting) throw new InvalidOperationException("Account unavailable.");
        }
        return identity;
    }

    private async Task<(GuestIdentity Identity, Dictionary<string, DailyUsage> Days, QuotaDto Quota)> SnapshotAsync(
        Transaction transaction, Guid id, bool paid, DateTimeOffset now, CancellationToken ct)
    {
        var identity = await db.GetAsync<GuestIdentity>(transaction, db.Identities.Document(FirestoreStore.Id(id)), ct)
            ?? throw new InvalidOperationException("Identity unavailable.");
        var hashes = new List<string> { identity.InstallationHash };
        if (identity.AccountId is Guid accountId)
        {
            var account = await db.GetAsync<VerifiedAccount>(transaction, db.Accounts.Document(FirestoreStore.Id(accountId)), ct);
            if (account is null || account.Deleting) throw new InvalidOperationException("Account unavailable.");
            hashes.AddRange(account.InstallationHashes);
        }
        var day = QuotaPolicy.Day(now);
        var days = new Dictionary<string, DailyUsage>();
        foreach (var hash in hashes.Distinct().Order())
        {
            var usage = await db.GetAsync<DailyUsage>(transaction, db.Day(hash, day), ct) ?? new()
            {
                InstallationHash = hash, Day = day.ToString("yyyy-MM-dd"),
                ExpiresAt = new DateTimeOffset(day.ToDateTime(TimeOnly.MinValue), TimeSpan.Zero).AddDays(8)
            };
            usage.Expire(now);
            days[hash] = usage;
        }
        var used = days.Values.Sum(x => x.Used.Values.Sum());
        var reserved = days.Values.Sum(x => x.Reservations.Count);
        var limit = QuotaPolicy.Limit(paid);
        return (identity, days, new(paid ? "subscription" : "free", limit, used,
            Math.Max(0, limit - used - reserved), now, QuotaPolicy.ResetAt(now)));
    }
}
