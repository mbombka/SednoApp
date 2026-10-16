using System.Net;
using System.Text.Json;
using Sedno.Infrastructure;
using Xunit;

namespace Sedno.UnitTests;

public sealed class ResponsesClientTests
{
    [Fact]
    public void PolishPromptIsEmbeddedInMainAssembly()
    {
        using var stream = typeof(ResponsesClient).Assembly.GetManifestResourceStream("Sedno.Infrastructure.Prompts.simplify.pl.txt");
        Assert.NotNull(stream);
        using var reader = new StreamReader(stream);
        Assert.Contains("Zwracaj wyłącznie uproszczony tekst po polsku", reader.ReadToEnd());
    }

    private sealed class Clock : TimeProvider
    {
        public Action? Elapse;
        public override ITimer CreateTimer(TimerCallback callback, object? state, TimeSpan dueTime, TimeSpan period)
        {
            Assert.Equal(TimeSpan.FromSeconds(8), dueTime);
            Elapse = () => callback(state);
            return new TimerStub();
        }
        private sealed class TimerStub : ITimer
        {
            public bool Change(TimeSpan dueTime, TimeSpan period) => true;
            public void Dispose() { }
            public ValueTask DisposeAsync() => ValueTask.CompletedTask;
        }
    }

    [Fact]
    public async Task DeadlineUsesInjectedClock()
    {
        var clock = new Clock();
        using var client = new HttpClient(new Handler(async (_, ct) =>
        {
            clock.Elapse!();
            await Task.Delay(Timeout.Infinite, ct);
            return new(HttpStatusCode.OK);
        }));
        var probe = new ResponsesClient(client, "test-key", "test-model", "Instrukcje.", "none", "fast", clock);
        await Assert.ThrowsAsync<Sedno.Application.SimplificationTimeoutException>(() => probe.SimplifyAsync("Tekst.", default));
    }

    private sealed class Handler(Func<HttpRequestMessage, CancellationToken, Task<HttpResponseMessage>> send) : HttpMessageHandler
    {
        public int Calls { get; private set; }
        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken ct)
        {
            Calls++;
            return send(request, ct);
        }
    }

    private const string Completed = """
        {"status":"completed","service_tier":"priority","usage":{"input_tokens":90,"output_tokens":12},
        "output":[{"type":"message","role":"assistant","status":"completed",
        "content":[{"type":"output_text","text":"Prosty tekst."}]}]}
        """;

    [Theory]
    [InlineData("default")]
    [InlineData("fast")]
    public async Task RequestIsStatelessAndReportsActualTier(string tier)
    {
        using var client = new HttpClient(new Handler(async (request, ct) =>
        {
            Assert.Equal("https://api.openai.com/v1/responses", request.RequestUri!.AbsoluteUri);
            using var body = JsonDocument.Parse(await request.Content!.ReadAsStringAsync(ct));
            var root = body.RootElement;
            Assert.False(root.GetProperty("store").GetBoolean());
            Assert.False(root.TryGetProperty("previous_response_id", out _));
            Assert.False(root.TryGetProperty("conversation", out _));
            Assert.Equal(tier, root.GetProperty("service_tier").GetString());
            Assert.Equal("test-model", root.GetProperty("model").GetString());
            Assert.Equal("low", root.GetProperty("reasoning").GetProperty("effort").GetString());
            Assert.Equal("Instrukcje.", root.GetProperty("instructions").GetString());
            Assert.Equal("Tekst.", root.GetProperty("input")[0].GetProperty("content").GetString());
            Assert.Single(root.GetProperty("input").EnumerateArray());
            return new(HttpStatusCode.OK) { Content = new StringContent(Completed) };
        }));
        var probe = new ResponsesClient(client, "test-key", "test-model", "Instrukcje.", "low", tier);
        Assert.Equal("Prosty tekst.", await probe.SimplifyAsync("Tekst.", default));
        Assert.Equal("priority", probe.ServedTier);
        Assert.Equal(90, probe.InputTokens);
        Assert.Equal(12, probe.OutputTokens);
    }

    [Theory]
    [InlineData(429, "secret upstream content")]
    [InlineData(200, "not json")]
    [InlineData(200, "{\"status\":\"incomplete\"}")]
    [InlineData(200, "{\"status\":\"completed\",\"output\":[]}")]
    public async Task FailureIsSanitizedAndNotRetried(int status, string body)
    {
        var handler = new Handler((_, _) => Task.FromResult(new HttpResponseMessage((HttpStatusCode)status)
        { Content = new StringContent(body) }));
        using var client = new HttpClient(handler);
        var probe = new ResponsesClient(client, "test-key", "test-model", "Instrukcje.", "none", "fast");
        var error = await Assert.ThrowsAsync<ModelProviderException>(() => probe.SimplifyAsync("Tekst.", default));
        Assert.Null(error.InnerException);
        Assert.DoesNotContain(body, error.ToString());
        Assert.Equal(1, handler.Calls);
    }

    [Fact]
    public async Task CancellationPropagates()
    {
        using var cts = new CancellationTokenSource();
        using var client = new HttpClient(new Handler(async (_, ct) =>
        {
            cts.Cancel();
            await Task.Delay(Timeout.Infinite, ct);
            return new(HttpStatusCode.OK);
        }));
        var probe = new ResponsesClient(client, "test-key", "test-model", "Instrukcje.", "none", "fast");
        var error = await Assert.ThrowsAsync<OperationCanceledException>(() => probe.SimplifyAsync("Tekst.", cts.Token));
        Assert.Equal(cts.Token, error.CancellationToken);
    }
}
