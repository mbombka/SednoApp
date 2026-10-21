using Microsoft.Extensions.Caching.Memory;

namespace Sedno.Infrastructure;

public sealed record IdentityAccountStatus(bool Enabled, long ValidSince)
{
    public bool Allows(long authTime) => Enabled && authTime > 0 && authTime >= ValidSince;
}

/// <summary>Per-instance, bounded, demand-driven account status cache. Never caches transport failures.</summary>
public sealed class FirebaseAccountAccess(IIdentityAccountDeletion accounts, TimeProvider clock) : IDisposable
{
    private static readonly TimeSpan Lifetime = TimeSpan.FromMinutes(5);
    private readonly MemoryCache _cache = new(new MemoryCacheOptions { SizeLimit = 10000 });
    private readonly object _gate = new();
    private readonly Dictionary<string, TaskCompletionSource<IdentityAccountStatus>> _pending = [];
    private sealed record Entry(IdentityAccountStatus Status, DateTimeOffset ExpiresAt);

    public Task<IdentityAccountStatus> GetFreshAsync(string uid, CancellationToken ct) => accounts.GetStatusAsync(uid, ct);

    public async Task<IdentityAccountStatus> GetAsync(string uid, CancellationToken ct)
    {
        TaskCompletionSource<IdentityAccountStatus> pending;
        bool refresh;
        lock (_gate)
        {
            if (_cache.TryGetValue(uid, out Entry? entry) && entry!.ExpiresAt > clock.GetUtcNow()) return entry.Status;
            refresh = !_pending.TryGetValue(uid, out pending!);
            if (refresh)
            {
                pending = new(TaskCreationOptions.RunContinuationsAsynchronously);
                _pending.Add(uid, pending);
            }
        }
        if (refresh) _ = RefreshAsync(uid, pending);
        // One cancelled caller must not cancel the other callers' account check.
        return await pending.Task.WaitAsync(ct);
    }

    private async Task RefreshAsync(string uid, TaskCompletionSource<IdentityAccountStatus> pending)
    {
        var checkedAt = clock.GetUtcNow();
        try
        {
            var status = await accounts.GetStatusAsync(uid, CancellationToken.None);
            lock (_gate)
            {
                _cache.Set(uid, new Entry(status, checkedAt + Lifetime),
                    new MemoryCacheEntryOptions { Size = 1, AbsoluteExpirationRelativeToNow = Lifetime });
                _pending.Remove(uid);
            }
            pending.TrySetResult(status);
        }
        catch (Exception error)
        {
            lock (_gate) { _cache.Remove(uid); _pending.Remove(uid); }
            pending.TrySetException(error);
        }
    }

    public void Dispose() => _cache.Dispose();
}
