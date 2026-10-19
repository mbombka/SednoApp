namespace Sedno.Infrastructure;

// An optimization for concurrent requests in the same API process. Cross-replica
// correctness always comes from Firestore transactions, never from this gate.
// Entries are removed after the last waiter, so installation IDs cannot accumulate.
internal sealed class UsageGate
{
    private readonly object _sync = new();
    private readonly Dictionary<string, Entry> _entries = [];

    public async Task<IDisposable> AcquireAsync(string key, CancellationToken ct)
    {
        Entry entry;
        lock (_sync)
        {
            if (!_entries.TryGetValue(key, out entry!)) _entries[key] = entry = new();
            entry.Users++;
        }
        try { await entry.Semaphore.WaitAsync(ct); }
        catch { Drop(key, entry); throw; }
        return new Releaser(this, key, entry);
    }

    private void Drop(string key, Entry entry)
    {
        lock (_sync)
            if (--entry.Users == 0)
            {
                _entries.Remove(key);
                entry.Semaphore.Dispose();
            }
    }

    private sealed class Entry
    {
        public readonly SemaphoreSlim Semaphore = new(1, 1);
        public int Users;
    }
    private sealed class Releaser(UsageGate gate, string key, Entry entry) : IDisposable
    {
        private UsageGate? _gate = gate;
        public void Dispose()
        {
            var owner = Interlocked.Exchange(ref _gate, null);
            if (owner is null) return;
            entry.Semaphore.Release();
            owner.Drop(key, entry);
        }
    }
}
