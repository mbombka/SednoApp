using System.Security.Cryptography;
using System.Text;
namespace Sedno.Infrastructure;

public static class SimplificationPrompt
{
    public static string Text { get; } = Load();
    public static string Sha256 { get; } = Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(Text)));
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
        using var stream = typeof(SimplificationPrompt).Assembly.GetManifestResourceStream($"Sedno.Infrastructure.Prompts.simplify.{language}.txt")
            ?? throw new InvalidOperationException("Brak promptu upraszczania.");
        using var reader = new StreamReader(stream);
        var text = reader.ReadToEnd();
        if (string.IsNullOrWhiteSpace(text)) throw new InvalidOperationException("Pusty prompt upraszczania.");
        return text;
    }
}
