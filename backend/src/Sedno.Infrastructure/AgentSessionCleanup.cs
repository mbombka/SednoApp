using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;

namespace Sedno.Infrastructure;

public interface IAgentSessionCleanupQueue
{
    Task TrackAsync(string sessionId, CancellationToken ct);
    Task ReadyAsync(string sessionId, CancellationToken ct, bool cancel = false);
    void RequestRecovery() { }
}

// Only session IDs and retry state live in RAM. No database writes or user text.
public sealed class AgentSessionCleanupWorker(IHttpClientFactory clients, OpenAiAgentOptions options,
    TimeProvider clock, ILogger<AgentSessionCleanupWorker> logger) : BackgroundService, IAgentSessionCleanupQueue
{
    public const string Purpose = "sedno-simplification-v1";
    private sealed record Pending(DateTimeOffset Due, int Attempts, bool Cancel);
    private readonly object _sync = new();
    private readonly Dictionary<string, Pending> _pending = new();
    private readonly SemaphoreSlim _wake = new(0, 1);
    private DateTimeOffset? _recoverAt = clock.GetUtcNow();
    private int _recoveryFailures;
    private int _recoveryVersion;
    public bool AnySessionOpened { get { lock (_sync) return _pending.Count > 0 || _recoverAt is not null; } }
    internal static bool SafeId(string? id) => !string.IsNullOrEmpty(id) && id.Length <= 128 &&
        id.All(c => char.IsAsciiLetterOrDigit(c) || c is '_' or '-');

    public Task TrackAsync(string sessionId, CancellationToken ct)
    {
        if (!SafeId(sessionId)) throw new ArgumentException("Invalid session ID.");
        lock (_sync)
        {
            _pending.TryAdd(sessionId, new(clock.GetUtcNow().AddSeconds(30), 0, true));
            Wake();
        }
        return Task.CompletedTask;
    }
    public Task ReadyAsync(string sessionId, CancellationToken ct, bool cancel = false)
    {
        lock (_sync)
        {
            _pending[sessionId] = new(clock.GetUtcNow(), 0, cancel);
            Wake();
        }
        return Task.CompletedTask;
    }
    public void RequestRecovery()
    {
        lock (_sync)
        {
            _recoveryVersion++;
            var due = clock.GetUtcNow().AddMinutes(1);
            if (_recoverAt is null || _recoverAt > due) _recoverAt = due;
            Wake();
        }
    }
    private void Wake() { if (_wake.CurrentCount == 0) _wake.Release(); }

    protected override async Task ExecuteAsync(CancellationToken ct)
    {
        while (!ct.IsCancellationRequested)
        {
            await ProcessPendingAsync(ct);
            TimeSpan? delay;
            lock (_sync)
            {
                var due = _pending.Values.Select(x => (DateTimeOffset?)x.Due).Append(_recoverAt).Min();
                delay = due is null ? null : due.Value - clock.GetUtcNow();
            }
            if (delay is null) await _wake.WaitAsync(ct);
            else
            {
                using var wait = CancellationTokenSource.CreateLinkedTokenSource(ct);
                var signal = _wake.WaitAsync(wait.Token);
                var timer = Task.Delay(delay > TimeSpan.Zero ? delay.Value : TimeSpan.Zero, clock, wait.Token);
                await Task.WhenAny(signal, timer);
                await wait.CancelAsync();
                try { await Task.WhenAll(signal, timer); } catch (OperationCanceledException) { ct.ThrowIfCancellationRequested(); }
            }
        }
    }

    public async Task ProcessPendingAsync(CancellationToken ct)
    {
        bool recover;
        int recoveryVersion;
        lock (_sync) { recover = _recoverAt <= clock.GetUtcNow(); recoveryVersion = _recoveryVersion; }
        if (recover)
        {
            try
            {
                await RecoverAsync(ct);
                lock (_sync) { if (_recoveryVersion == recoveryVersion) _recoverAt = null; _recoveryFailures = 0; }
            }
            catch (Exception) when (!ct.IsCancellationRequested)
            {
                lock (_sync) _recoverAt = clock.GetUtcNow() + Backoff(++_recoveryFailures);
                logger.LogWarning("Nie udało się sprawdzić pozostałych sesji OpenAI. Próba zostanie ponowiona.");
            }
        }
        KeyValuePair<string, Pending>[] jobs;
        lock (_sync) jobs = _pending.Where(x => x.Value.Due <= clock.GetUtcNow()).Take(100).ToArray();
        await Parallel.ForEachAsync(jobs, new ParallelOptions { MaxDegreeOfParallelism = 4, CancellationToken = ct }, async (job, token) =>
        {
            var deleted = false;
            try { deleted = await DeleteAsync(job.Key, job.Value.Cancel, token); }
            catch (Exception) when (!token.IsCancellationRequested) { }
            lock (_sync)
            {
                // A concurrent scheduling update must not be overwritten by an older attempt.
                if (!_pending.TryGetValue(job.Key, out var current) || current != job.Value) return;
                if (deleted) _pending.Remove(job.Key);
                else _pending[job.Key] = new(clock.GetUtcNow() + Backoff(current.Attempts + 1),
                    Math.Min(20, current.Attempts + 1), true);
            }
            if (!deleted) logger.LogWarning("Usuwanie sesji OpenAI nie powiodło się. Próba zostanie ponowiona.");
        });
    }
    private static TimeSpan Backoff(int failures) => TimeSpan.FromSeconds(Math.Min(300, 10 * Math.Pow(2, Math.Min(10, failures - 1))));

    private async Task<bool> DeleteAsync(string id, bool cancel, CancellationToken ct)
    {
        using var budget = new CancellationTokenSource(TimeSpan.FromSeconds(3), clock);
        using var linked = CancellationTokenSource.CreateLinkedTokenSource(ct, budget.Token);
        using var client = clients.CreateClient("openai-agent");
        if (cancel)
        {
            using var request = Request(HttpMethod.Post, id + "/events");
            request.Content = JsonContent.Create(new { events = new[] { new { type = "agent.session.input.cancel" } } });
            using var response = await client.SendAsync(request, HttpCompletionOption.ResponseHeadersRead, linked.Token);
            if (response.StatusCode == HttpStatusCode.NotFound) return true;
            // Still try deletion: an idle session can reject cancellation.
        }
        using var deletion = Request(HttpMethod.Delete, id);
        using var result = await client.SendAsync(deletion, HttpCompletionOption.ResponseHeadersRead, linked.Token);
        return result.IsSuccessStatusCode || result.StatusCode == HttpStatusCode.NotFound;
    }

    private async Task RecoverAsync(CancellationToken ct)
    {
        string? after = null;
        var seen = new HashSet<string>();
        do
        {
            using var budget = new CancellationTokenSource(TimeSpan.FromSeconds(3), clock);
            using var linked = CancellationTokenSource.CreateLinkedTokenSource(ct, budget.Token);
            using var client = clients.CreateClient("openai-agent");
            var url = "?agent_id=" + Uri.EscapeDataString(options.AgentId) + "&order=asc&limit=100" +
                (after is null ? "" : "&after=" + Uri.EscapeDataString(after));
            using var request = Request(HttpMethod.Get, url);
            using var response = await client.SendAsync(request, HttpCompletionOption.ResponseHeadersRead, linked.Token);
            if (!response.IsSuccessStatusCode) throw new ModelProviderException();
            await response.Content.LoadIntoBufferAsync(4 * 1024 * 1024, linked.Token);
            using var document = JsonDocument.Parse(await response.Content.ReadAsByteArrayAsync(linked.Token));
            var root = document.RootElement;
            foreach (var session in root.GetProperty("data").EnumerateArray())
            {
                if (session.GetProperty("agent").GetProperty("id").GetString() != options.AgentId ||
                    !session.TryGetProperty("metadata", out var metadata) || metadata.ValueKind != JsonValueKind.Object ||
                    !metadata.TryGetProperty("sedno_purpose", out var purpose) || purpose.GetString() != Purpose) continue;
                var id = session.GetProperty("id").GetString();
                if (!SafeId(id)) throw new ModelProviderException();
                var due = DateTimeOffset.FromUnixTimeSeconds(session.GetProperty("created_at").GetInt64()).AddMinutes(1);
                lock (_sync) _pending.TryAdd(id!, new(due > clock.GetUtcNow() ? due : clock.GetUtcNow(), 0, true));
            }
            if (!root.GetProperty("has_more").GetBoolean()) return;
            after = root.GetProperty("last_id").GetString();
            if (!SafeId(after) || !seen.Add(after!)) throw new ModelProviderException();
        } while (!ct.IsCancellationRequested);
        ct.ThrowIfCancellationRequested();
    }
    private HttpRequestMessage Request(HttpMethod method, string path)
    {
        var request = new HttpRequestMessage(method, "https://api.openai.com/v1/agents/sessions" +
            (path.StartsWith('?') ? path : "/" + path));
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", options.ApiKey);
        request.Headers.Add("OpenAI-Beta", "agents=v1");
        return request;
    }
}
