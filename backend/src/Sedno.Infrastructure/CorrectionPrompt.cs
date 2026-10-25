using Sedno.Application;
using System.Collections.Concurrent;
namespace Sedno.Infrastructure;

public static class CorrectionPrompt
{
    public static string Text { get; } = Load();
    private static readonly ConcurrentDictionary<string, Lazy<string>> Translations = new();
    public static string ForLanguage(string language)
    {
        var variant = TextLanguages.PromptVariant(language);
        return language == "pl" ? Text : Translations.GetOrAdd(variant,
            key => new Lazy<string>(() => Load(key))).Value;
    }
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
