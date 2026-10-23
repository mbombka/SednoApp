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
    private readonly IReadOnlyDictionary<string, ResponsesClient> _simplifiers;
    private readonly IReadOnlyDictionary<string, ResponsesClient> _correctors;
    public OpenAiModelProvider(HttpClient client, OpenAiModelOptions options, TimeProvider? clock = null,
        SimplificationTimings? timings = null)
    {
        options.Validate();
        ResponsesClient Create(string prompt) => new(client, options.ApiKey, options.Model, prompt,
            options.ReasoningEffort, options.ServiceTier, clock, options.MaxOutputTokens, options.TimeoutSeconds, timings);
        _simplifiers = new[] { "pl", "en" }.ToDictionary(language => language,
            language => Create(SimplificationPrompt.ForLanguage(language)));
        _correctors = new[] { "pl", "en" }.ToDictionary(language => language,
            language => Create(CorrectionPrompt.ForLanguage(language)));
    }
    public Task<string> SimplifyAsync(string text, CancellationToken cancellationToken) =>
        SimplifyAsync(text, "pl", cancellationToken);
    public Task<string> CorrectAsync(string text, CancellationToken cancellationToken) =>
        CorrectAsync(text, "pl", cancellationToken);
    public Task<string> SimplifyAsync(string text, string language, CancellationToken cancellationToken) =>
        _simplifiers[language].SimplifyAsync(text, cancellationToken);
    public Task<string> CorrectAsync(string text, string language, CancellationToken cancellationToken) =>
        _correctors[language].SimplifyAsync(text, cancellationToken);
}
