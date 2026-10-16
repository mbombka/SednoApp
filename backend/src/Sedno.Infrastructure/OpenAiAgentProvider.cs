using System.Runtime.CompilerServices;
using System.Text;
using System.Diagnostics.Metrics;
using System.Globalization;
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
    public int TimeoutSeconds { get; init; } = 8;

    public void Validate()
    {
        if (string.IsNullOrWhiteSpace(ApiKey) || ApiKey.Any(char.IsWhiteSpace))
            throw new InvalidOperationException("OpenAI:ApiKey is required and must not contain whitespace.");
        if (!AgentId.StartsWith("agent_", StringComparison.Ordinal) || AgentId.Length is < 7 or > 64 ||
            AgentId.Any(c => !char.IsAsciiLetterOrDigit(c) && c != '_'))
            throw new InvalidOperationException("OpenAI:AgentId must be a saved agent identifier.");
        // Reserve time for the API to return a timeout before the mobile 10-second deadline.
        if (TimeoutSeconds is < 1 or > 8)
            throw new InvalidOperationException("OpenAI:TimeoutSeconds must be between 1 and 8.");
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
    private readonly IAgentSessionCleanupQueue _cleanup;

    public OpenAiAgentProvider(HttpClient client, OpenAiAgentOptions options, TimeProvider clock,
        ILogger<OpenAiAgentProvider> logger, IAgentSessionCleanupQueue cleanup)
    {
        options.Validate();
        _client = client;
        _options = options;
        _clock = clock;
        _logger = logger;
        _cleanup = cleanup;
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
            // Conversation-only sessions require initial input. Do not retry a lost
            // create response: the provider may already be processing this text.
            using var response = await SendAsync(HttpMethod.Post, Sessions, new
            {
                agent_id = _options.AgentId,
                stream = true,
                metadata = new { sedno_purpose = AgentSessionCleanupWorker.Purpose },
                environment = new { type = "none" },
                input = new[] { new { role = "user", content = new[] { new { type = "input_text", text } } } },
                agent = new
                {
                    // Model and instructions are inherited from the saved agent.
                    tools = Array.Empty<object>(),
                    multi_agent = new { enabled = false },
                    text = new { format = new { type = "text" } }
                }
            }, linked.Token);
            if (response.Content.Headers.ContentType?.MediaType != "text/event-stream")
                throw new ModelProviderException();
            using var stream = await response.Content.ReadAsStreamAsync(linked.Token);
            string? turnId = null;
            string? result = null;
            var completed = false;
            await foreach (var data in ReadEventsAsync(stream, linked.Token))
            {
                using var document = JsonDocument.Parse(data);
                var root = document.RootElement;
                var type = root.GetProperty("type").GetString();
                if (type == "agent.session.created")
                {
                    var id = root.GetProperty("session").GetProperty("id").GetString();
                    if (!SafeId(id) || sessionId is not null) throw new ModelProviderException();
                    sessionId = id;
                    await _cleanup.TrackAsync(id!, CancellationToken.None);
                    continue;
                }
                if (sessionId is null) throw new ModelProviderException();
                if (root.TryGetProperty("session_id", out var session) && session.GetString() != sessionId)
                    throw new ModelProviderException();
                if (root.TryGetProperty("turn_id", out var turnRef) && turnRef.ValueKind != JsonValueKind.Null)
                {
                    var id = turnRef.GetString();
                    if (!SafeId(id) || (turnId is not null && turnId != id)) throw new ModelProviderException();
                    turnId = id;
                }
                switch (type)
                {
                    case "agent.session.turn.item.done":
                        var item = root.GetProperty("item");
                        if (item.GetProperty("type").GetString() == "message" &&
                            item.GetProperty("role").GetString() == "assistant" &&
                            item.GetProperty("phase").GetString() == "final_answer")
                        {
                            if (result is not null || turnId is null) throw new ModelProviderException();
                            result = ReadFinalAnswer(item, turnId);
                        }
                        break;
                    case "agent.session.turn.completed":
                        var turn = root.GetProperty("turn");
                        if (turnId is null || turn.GetProperty("id").GetString() != turnId ||
                            turn.GetProperty("status").GetString() != "completed" || result is null ||
                            (turn.TryGetProperty("error", out var error) && error.ValueKind != JsonValueKind.Null))
                            throw new ModelProviderException();
                        RecordUsage(root.TryGetProperty("usage", out var usage) && usage.ValueKind == JsonValueKind.Object
                            ? root : turn);
                        completed = true;
                        break;
                    case "error":
                    case "agent.session.turn.failed":
                    case "agent.session.turn.cancelled":
                    case "agent.session.failed":
                    case "agent.session.requires_action":
                        throw new ModelProviderException();
                }
                if (completed) break;
            }
            // Neither EOF, idle, nor text deltas prove a successful complete turn.
            if (!completed || result is null) throw new ModelProviderException();
            outcome = "succeeded";
            return result;
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
        {
            outcome = "cancelled";
            throw new OperationCanceledException(cancellationToken);
        }
        catch (OperationCanceledException) when (timeout.IsCancellationRequested)
        {
            throw new SimplificationTimeoutException();
        }
        catch (Exception ex) when (ex is HttpRequestException or OperationCanceledException or JsonException
            or KeyNotFoundException or InvalidOperationException or ModelProviderException or FormatException
            or IOException or DecoderFallbackException)
        {
            // Never attach the upstream exception: it can contain credentials or content.
            throw new ModelProviderException();
        }
        finally
        {
            if (SafeId(sessionId)) await _cleanup.ReadyAsync(sessionId!, CancellationToken.None, outcome != "succeeded");
            else if (outcome != "succeeded") _cleanup.RequestRecovery();
            Duration.Record(_clock.GetElapsedTime(started).TotalSeconds,
                new("agent_id", _options.AgentId), new("outcome", outcome));
        }
    }

    private static bool SafeId(string? id) => !string.IsNullOrEmpty(id) && id.Length <= 128 &&
        id.All(c => char.IsAsciiLetterOrDigit(c) || c is '_' or '-');

    private static string ReadFinalAnswer(JsonElement message, string turnId)
    {
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
        // Status only: upstream error bodies can echo user text or credentials.
        _logger.LogWarning("OpenAI Agents API zwróciło HTTP {StatusCode}.", (int)response.StatusCode);
        response.Dispose();
        throw new ModelProviderException();
    }

    private static async IAsyncEnumerable<string> ReadEventsAsync(Stream stream,
        [EnumeratorCancellation] CancellationToken ct)
    {
        // Bound both individual SSE frames and the full stream, including ignored deltas.
        const int frameLimit = 256 * 1024;
        var buffer = new byte[4096];
        var line = new List<byte>();
        var data = new StringBuilder();
        var encoding = new UTF8Encoding(false, true);
        var total = 0;
        int count;
        while ((count = await stream.ReadAsync(buffer, ct)) != 0)
        {
            total += count;
            if (total > 4 * 1024 * 1024) throw new ModelProviderException();
            for (var i = 0; i < count; i++)
            {
                if (buffer[i] != (byte)'\n')
                {
                    line.Add(buffer[i]);
                    if (line.Count > frameLimit) throw new ModelProviderException();
                    continue;
                }
                var value = encoding.GetString(line.ToArray()).TrimEnd('\r');
                line.Clear();
                if (value.Length == 0)
                {
                    if (data.Length == 0) continue;
                    yield return data.ToString();
                    data.Clear();
                }
                else if (value.StartsWith("data:", StringComparison.Ordinal))
                {
                    var part = value[5..];
                    if (part.StartsWith(' ')) part = part[1..];
                    if (data.Length > 0) data.Append('\n');
                    data.Append(part);
                    if (data.Length > frameLimit) throw new ModelProviderException();
                }
            }
        }
    }

}
