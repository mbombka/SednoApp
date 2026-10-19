using Google.Cloud.Firestore;

namespace Sedno.Infrastructure;

// Serializes external Firebase/Play calls across replicas, outside retryable
// Firestore callbacks. Expiry is checked again in the data commit (fencing).
internal sealed class FirestoreLease(FirestoreStore store, DocumentReference reference, string owner, TimeProvider clock) : IAsyncDisposable
{
    private static readonly TimeSpan Lifetime = TimeSpan.FromMinutes(2);
    public static async Task<FirestoreLease> AcquireAsync(FirestoreStore store, string scope, TimeProvider clock, CancellationToken ct)
    {
        var reference = store.Leases.Document(FirestoreStore.Hash(scope));
        var owner = Guid.NewGuid().ToString("N");
        while (true)
        {
            ct.ThrowIfCancellationRequested();
            // Atomic create is the uncontended path. Competing callers do not
            // open read transactions that could block the owner's delete/commit.
            try
            {
                await reference.CreateAsync(FirestoreStore.Encode(new LeaseDocument
                    { Owner = owner, ExpiresAt = clock.GetUtcNow().Add(Lifetime) }), ct);
                return new(store, reference, owner, clock);
            }
            catch (Grpc.Core.RpcException error) when (error.StatusCode == Grpc.Core.StatusCode.AlreadyExists) { }
            var snapshot = await store.GetAsync<LeaseDocument>(reference, ct);
            if (snapshot is not null && snapshot.ExpiresAt <= clock.GetUtcNow())
            {
                var acquired = await store.Database.RunTransactionAsync(async transaction =>
                {
                    var current = await store.GetAsync<LeaseDocument>(transaction, reference, ct);
                    var now = clock.GetUtcNow();
                    if (current is not null && current.ExpiresAt > now) return false;
                    store.Put(transaction, reference, new LeaseDocument { Owner = owner, ExpiresAt = now.Add(Lifetime) });
                    return true;
                }, cancellationToken: ct);
                if (acquired) return new(store, reference, owner, clock);
            }
            await Task.Delay(TimeSpan.FromMilliseconds(50), ct);
        }
    }
    public async Task CheckAsync(Transaction transaction, CancellationToken ct)
    {
        var current = await store.GetAsync<LeaseDocument>(transaction, reference, ct);
        if (current?.Owner != owner || current.ExpiresAt <= clock.GetUtcNow())
            throw new InvalidOperationException("Operation lease expired; retry the operation.");
    }
    public async ValueTask DisposeAsync()
    {
        // Do not mask an earlier failure. Abandoned leases have a bounded lifetime.
        try
        {
            using var timeout = new CancellationTokenSource(TimeSpan.FromSeconds(5));
            await store.Database.RunTransactionAsync(async transaction =>
            {
                var current = await store.GetAsync<LeaseDocument>(transaction, reference, timeout.Token);
                if (current?.Owner == owner) transaction.Delete(reference);
            }, cancellationToken: timeout.Token);
        }
        catch (Exception ex) when (ex is Grpc.Core.RpcException or OperationCanceledException) { }
    }
    private sealed class LeaseDocument
    {
        public string Owner { get; set; } = "";
        public DateTimeOffset ExpiresAt { get; set; }
    }
}
