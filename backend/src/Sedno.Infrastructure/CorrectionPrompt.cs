namespace Sedno.Infrastructure;

public static class CorrectionPrompt
{
    public static string Text { get; } = Load();
    private static string Load()
    {
        using var stream = typeof(CorrectionPrompt).Assembly.GetManifestResourceStream("Sedno.Infrastructure.Prompts.correct.pl.txt")
            ?? throw new InvalidOperationException("Brak promptu poprawiania.");
        using var reader = new StreamReader(stream);
        var text = reader.ReadToEnd();
        if (string.IsNullOrWhiteSpace(text)) throw new InvalidOperationException("Pusty prompt poprawiania.");
        return text;
    }
}
