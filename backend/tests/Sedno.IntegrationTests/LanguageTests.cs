using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Sedno.Application;
using Xunit;

namespace Sedno.IntegrationTests;

[Collection("backend")]
public sealed class LanguageTests(BackendFixture fixture)
{
    private sealed class Model : IModelProvider
    {
        public readonly List<(string Language, bool Correct)> Calls = [];
        public Task<string> SimplifyAsync(string text, CancellationToken ct) => SimplifyAsync(text, "pl", ct);
        public Task<string> SimplifyAsync(string text, string language, CancellationToken ct)
        {
            Calls.Add((language, false));
            return Task.FromResult("Simple text.");
        }
        public Task<string> CorrectAsync(string text, string language, CancellationToken ct)
        {
            Calls.Add((language, true));
            return Task.FromResult("Correct text.");
        }
    }

    public static IEnumerable<object[]> AddedLanguages => TextLanguages.All.Where(language => language != "pl").Select(language => new object[] { language });

    [Theory]
    [MemberData(nameof(AddedLanguages))]
    public async Task LanguagesShareQuotaAndCannotReuseAnIdForAnotherLanguage(string language)
    {
        var model = new Model();
        await using var factory = fixture.Factory.WithWebHostBuilder(web => web.ConfigureTestServices(services =>
        {
            services.RemoveAll<IModelProvider>(); services.AddSingleton<IModelProvider>(model);
        }));
        using var client = factory.CreateClient();
        var guest = await (await client.PostAsJsonAsync("/v1/guest-sessions", new { installationId = Guid.NewGuid().ToString() }))
            .Content.ReadFromJsonAsync<GuestSessionDto>();
        client.DefaultRequestHeaders.Authorization = new("Bearer", guest!.AccessToken);
        var legacy = await client.PostAsJsonAsync("/v1/simplifications", new { requestId = "same-id", text = "Text" });
        Assert.Equal(HttpStatusCode.OK, legacy.StatusCode);
        var conflict = await client.PostAsJsonAsync("/v1/simplifications", new { requestId = "same-id", text = "Text", language });
        Assert.Equal(HttpStatusCode.Conflict, conflict.StatusCode);
        foreach (var mode in new[] { "simplify", "correct" })
        {
            using var response = await client.PostAsJsonAsync("/v1/simplifications", new { requestId = language + "-" + mode, text = "Text", language, mode });
            Assert.Equal(HttpStatusCode.OK, response.StatusCode);
            var result = await response.Content.ReadFromJsonAsync<SimplificationResponseDto>();
            Assert.Equal(language, result!.Result.Language);
            Assert.Equal(mode, result.Result.Mode);
        }
        var quota = await client.GetFromJsonAsync<QuotaDto>("/v1/quota");
        Assert.Equal(3, quota!.Used);
        Assert.Equal(new[] { ("pl", false), (language, false), (language, true) }, model.Calls);
        using var rejected = await client.PostAsJsonAsync("/v1/simplifications", new { requestId = "unsupported", text = "Text", language = "xx" });
        Assert.Equal(HttpStatusCode.BadRequest, rejected.StatusCode);
        Assert.Contains("invalid_language", await rejected.Content.ReadAsStringAsync());
        Assert.Equal(3, model.Calls.Count);
    }
}
