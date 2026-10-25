namespace Sedno.Application;

public static class TextLanguages
{
    public static IReadOnlyList<string> All { get; } = Array.AsReadOnly(new[]
    {
        "pl", "en", "en-US", "fr", "de", "it", "es", "pt", "sk", "cs", "ro", "nb", "sv"
    });

    public static bool IsSupported(string? language) => language is not null && All.Contains(language);

    public static string PromptVariant(string language) => language switch
    {
        "en" => "en-gb",
        "en-US" => "en-us",
        "nb" => "no",
        _ when IsSupported(language) => language,
        _ => throw new ArgumentException("Unsupported text language.", nameof(language))
    };
}
