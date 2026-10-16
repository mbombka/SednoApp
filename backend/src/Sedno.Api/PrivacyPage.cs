public static class PrivacyPage
{
    public static readonly string Html = Read();

    private static string Read()
    {
        using var stream = typeof(PrivacyPage).Assembly.GetManifestResourceStream("Sedno.Api.PrivacyPage.html")
            ?? throw new InvalidOperationException("Missing privacy policy resource.");
        using var reader = new StreamReader(stream);
        return reader.ReadToEnd();
    }
}
