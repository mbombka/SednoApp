using System.Net;
using System.Text.Json;
using Microsoft.Extensions.Logging.Abstractions;
using Sedno.Infrastructure;
using Xunit;

namespace Sedno.UnitTests;

public sealed class AgentSessionCleanupTests
{
    private sealed class Clock : TimeProvider
    {
        public DateTimeOffset Now = new(2026, 10, 16, 12, 0, 0, TimeSpan.Zero);
        public override DateTimeOffset GetUtcNow() => Now;
    }
    private sealed class Upstream : HttpMessageHandler, IHttpClientFactory
    {
        public List<string> Calls = [];
        public Func<HttpRequestMessage, CancellationToken, Task<HttpResponseMessage>> Respond =
            (r, _) => Task.FromResult(r.Method == HttpMethod.Get ? Json(new { data = Array.Empty<object>(), has_more = false }) : new HttpResponseMessage(HttpStatusCode.NoContent));
        public HttpClient CreateClient(string name) => new(this, false);
        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage r, CancellationToken ct)
        {
            lock (Calls) Calls.Add(r.Method + " " + r.RequestUri!.PathAndQuery);
            return Respond(r, ct);
        }
    }
    private static HttpResponseMessage Json(object body) => new(HttpStatusCode.OK) { Content = new StringContent(JsonSerializer.Serialize(body)) };
    private static AgentSessionCleanupWorker Worker(Upstream api, Clock clock) => new(api,
        new OpenAiAgentOptions { ApiKey = "test", AgentId = "agent_test" }, clock, NullLogger<AgentSessionCleanupWorker>.Instance);

    [Fact]
    public async Task EmptyWorkerSleepsAndReadySessionIsDeletedWithoutCancellation()
    {
        var api = new Upstream(); var clock = new Clock(); using var worker = Worker(api, clock);
        await worker.ProcessPendingAsync(default); // Startup recovery.
        Assert.False(worker.AnySessionOpened);
        await worker.TrackAsync("sess_test", default);
        await worker.ProcessPendingAsync(default);
        Assert.Single(api.Calls); // Tracking alone must not delete a running request.
        await worker.ReadyAsync("sess_test", default);
        await worker.ProcessPendingAsync(default);
        Assert.Equal(2, api.Calls.Count);
        Assert.StartsWith("DELETE", api.Calls.Last());
        Assert.False(worker.AnySessionOpened);
        await worker.ProcessPendingAsync(default);
        Assert.Equal(2, api.Calls.Count); // No list or delete calls while idle.
    }

    [Fact]
    public async Task FailedCleanupRetriesAfterTenSecondsAndCancelsBeforeDelete()
    {
        var api = new Upstream(); var clock = new Clock(); using var worker = Worker(api, clock);
        await worker.ProcessPendingAsync(default);
        api.Respond = (_, _) => Task.FromResult(new HttpResponseMessage(HttpStatusCode.ServiceUnavailable));
        await worker.TrackAsync("sess_test", default);
        await worker.ReadyAsync("sess_test", default, cancel: true);
        await worker.ProcessPendingAsync(default);
        Assert.True(worker.AnySessionOpened);
        Assert.StartsWith("POST", api.Calls[1]); Assert.StartsWith("DELETE", api.Calls[2]);
        clock.Now = clock.Now.AddSeconds(9);
        await worker.ProcessPendingAsync(default); Assert.Equal(3, api.Calls.Count);
        clock.Now = clock.Now.AddSeconds(1);
        api.Respond = (_, _) => Task.FromResult(new HttpResponseMessage(HttpStatusCode.NotFound));
        await worker.ProcessPendingAsync(default);
        Assert.False(worker.AnySessionOpened);
    }

    [Fact]
    public async Task StartupRecoveryPaginatesAndOnlyDeletesTaggedSessionsOfConfiguredAgent()
    {
        var api = new Upstream(); var clock = new Clock();
        object Session(string id, string agent, string purpose, DateTimeOffset created) => new
        { id, agent = new { id = agent }, metadata = new { sedno_purpose = purpose }, created_at = created.ToUnixTimeSeconds() };
        api.Respond = (r, _) => Task.FromResult(r.Method != HttpMethod.Get ? new HttpResponseMessage(HttpStatusCode.NoContent) :
            r.RequestUri!.Query.Contains("after=") ? Json(new
            { data = new[] { Session("sess_young", "agent_test", AgentSessionCleanupWorker.Purpose, clock.Now) }, has_more = false }) :
            Json(new { data = new[] {
                Session("sess_old", "agent_test", AgentSessionCleanupWorker.Purpose, clock.Now.AddMinutes(-2)),
                Session("sess_other", "agent_other", AgentSessionCleanupWorker.Purpose, clock.Now.AddMinutes(-2)),
                Session("sess_unmarked", "agent_test", "", clock.Now.AddMinutes(-2)) }, has_more = true, last_id = "sess_unmarked" }));
        using var worker = Worker(api, clock);
        await worker.ProcessPendingAsync(default);
        Assert.Equal(2, api.Calls.Count(x => x.StartsWith("GET")));
        Assert.Contains(api.Calls, x => x == "DELETE /v1/agents/sessions/sess_old");
        Assert.DoesNotContain(api.Calls, x => x.StartsWith("DELETE") && (x.EndsWith("sess_other") || x.EndsWith("sess_unmarked") || x.EndsWith("sess_young")));
        clock.Now = clock.Now.AddMinutes(1);
        await worker.ProcessPendingAsync(default);
        Assert.Contains(api.Calls, x => x == "DELETE /v1/agents/sessions/sess_young");
        Assert.False(worker.AnySessionOpened);
    }

    [Fact]
    public async Task BackgroundDeletionCanBlockWhileCallerAlreadyHasScheduledCleanup()
    {
        var api = new Upstream(); var clock = new Clock(); using var worker = Worker(api, clock);
        await worker.ProcessPendingAsync(default);
        var gate = new TaskCompletionSource<HttpResponseMessage>(TaskCreationOptions.RunContinuationsAsynchronously);
        api.Respond = (_, _) => gate.Task;
        await worker.TrackAsync("sess_test", default);
        await worker.ReadyAsync("sess_test", default);
        var deleting = worker.ProcessPendingAsync(default);
        Assert.False(deleting.IsCompleted);
        gate.SetResult(new HttpResponseMessage(HttpStatusCode.NoContent));
        await deleting;
        Assert.False(worker.AnySessionOpened);
    }
}
