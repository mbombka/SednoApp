using System.Globalization;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Sedno.Application;
using System.Diagnostics.Metrics;

namespace Sedno.Infrastructure;

// Shared transport; production settings are restricted by OpenAiModelOptions.
public sealed class ResponsesClient(HttpClient client, string apiKey, string model,
    string instructions, string effort, string tier, TimeProvider? clock = null, int maxOutputTokens = 4096, int timeoutSeconds = 8,
    SimplificationTimings? timings = null) : IModelProvider
{
    private static readonly Meter Meter = new("Sedno.OpenAI.Responses");
    private static readonly Histogram<double> Duration = Meter.CreateHistogram<double>("sedno.responses.duration", "s");
    private static readonly Counter<long> Tokens = Meter.CreateCounter<long>("sedno.responses.tokens");
    public string? ServedTier { get; private set; }
    public int? InputTokens { get; private set; }
    public int? OutputTokens { get; private set; }
    public int? HttpStatus { get; private set; }

    public async Task<string> SimplifyAsync(string text, CancellationToken cancellationToken)
    {
        SimplificationService.Validate(new("provider", text));
        ServedTier = null;
        InputTokens = OutputTokens = HttpStatus = null;
        using var timeout = new CancellationTokenSource(TimeSpan.FromSeconds(timeoutSeconds), clock ?? TimeProvider.System);
        using var linked = CancellationTokenSource.CreateLinkedTokenSource(cancellationToken, timeout.Token);
        var time = clock ?? TimeProvider.System;
        var started = time.GetTimestamp();
        var outcome = "failed";
        try
        {
            using var request = new HttpRequestMessage(HttpMethod.Post, "https://api.openai.com/v1/responses");
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", apiKey);
            request.Content = JsonContent.Create(new
            {
                model,
                instructions,
                input = new[] { new { role = "user", content = text } },
                store = false,
                service_tier = tier,
                reasoning = new { effort },
                max_output_tokens = maxOutputTokens
            });
            using var response = await client.SendAsync(request, HttpCompletionOption.ResponseHeadersRead, linked.Token);
            timings?.Milestone(SimplificationStage.ResponsesHeaders, started);
            HttpStatus = (int)response.StatusCode;
            if (!response.IsSuccessStatusCode) throw new ModelProviderException();
            await response.Content.LoadIntoBufferAsync(256 * 1024, linked.Token);
            using var document = JsonDocument.Parse(await response.Content.ReadAsByteArrayAsync(linked.Token));
            var root = document.RootElement;
            if (root.GetProperty("status").GetString() != "completed" ||
                (root.TryGetProperty("error", out var error) && error.ValueKind != JsonValueKind.Null))
                throw new ModelProviderException();
            var messages = root.GetProperty("output").EnumerateArray()
                .Where(item => item.GetProperty("type").GetString() == "message").ToArray();
            if (messages.Length != 1) throw new ModelProviderException();
            var message = messages[0];
            if (message.GetProperty("role").GetString() != "assistant" ||
                message.GetProperty("status").GetString() != "completed") throw new ModelProviderException();
            var parts = message.GetProperty("content").EnumerateArray().ToArray();
            if (parts.Length == 0 || parts.Any(part => part.GetProperty("type").GetString() != "output_text"))
                throw new ModelProviderException();
            var result = string.Join("\n", parts.Select(part => part.GetProperty("text").GetString())).Trim();
            if (string.IsNullOrWhiteSpace(result) || new StringInfo(result).LengthInTextElements > 16000)
                throw new ModelProviderException();
            if (root.TryGetProperty("service_tier", out var served))
            {
                var value = served.GetString();
                ServedTier = value is "default" or "priority" or "fast" or "flex" or "scale" or "ultrafast"
                    ? value : "unknown";
            }
            if (root.TryGetProperty("usage", out var usage) && usage.ValueKind == JsonValueKind.Object)
            {
                InputTokens = ReadCount(usage, "input_tokens");
                OutputTokens = ReadCount(usage, "output_tokens");
            }
            outcome = "succeeded";
            timings?.Milestone(SimplificationStage.ResponsesComplete, started);
            if (InputTokens is int inputCount) Tokens.Add(inputCount, new KeyValuePair<string, object?>("kind", "input"));
            if (OutputTokens is int outputCount) Tokens.Add(outputCount, new KeyValuePair<string, object?>("kind", "output"));
            return result;
        }
        catch (OperationCanceledException) when (cancellationToken.IsCancellationRequested)
        {
            outcome = "cancelled";
            throw new OperationCanceledException(cancellationToken);
        }
        catch (OperationCanceledException) when (timeout.IsCancellationRequested)
        {
            outcome = "timeout";
            throw new SimplificationTimeoutException();
        }
        catch (Exception ex) when (ex is HttpRequestException or OperationCanceledException or JsonException
            or KeyNotFoundException or InvalidOperationException or ModelProviderException or IOException)
        {
            throw new ModelProviderException();
        }
        finally
        {
            Duration.Record(time.GetElapsedTime(started).TotalSeconds,
                new("outcome", outcome), new("service_tier", ServedTier ?? "unknown"));
        }
    }

    private static int? ReadCount(JsonElement usage, string key) =>
        usage.TryGetProperty(key, out var value) && value.TryGetInt32(out var count) && count >= 0 ? count : null;
}
