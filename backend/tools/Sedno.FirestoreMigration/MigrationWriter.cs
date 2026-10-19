using System.Text.Json;
using Google.Cloud.Firestore;
using Sedno.Domain;
using Sedno.Infrastructure;

namespace Sedno.FirestoreMigration;

public sealed class MigrationSnapshot
{
    public List<GuestIdentity> Identities { get; set; } = [];
    public List<GuestSession> Sessions { get; set; } = [];
    public List<VerifiedAccount> Accounts { get; set; } = [];
    public List<SimplificationRecord> Requests { get; set; } = [];
    public List<PlayPurchase> Purchases { get; set; } = [];
    public List<PlayNotification> Notifications { get; set; } = [];
}

// Standalone tool only; the application never reads PostgreSQL or references this project.
public sealed class MigrationWriter(FirestoreStore db)
{
    public async Task<int> ApplyAsync(MigrationSnapshot source, CancellationToken ct)
    {
        var documents = Plan(source);
        var fingerprint = FirestoreStore.Hash(JsonSerializer.Serialize(documents.OrderBy(x => x.Key).ToArray()));
        var marker = db.Database.Collection("system").Document("migration");
        await db.Database.RunTransactionAsync(async transaction =>
        {
            var current = await transaction.GetSnapshotAsync(marker, ct);
            if (current.Exists)
            {
                if (current.GetValue<string>("Fingerprint") != fingerprint)
                    throw new InvalidOperationException("Target contains a different migration.");
                if (!current.GetValue<bool>("InProgress"))
                    throw new InvalidOperationException("Migration already completed; never overwrite an active target.");
                return;
            }
            foreach (var name in CollectionNames)
                if ((await transaction.GetSnapshotAsync(db.Database.Collection(name).Limit(1), ct)).Count != 0)
                    throw new InvalidOperationException("Migration requires an empty target.");
            transaction.Create(marker, new Dictionary<string, object> { ["Fingerprint"] = fingerprint, ["InProgress"] = true });
        }, cancellationToken: ct);
        // The old API and all target writers must remain stopped throughout import.
        // An interrupted import can resume only with the same source fingerprint.
        foreach (var chunk in documents.Chunk(200))
        {
            var batch = db.Database.StartBatch();
            foreach (var pair in chunk) batch.Set(db.Database.Document(pair.Key), pair.Value);
            await batch.CommitAsync(ct);
        }
        foreach (var pair in documents)
        {
            var actual = await db.Database.Document(pair.Key).GetSnapshotAsync(ct);
            if (!actual.Exists || !Same(pair.Value, actual.ToDictionary()))
                throw new InvalidOperationException("Target verification failed.");
        }
        await marker.UpdateAsync("InProgress", false, cancellationToken: ct);
        return documents.Count;
    }

    private static bool Same(object expected, object actual)
    {
        // Firestore integers are Int64, source integers may be boxed Int32.
        // Compare canonical JSON, recursively sorting maps and normalizing timestamps.
        object? Canonical(object? value) => value switch
        {
            Timestamp t => t.ToDateTimeOffset().ToString("O"),
            IDictionary<string, object> map => map.OrderBy(x => x.Key).ToDictionary(x => x.Key, x => Canonical(x.Value)),
            IEnumerable<object> array => array.Select(Canonical).ToArray(),
            _ => value
        };
        return JsonSerializer.Serialize(Canonical(expected)) == JsonSerializer.Serialize(Canonical(actual));
    }

    public Dictionary<string, Dictionary<string, object>> Plan(MigrationSnapshot source)
    {
        var result = new Dictionary<string, Dictionary<string, object>>();
        void Add<T>(DocumentReference reference, T value) => result.Add(reference.Parent.Id + "/" + reference.Id, FirestoreStore.Encode(value));
        var identities = source.Identities.ToDictionary(x => x.Id);
        foreach (var row in source.Identities.OrderBy(x => x.Id)) Add(db.Identities.Document(FirestoreStore.Id(row.Id)), row);
        foreach (var row in source.Sessions.OrderBy(x => x.Id)) Add(db.Sessions.Document(FirestoreStore.Id(row.Id)), row);
        foreach (var row in source.Accounts.OrderBy(x => x.Id))
        {
            row.InstallationHashes = source.Identities.Where(x => x.AccountId == row.Id).Select(x => x.InstallationHash).Distinct().Order().ToList();
            Add(db.Accounts.Document(FirestoreStore.Id(row.Id)), row);
            Add(db.Uids.Document(FirestoreStore.Hash(row.FirebaseUid)), new AccountPointer { AccountId = row.Id });
            Add(db.Bindings.Document(SubscriptionService.Binding(row.Id)), new AccountPointer { AccountId = row.Id });
        }
        var days = new Dictionary<string, DailyUsage>();
        foreach (var row in source.Requests.OrderBy(x => x.IdentityId).ThenBy(x => x.RequestId))
        {
            var request = db.Request(row.IdentityId, row.RequestId);
            Add(request, row);
            if (row.State is not (RequestState.Succeeded or RequestState.Processing)) continue;
            var hash = identities[row.IdentityId].InstallationHash;
            var dayRef = db.Day(hash, row.ReservationDay);
            if (!days.TryGetValue(dayRef.Parent.Id + "/" + dayRef.Id, out var usage))
                days[dayRef.Parent.Id + "/" + dayRef.Id] = usage = new() { InstallationHash = hash, Day = row.ReservationDay.ToString("yyyy-MM-dd"),
                    ExpiresAt = new DateTimeOffset(row.ReservationDay.ToDateTime(TimeOnly.MinValue), TimeSpan.Zero).AddDays(8) };
            if (row.State == RequestState.Succeeded)
            {
                var id = FirestoreStore.Id(row.IdentityId);
                usage.Used[id] = usage.Used.GetValueOrDefault(id) + 1;
            }
            else usage.Reservations[request.Id] = new() { IdentityId = row.IdentityId, ExpiresAt = row.ReservationExpiresAt };
        }
        foreach (var day in days.OrderBy(x => x.Key)) Add(db.Database.Document(day.Key), day.Value);
        foreach (var row in source.Purchases.OrderBy(x => x.TokenHash)) Add(db.Purchases.Document(row.TokenHash), row);
        foreach (var row in source.Notifications.OrderBy(x => x.Id)) Add(db.PlayNotifications.Document(FirestoreStore.Hash(row.Id)), row);
        return result;
    }

    private static readonly string[] CollectionNames = ["guest_identities", "guest_sessions", "verified_accounts", "simplification_requests",
        "play_purchases", "play_notifications", "daily_usage", "account_bindings", "firebase_uids", "operation_leases"];
}
