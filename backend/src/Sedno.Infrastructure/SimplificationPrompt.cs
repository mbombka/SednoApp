using Sedno.Application;
using System.Collections.Concurrent;
using System.Security.Cryptography;
using System.Text;
namespace Sedno.Infrastructure;

public static class SimplificationPrompt
{
    public static string Text { get; } = Load();
    public static string Sha256 { get; } = Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(Text)));
    private static readonly ConcurrentDictionary<string, Lazy<string>> Translations = new();
    public static string ForLanguage(string language)
    {
        var variant = TextLanguages.PromptVariant(language);
        return language == "pl" ? Text : Translations.GetOrAdd(variant,
            key => new Lazy<string>(() => Load(key))).Value;
    }
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
