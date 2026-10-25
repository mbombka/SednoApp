using System.Net;
using System.Text.Json;
using Sedno.Application;
using Sedno.Infrastructure;
using Xunit;

namespace Sedno.UnitTests;

public sealed class LanguageTests
{
    [Fact]
    public void LegacyRequestsRemainPolishAndUnsupportedLanguagesAreRejected()
    {
        Assert.Equal("pl", new SimplificationInput("legacy", "Tekst").Language);
        foreach (var language in new[] { "xx", "en-GB", "", "EN", "pt-BR", "nn" })
        {
            var error = Assert.Throws<InputValidationException>(() =>
                SimplificationService.Validate(new("request", "Text", Language: language)));
            Assert.Equal("invalid_language", error.Code);
        }
        foreach (var language in TextLanguages.All)
            SimplificationService.Validate(new("request", "Text", Language: language));
    }

    [Fact]
    public void PromptsAreEmbeddedAndPolishAccessorsStayCompatible()
    {
        Assert.Equal(SimplificationPrompt.Text, SimplificationPrompt.ForLanguage("pl"));
        Assert.Equal(CorrectionPrompt.Text, CorrectionPrompt.ForLanguage("pl"));
        Assert.Equal(ReadEmbeddedPrompt("simplify.en-gb.txt"), SimplificationPrompt.ForLanguage("en"));
        Assert.Equal(ReadEmbeddedPrompt("correct.en-gb.txt"), CorrectionPrompt.ForLanguage("en"));
        Assert.Contains("British English", SimplificationPrompt.ForLanguage("en"));
        Assert.Contains("British English", CorrectionPrompt.ForLanguage("en"));
        Assert.NotEqual(SimplificationPrompt.ForLanguage("en"), CorrectionPrompt.ForLanguage("en"));
        foreach (var language in TextLanguages.All)
        {
            var variant = TextLanguages.PromptVariant(language);
            Assert.Equal(ReadEmbeddedPrompt($"simplify.{variant}.txt"), SimplificationPrompt.ForLanguage(language));
            Assert.Equal(ReadEmbeddedPrompt($"correct.{variant}.txt"), CorrectionPrompt.ForLanguage(language));
        }
        Assert.Throws<ArgumentException>(() => SimplificationPrompt.ForLanguage("xx"));
    }

    public static IEnumerable<object[]> LanguageModes => TextLanguages.All.SelectMany(language => new[] { new object[] { language, false }, new object[] { language, true } });

    [Theory]
    [MemberData(nameof(LanguageModes))]
    public async Task SelectedLanguageUsesItsPromptAndPreservesProductionPrivacySettings(string language, bool correct)
    {
        using var client = new HttpClient(new CaptureHandler(async request =>
        {
            using var json = JsonDocument.Parse(await request.Content!.ReadAsStringAsync());
            var root = json.RootElement;
            Assert.Equal(correct ? CorrectionPrompt.ForLanguage(language) : SimplificationPrompt.ForLanguage(language),
                root.GetProperty("instructions").GetString());
            Assert.False(root.GetProperty("store").GetBoolean());
            Assert.Equal(4096, root.GetProperty("max_output_tokens").GetInt32());
            Assert.Equal("none", root.GetProperty("reasoning").GetProperty("effort").GetString());
            Assert.Equal("default", root.GetProperty("service_tier").GetString());
            Assert.False(root.TryGetProperty("conversation", out _));
            Assert.False(root.TryGetProperty("previous_response_id", out _));
            return new(HttpStatusCode.OK)
            {
                Content = new StringContent("""{"status":"completed","output":[{"type":"message","role":"assistant","status":"completed","content":[{"type":"output_text","text":"Clear text."}]}]}""")
            };
        }));
        var model = new OpenAiModelProvider(client, new() { ApiKey = "synthetic-test-key" });
        var result = correct
            ? await model.CorrectAsync("Text", language, CancellationToken.None)
            : await model.SimplifyAsync("Text", language, CancellationToken.None);
        Assert.Equal("Clear text.", result);
    }

    private static string ReadEmbeddedPrompt(string fileName)
    {
        using var stream = typeof(SimplificationPrompt).Assembly.GetManifestResourceStream($"Sedno.Infrastructure.Prompts.{fileName}");
        Assert.NotNull(stream);
        using var reader = new StreamReader(stream);
        return reader.ReadToEnd();
    }

    private sealed class CaptureHandler(Func<HttpRequestMessage, Task<HttpResponseMessage>> respond) : HttpMessageHandler
    {
        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken ct) => respond(request);
    }
}
