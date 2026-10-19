using Google.Cloud.Firestore;
using Sedno.Application;
using Sedno.Domain;

namespace Sedno.Infrastructure;

// Invoked hourly by a Cloud Run job, not by a permanently running API instance.
public sealed class MetadataCleanup(FirestoreStore db, TimeProvider clock, AccountDeletionService deletion)
{
    public async Task RunAsync(CancellationToken ct)
    {
        if (!await db.ReadyAsync(ct)) throw new InvalidOperationException("Firestore migration must complete before cleanup.");
        var now = clock.GetUtcNow();
        foreach (var account in await db.ListAsync<VerifiedAccount>(db.Accounts.WhereEqualTo("Deleting", true), ct))
            await deletion.DeleteAsync(new SessionIdentity(account.PrimaryIdentityId, account.Id, Guid.Empty), ct);
        await DeleteAsync(db.Requests.WhereLessThan("CreatedAt", FirestoreStore.Date(now.AddDays(-8))), ct);
        await DeleteAsync(db.Sessions.WhereLessThanOrEqualTo("ExpiresAt", FirestoreStore.Date(now)), ct);
        await DeleteAsync(db.DailyUsage.WhereLessThanOrEqualTo("ExpiresAt", FirestoreStore.Date(now)), ct);
        var candidates = await db.Identities.WhereLessThan("CreatedAt", FirestoreStore.Date(now.AddDays(-90))).GetSnapshotAsync(ct);
        foreach (var candidate in candidates.Documents)
            await db.Database.RunTransactionAsync(async transaction =>
            {
                var identity = await db.GetAsync<GuestIdentity>(transaction, candidate.Reference, ct);
                if (identity is null || identity.AccountId is not null) return;
                var sessions = await transaction.GetSnapshotAsync(db.Sessions.WhereEqualTo("IdentityId", identity.Id.ToString()).Limit(1), ct);
                var requests = await transaction.GetSnapshotAsync(db.Requests.WhereEqualTo("IdentityId", identity.Id.ToString()).Limit(1), ct);
                if (sessions.Count == 0 && requests.Count == 0) transaction.Delete(candidate.Reference);
            }, cancellationToken: ct);
        // Crashed callers leave bounded leases; do not retain coordination metadata forever.
        await DeleteAsync(db.Leases.WhereLessThan("ExpiresAt", FirestoreStore.Date(now)), ct);
    }

    private async Task DeleteAsync(Query query, CancellationToken ct)
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
