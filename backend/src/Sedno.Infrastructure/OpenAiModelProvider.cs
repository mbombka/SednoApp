using Sedno.Application;

namespace Sedno.Infrastructure;

public sealed class OpenAiModelOptions
{
    public string ApiKey { get; set; } = "";
    public string Model { get; init; } = "gpt-6-luna";
    public string ServiceTier { get; init; } = "default";
    public string ReasoningEffort { get; init; } = "none";
    public int MaxOutputTokens { get; init; } = 4096;
    public int TimeoutSeconds { get; init; } = 8;

    public void Validate()
    {
        if (string.IsNullOrWhiteSpace(ApiKey) || ApiKey.Any(char.IsWhiteSpace))
            throw new InvalidOperationException("OpenAI:ApiKey is required and must not contain whitespace.");
        if (Model != "gpt-6-luna")
            throw new InvalidOperationException("Model:OpenAI:Model must be gpt-6-luna; evaluate other models before enabling them.");
        if (ServiceTier != "default" || ReasoningEffort != "none")
            throw new InvalidOperationException("Production Responses requires default tier and none reasoning; use benchmarks for experiments.");
        if (MaxOutputTokens != 4096)
            throw new InvalidOperationException("Model:OpenAI:MaxOutputTokens must be 4096.");
        if (TimeoutSeconds != 8)
            throw new InvalidOperationException("Model:OpenAI:TimeoutSeconds must be 8.");
    }
}

// Deliberately excludes upstream bodies, text, tokens and underlying exceptions.
public sealed class ModelProviderException() : Exception("Usługa upraszczania jest chwilowo niedostępna.");

public sealed class OpenAiModelProvider : IModelProvider
{
    private readonly ResponsesClient _responses;
    public OpenAiModelProvider(HttpClient client, OpenAiModelOptions options, TimeProvider? clock = null,
        SimplificationTimings? timings = null)
    {
        options.Validate();
        _responses = new ResponsesClient(client, options.ApiKey, options.Model, SimplificationPrompt.Text,
            options.ReasoningEffort, options.ServiceTier, clock, options.MaxOutputTokens, options.TimeoutSeconds, timings);
    }
    public Task<string> SimplifyAsync(string text, CancellationToken cancellationToken) =>
        _responses.SimplifyAsync(text, cancellationToken);
}
