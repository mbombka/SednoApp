using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Google.Cloud.Firestore;
using Sedno.Domain;

namespace Sedno.Infrastructure;

// One document per entity. No input, result, raw installation ID or bearer is stored.
// The JSON-compatible mapping keeps persistence concerns out of the Domain assembly.
public sealed class FirestoreStore(FirestoreDb database, bool requireMigration = false)
{
    public FirestoreDb Database { get; } = database;
    private readonly UsageGate _usageGate = new();
    internal async Task<UsageLock> LockUsageAsync(Guid identityId, TimeProvider clock, CancellationToken ct, bool write = false)
    {
        // This hint chooses a queue only; authorization and quota membership are
        // re-read in the transaction, including concurrent linking/deletion.
        var identity = await GetAsync<GuestIdentity>(Identities.Document(Id(identityId)), ct)
            ?? throw new InvalidOperationException("Identity unavailable.");
        var local = await _usageGate.AcquireAsync(identity.InstallationHash, ct);
        try
        {
            var lease = write ? await FirestoreLease.AcquireAsync(this, "usage:" + identity.InstallationHash, clock, ct) : null;
            return new(local, lease);
        }
        catch { local.Dispose(); throw; }
    }
    public CollectionReference Identities => Database.Collection("guest_identities");
    public CollectionReference Sessions => Database.Collection("guest_sessions");
    public CollectionReference Accounts => Database.Collection("verified_accounts");
    public CollectionReference Requests => Database.Collection("simplification_requests");
    public CollectionReference Purchases => Database.Collection("play_purchases");
    public CollectionReference PlayNotifications => Database.Collection("play_notifications");
    public CollectionReference DailyUsage => Database.Collection("daily_usage");
    public CollectionReference Bindings => Database.Collection("account_bindings");
    public CollectionReference Uids => Database.Collection("firebase_uids");
    public CollectionReference Leases => Database.Collection("operation_leases");
    public static string Id(Guid id) => id.ToString("N");
    public static string Hash(string value) => System.Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(value)));
    public DocumentReference Request(Guid identity, string request) => Requests.Document(Id(identity) + "_" + request);
    public DocumentReference Day(string installation, DateOnly day) => DailyUsage.Document(installation + "_" + day.ToString("yyyy-MM-dd"));
    public static Timestamp Date(DateTimeOffset value) => Timestamp.FromDateTimeOffset(value);

    public static Dictionary<string, object> Encode<T>(T value) =>
        (Dictionary<string, object>)Convert(JsonSerializer.SerializeToElement(value))!;
    private static object? Convert(JsonElement value, string? field = null) => value.ValueKind switch
    {
        JsonValueKind.Object => value.EnumerateObject().ToDictionary(x => x.Name, x => Convert(x.Value, x.Name)!),
        JsonValueKind.Array => value.EnumerateArray().Select(x => Convert(x)).ToArray(),
        JsonValueKind.String => (field is "CreatedAt" or "ExpiresAt" or "FinishedAt" or "ReservationExpiresAt" or "VerifiedAt" or "RefreshNotBefore" or "ProcessedAt") && value.TryGetDateTimeOffset(out var date) ? Timestamp.FromDateTimeOffset(date) : value.GetString(),
        JsonValueKind.Number => value.GetInt64(),
        JsonValueKind.True => true,
        JsonValueKind.False => false,
        _ => null
    };
    public static T? Decode<T>(DocumentSnapshot snapshot) where T : class => snapshot.Exists
        ? JsonSerializer.Deserialize<T>(JsonSerializer.Serialize(Normalize(snapshot.ToDictionary()))) : null;
    private static object? Normalize(object? value) => value switch
    {
        Timestamp timestamp => timestamp.ToDateTimeOffset(),
        IDictionary<string, object> map => map.ToDictionary(x => x.Key, x => Normalize(x.Value)),
        IEnumerable<object> list => list.Select(Normalize).ToArray(),
        _ => value
    };
    public async Task<T?> GetAsync<T>(DocumentReference reference, CancellationToken ct = default) where T : class =>
        Decode<T>(await reference.GetSnapshotAsync(ct));
    public async Task<T?> GetAsync<T>(Transaction transaction, DocumentReference reference, CancellationToken ct) where T : class =>
        Decode<T>(await transaction.GetSnapshotAsync(reference, ct));
    public async Task<List<T>> ListAsync<T>(Query query, CancellationToken ct = default) where T : class =>
        (await query.GetSnapshotAsync(ct)).Documents.Select(x => Decode<T>(x)!).ToList();
    public Task PutAsync<T>(DocumentReference reference, T value, CancellationToken ct = default) => reference.SetAsync(Encode(value), cancellationToken: ct);
    public void Put<T>(Transaction transaction, DocumentReference reference, T value) => transaction.Set(reference, Encode(value));

    // Read a fixed document: verifies IAM/connectivity without scanning a collection.
    public async Task<bool> ReadyAsync(CancellationToken ct)
    {
        try
        {
            var marker = await Database.Collection("system").Document("migration").GetSnapshotAsync(ct);
            return marker.Exists ? !marker.GetValue<bool>("InProgress") : !requireMigration;
        }
        catch (Grpc.Core.RpcException) { return false; }
    }
}

public sealed class DailyUsage
{
    public string InstallationHash { get; set; } = "";
    public string Day { get; set; } = "";
    public DateTimeOffset ExpiresAt { get; set; }
    public Dictionary<string, int> Used { get; set; } = [];
    public Dictionary<string, UsageReservation> Reservations { get; set; } = [];
    public void Expire(DateTimeOffset now)
    {
        foreach (var key in Reservations.Where(x => x.Value.ExpiresAt <= now).Select(x => x.Key).ToArray())
            Reservations.Remove(key);
    }
}
public sealed class UsageReservation
{
    public Guid IdentityId { get; set; }
    public DateTimeOffset ExpiresAt { get; set; }
}
public sealed class AccountPointer
{
    public Guid AccountId { get; set; }
}

internal sealed class UsageLock(IDisposable local, FirestoreLease? lease) : IAsyncDisposable
{
    public Task CheckAsync(Transaction transaction, CancellationToken ct) => lease?.CheckAsync(transaction, ct) ?? Task.CompletedTask;
    public async ValueTask DisposeAsync()
    {
        try { if (lease is not null) await lease.DisposeAsync(); }
        finally { local.Dispose(); }
    }
}
