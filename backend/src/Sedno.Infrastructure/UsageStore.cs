using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Storage;
using Npgsql;
using Sedno.Application;
using Sedno.Domain;

namespace Sedno.Infrastructure;

public sealed class UsageStore(AppDbContext db, IEntitlementResolver entitlements, TimeProvider clock) : IUsageStore
{
    private static readonly TimeSpan ReservationLife = TimeSpan.FromMinutes(5);

    public async Task<QuotaDto> GetQuotaAsync(Guid identityId, CancellationToken ct)
    {
        var now = clock.GetUtcNow();
        await ExpireAsync(identityId, now, ct);
        return await SnapshotAsync(identityId, now, ct);
    }

    public async Task<ReservationOutcome> ReserveAsync(Guid identityId, string requestId, string fingerprint, CancellationToken ct)
    {
        await using var transaction = await db.Database.BeginTransactionAsync(ct);
        await LockAsync(identityId, ct);
        var now = clock.GetUtcNow();
        await ExpireAsync(identityId, now, ct);
        var previous = await db.Requests.AsNoTracking().SingleOrDefaultAsync(x => x.IdentityId == identityId && x.RequestId == requestId, ct);
        if (previous is not null)
        {
            var kind = previous.Fingerprint != fingerprint ? "key_conflict" : previous.State switch
            {
                RequestState.Processing => "processing",
                RequestState.Succeeded => "result_unavailable",
                RequestState.Expired => "expired",
                _ => "failed"
            };
            var snapshot = await SnapshotAsync(identityId, now, ct);
            await transaction.CommitAsync(ct);
            return new(kind, snapshot);
        }
        var quota = await SnapshotAsync(identityId, now, ct);
        if (quota.Remaining == 0)
        {
            await transaction.CommitAsync(ct);
            return new("quota_exceeded", quota);
        }
        db.Requests.Add(new SimplificationRecord
        {
            IdentityId = identityId, RequestId = requestId, Fingerprint = fingerprint,
            State = RequestState.Processing, CreatedAt = now,
            ReservationDay = QuotaPolicy.Day(now), ReservationExpiresAt = now.Add(ReservationLife)
        });
        await db.SaveChangesAsync(ct);
        await transaction.CommitAsync(ct);
        return new("reserved", quota with { Remaining = quota.Remaining - 1 });
    }

    public async Task<bool> CompleteAsync(Guid identityId, string requestId, CancellationToken ct)
    {
        await using var transaction = await db.Database.BeginTransactionAsync(ct);
        await LockAsync(identityId, ct);
        var now = clock.GetUtcNow();
        var changed = await db.Requests.Where(x => x.IdentityId == identityId && x.RequestId == requestId &&
            x.State == RequestState.Processing && x.ReservationExpiresAt > now)
            .ExecuteUpdateAsync(s => s.SetProperty(x => x.State, RequestState.Succeeded)
                .SetProperty(x => x.FinishedAt, (DateTimeOffset?)now), ct);
        await transaction.CommitAsync(ct);
        return changed == 1;
    }

    public async Task FailAsync(Guid identityId, string requestId, CancellationToken ct)
    {
        await using var transaction = await db.Database.BeginTransactionAsync(ct);
        await LockAsync(identityId, ct);
        var now = clock.GetUtcNow();
        await db.Requests.Where(x => x.IdentityId == identityId && x.RequestId == requestId && x.State == RequestState.Processing)
            .ExecuteUpdateAsync(s => s.SetProperty(x => x.State, RequestState.Failed)
                .SetProperty(x => x.FinishedAt, (DateTimeOffset?)now), ct);
        await transaction.CommitAsync(ct);
    }

    public async Task<RequestStatusDto?> GetStatusAsync(Guid identityId, string requestId, CancellationToken ct)
    {
        var now = clock.GetUtcNow();
        await ExpireAsync(identityId, now, ct);
        var record = await db.Requests.AsNoTracking().SingleOrDefaultAsync(x => x.IdentityId == identityId && x.RequestId == requestId, ct);
        if (record is null) return null;
        return new(record.RequestId, record.State.ToString().ToLowerInvariant(),
            new DateTimeOffset(record.ReservationDay.ToDateTime(TimeOnly.MinValue), TimeSpan.Zero), record.FinishedAt,
            await SnapshotAsync(identityId, now, ct));
    }

    private async Task ExpireAsync(Guid identityId, DateTimeOffset now, CancellationToken ct) =>
        await db.Requests.Where(x => x.IdentityId == identityId && x.State == RequestState.Processing && x.ReservationExpiresAt <= now)
            .ExecuteUpdateAsync(s => s.SetProperty(x => x.State, RequestState.Expired)
                .SetProperty(x => x.FinishedAt, (DateTimeOffset?)now), ct);

    private async Task<QuotaDto> SnapshotAsync(Guid identityId, DateTimeOffset now, CancellationToken ct)
    {
        var day = QuotaPolicy.Day(now);
        var identity = await db.Identities.AsNoTracking().Where(x => x.Id == identityId)
            .Select(x => new { x.InstallationHash, x.AccountId }).SingleAsync(ct);
        var hashes = identity.AccountId is null ? new[] { identity.InstallationHash } :
            await db.Identities.AsNoTracking().Where(x => x.AccountId == identity.AccountId)
                .Select(x => x.InstallationHash).Distinct().ToArrayAsync(ct);
        var counts = await db.Requests.AsNoTracking()
            .Join(db.Identities.AsNoTracking(), request => request.IdentityId, identity => identity.Id,
                (request, identity) => new { request, identity })
            .Where(x => (hashes.Contains(x.identity.InstallationHash) ||
                (identity.AccountId != null && x.identity.AccountId == identity.AccountId)) && x.request.ReservationDay == day &&
                (x.request.State != RequestState.Processing || x.request.ReservationExpiresAt > now))
            .GroupBy(x => x.request.State).Select(g => new { State = g.Key, Count = g.Count() }).ToListAsync(ct);
        var used = counts.Where(x => x.State == RequestState.Succeeded).Sum(x => x.Count);
        var reserved = counts.Where(x => x.State == RequestState.Processing).Sum(x => x.Count);
        var paid = await entitlements.HasSubscriptionAsync(identityId, ct);
        var limit = QuotaPolicy.Limit(paid);
        return new(paid ? "subscription" : "free", limit, used, Math.Max(0, limit - used - reserved), now, QuotaPolicy.ResetAt(now));
    }

    private async Task LockAsync(Guid identityId, CancellationToken ct)
    {
        var connection = db.Database.GetDbConnection();
        await using var command = connection.CreateCommand();
        command.Transaction = db.Database.CurrentTransaction!.GetDbTransaction();
        // Linking can merge several installation buckets. Serialize quota writes with linking.
        command.CommandText = "SELECT pg_advisory_xact_lock(1748392201)";
        await command.ExecuteNonQueryAsync(ct);
    }
}
