namespace Sedno.Infrastructure;

public static class CorrectionPrompt
{
    public static string Text { get; } = Load();
    public static string ForLanguage(string language) => language switch
    {
        "pl" => Text,
        "en" => English.Value,
        _ => throw new ArgumentException("Unsupported text language.", nameof(language))
    };
    // API language "en" selects the British English prompt variant.
    private static readonly Lazy<string> English = new(() => Load("en-gb"));
    private static string Load(string language = "pl")
    {
        using var stream = typeof(CorrectionPrompt).Assembly.GetManifestResourceStream($"Sedno.Infrastructure.Prompts.correct.{language}.txt")
            ?? throw new InvalidOperationException("Brak promptu poprawiania.");
        using var reader = new StreamReader(stream);
        var text = reader.ReadToEnd();
        if (string.IsNullOrWhiteSpace(text)) throw new InvalidOperationException("Pusty prompt poprawiania.");
        return text;
    }
}
