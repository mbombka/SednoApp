using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace Sedno.Infrastructure;

// The host owns detached stream readers, including shutdown cancellation and disposal.
public sealed class AgentStreamRunner(ILogger<AgentStreamRunner> logger) : IHostedService, IDisposable
{
    private int _disposed;
    private readonly object _sync = new();
    private readonly HashSet<Task> _tasks = [];
    private readonly CancellationTokenSource _stopping = new();
    public void Run(Func<CancellationToken, Task> work)
    {
        lock (_sync)
        {
            var stopping = _stopping.Token;
            stopping.ThrowIfCancellationRequested();
            var task = Task.Run(async () =>
            {
                try { await work(stopping); }
                catch (OperationCanceledException) when (_stopping.IsCancellationRequested) { }
                catch (Exception) { logger.LogWarning("Odbieranie końca strumienia agenta nie powiodło się."); }
            });
            _tasks.Add(task);
            _ = RemoveWhenFinishedAsync(task);
        }
    }
    private async Task RemoveWhenFinishedAsync(Task task)
    {
        await task;
        lock (_sync) _tasks.Remove(task);
    }
    public Task StartAsync(CancellationToken ct) => Task.CompletedTask;
    public async Task StopAsync(CancellationToken ct)
    {
        await _stopping.CancelAsync();
        Task[] pending;
        lock (_sync) pending = _tasks.ToArray();
        await Task.WhenAll(pending).WaitAsync(ct);
    }
    public void Dispose()
    {
        if (Interlocked.Exchange(ref _disposed, 1) != 0) return;
        _stopping.Cancel();
        _stopping.Dispose();
    }
}
