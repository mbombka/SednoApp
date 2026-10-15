using System.Diagnostics;
using System.Diagnostics.Metrics;
using System.Globalization;
using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.Extensions.Logging;
using Sedno.Application;

namespace Sedno.Infrastructure;

public sealed class OpenAiAgentOptions
{
    public string ApiKey { get; init; } = "";
    public string AgentId { get; init; } = "";
    public int TimeoutSeconds { get; init; } = 20;

    public void Validate()
    {
        if (string.IsNullOrWhiteSpace(ApiKey) || ApiKey.Any(char.IsWhiteSpace))
            throw new InvalidOperationException("OpenAI:ApiKey is required and must not contain whitespace.");
        if (!AgentId.StartsWith("agent_", StringComparison.Ordinal) || AgentId.Length is < 7 or > 64 ||
            AgentId.Any(c => !char.IsAsciiLetterOrDigit(c) && c != '_'))
            throw new InvalidOperationException("OpenAI:AgentId must be a saved agent identifier.");
        // Leave room for cleanup within the mobile client's 30-second request timeout.
        if (TimeoutSeconds is < 1 or > 25)
            throw new InvalidOperationException("OpenAI:TimeoutSeconds must be between 1 and 25.");
    }
}

public sealed class OpenAiAgentProvider : IModelProvider
{
    private const string Sessions = "https://api.openai.com/v1/agents/sessions";
    private static readonly Meter Meter = new("Sedno.OpenAI.Agents");
    private static readonly Counter<long> Tokens = Meter.CreateCounter<long>("sedno.agent.tokens");
    private static readonly Histogram<double> Duration = Meter.CreateHistogram<double>("sedno.agent.duration", "s");
    private readonly HttpClient _client;
    private readonly OpenAiAgentOptions _options;
    private readonly TimeProvider _clock;
    private readonly ILogger<OpenAiAgentProvider> _logger;

    public OpenAiAgentProvider(HttpClient client, OpenAiAgentOptions options, TimeProvider clock,
        ILogger<OpenAiAgentProvider> logger)
    {
        options.Validate();
        _client = client;
        _options = options;
        _clock = clock;
        _logger = logger;
    }

    public async Task<string> SimplifyAsync(string text, CancellationToken cancellationToken)
    {
        SimplificationService.Validate(new("agent", text));
        cancellationToken.ThrowIfCancellationRequested();
        var started = _clock.GetTimestamp();
        var outcome = "failed";
        string? sessionId = null;
        using var timeout = new CancellationTokenSource(TimeSpan.FromSeconds(_options.TimeoutSeconds), _clock);
        using var linked = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken, timeout.Token);
        try
        {
            // Acquire a cleanup handle BEFORE sending user content. A lost create response
            // can leave an empty session, but cannot leave a submitted text without a known ID.
            using (var created = await SendJsonAsync(HttpMethod.Post, Sessions, new
            {
                agent_id = _options.AgentId,
                environment = new { type = "none" },
                agent = new
                {
                    // Model and instructions are inherited from the saved agent.
                    tools = Array.Empty<object>(),
                    multi_agent = new { enabled = false },
                    text = new { format = new { type = "text" } }
                }
            }, linked.Token))
            {
                sessionId = created.RootElement.GetProperty("id").GetString();
                if (!SafeId(sessionId)) throw new ModelProviderException();
            }

            var sessionUrl = $"{Sessions}/{sessionId}";
            using (var accepted = await SendAsync(HttpMethod.Post, $"{sessionUrl}/events", new
            {
                events = new[] { new { type = "agent.session.input.message", input = new[]
                {
                    new { role = "user", content = new[] { new { type = "input_text", text } } }
                } } }
            }, linked.Token)) { }

            string? turnId = null;
            while (turnId is null)
            {
                using var turns = await SendJsonAsync(HttpMethod.Get, $"{sessionUrl}/turns?order=asc&limit=2", null, linked.Token);
                var root = turns.RootElement;
                if (root.GetProperty("has_more").GetBoolean()) throw new ModelProviderException();
                var data = root.GetProperty("data").EnumerateArray().ToArray();
                if (data.Length > 1) throw new ModelProviderException();
                if (data.Length == 1)
                {
                    var turn = data[0];
                    switch (turn.GetProperty("status").GetString())
                    {
                        case "completed":
                            if (turn.TryGetProperty("error", out var error) && error.ValueKind != JsonValueKind.Null)
                                throw new ModelProviderException();
                            turnId = turn.GetProperty("id").GetString();
                            if (!SafeId(turnId)) throw new ModelProviderException();
                            RecordUsage(turn);
                            break;
                        case "queued":
                        case "in_progress":
                            break;
                        default:
                            throw new ModelProviderException();
                    }
                }
                if (turnId is null) await Task.Delay(TimeSpan.FromMilliseconds(250), _clock, linked.Token);
            }

            using var items = await SendJsonAsync(HttpMethod.Get, $"{sessionUrl}/items?order=asc&limit=100", null, linked.Token);
            var result = ReadFinalAnswer(items.RootElement, turnId);
            outcome = "succeeded";
            return result;
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
        {
            outcome = "cancelled";
            throw new OperationCanceledException(cancellationToken);
        }
        catch (Exception ex) when (ex is HttpRequestException or OperationCanceledException or JsonException
            or KeyNotFoundException or InvalidOperationException or ModelProviderException or FormatException)
        {
            // Never attach the upstream exception: it can contain credentials or content.
            throw new ModelProviderException();
        }
        finally
        {
            if (SafeId(sessionId)) await DeleteSessionAsync(sessionId!);
            Duration.Record(_clock.GetElapsedTime(started).TotalSeconds,
                new("agent_id", _options.AgentId), new("outcome", outcome));
        }
    }

    private static bool SafeId(string? id) => !string.IsNullOrEmpty(id) && id.Length <= 128 &&
        id.All(c => char.IsAsciiLetterOrDigit(c) || c is '_' or '-');

    private static string ReadFinalAnswer(JsonElement root, string turnId)
    {
        if (root.GetProperty("has_more").GetBoolean()) throw new ModelProviderException();
        var messages = root.GetProperty("data").EnumerateArray()
            .Where(item => item.GetProperty("type").GetString() == "message" &&
                item.GetProperty("role").GetString() == "assistant" &&
                item.GetProperty("phase").GetString() == "final_answer").ToArray();
        if (messages.Length != 1) throw new ModelProviderException();
        var message = messages[0];
        if (message.GetProperty("status").GetString() != "completed" ||
            message.GetProperty("turn_id").GetString() != turnId) throw new ModelProviderException();
        var parts = message.GetProperty("content").EnumerateArray().ToArray();
        if (parts.Length == 0 || parts.Any(part => part.GetProperty("type").GetString() != "output_text"))
            throw new ModelProviderException();
        var result = string.Join("\n", parts.Select(part => part.GetProperty("text").GetString())).Trim();
        if (string.IsNullOrWhiteSpace(result) || new StringInfo(result).LengthInTextElements > 16000)
            throw new ModelProviderException();
        return result;
    }

    private void RecordUsage(JsonElement turn)
    {
        // Best-effort provider accounting, not a final bill. Missing usage is not zero usage.
        if (!turn.TryGetProperty("usage", out var usage) || usage.ValueKind != JsonValueKind.Object) return;
        foreach (var kind in new[] { "input_tokens", "output_tokens" })
            if (usage.TryGetProperty(kind, out var count) && count.TryGetInt64(out var value) && value >= 0)
                Tokens.Add(value, new("agent_id", _options.AgentId), new("kind", kind));
    }

    private async Task<HttpResponseMessage> SendAsync(HttpMethod method, string url, object? body, CancellationToken ct)
    {
        using var request = new HttpRequestMessage(method, url);
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", _options.ApiKey);
        request.Headers.Add("OpenAI-Beta", "agents=v1");
        if (body is not null) request.Content = JsonContent.Create(body);
        // Never retry submissions: uncertain delivery can still incur provider costs.
        var response = await _client.SendAsync(request, HttpCompletionOption.ResponseHeadersRead, ct);
        if (response.IsSuccessStatusCode) return response;
        response.Dispose();
        throw new ModelProviderException();
    }

    private async Task<JsonDocument> SendJsonAsync(HttpMethod method, string url, object? body, CancellationToken ct)
    {
        using var response = await SendAsync(method, url, body, ct);
        await response.Content.LoadIntoBufferAsync(256 * 1024, ct);
        return JsonDocument.Parse(await response.Content.ReadAsByteArrayAsync(ct));
    }

    private async Task DeleteSessionAsync(string sessionId)
    {
        // Independent of client cancellation and model timeout. Retry deletion only.
        using var cleanup = new CancellationTokenSource(TimeSpan.FromSeconds(3), _clock);
        for (var attempt = 0; attempt < 2; attempt++)
        {
            try
            {
                using var request = new HttpRequestMessage(HttpMethod.Delete, $"{Sessions}/{sessionId}");
                request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", _options.ApiKey);
                request.Headers.Add("OpenAI-Beta", "agents=v1");
                using var response = await _client.SendAsync(request, HttpCompletionOption.ResponseHeadersRead, cleanup.Token);
                if (response.IsSuccessStatusCode || response.StatusCode == HttpStatusCode.NotFound) return;
            }
            catch (Exception ex) when (ex is HttpRequestException or OperationCanceledException) { }
            if (cleanup.IsCancellationRequested) break;
        }
        // No session ID, body, credentials or exception in logs. Operators reconcile
        // retained sessions in the dedicated project if cleanup fails or the process dies.
        _logger.LogWarning("Nie udało się usunąć sesji OpenAI. Sprawdź retencję sesji w projekcie Sedno.");
    }
}
