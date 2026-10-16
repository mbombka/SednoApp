using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Sedno.Application;
using Sedno.Infrastructure;
using Xunit;

namespace Sedno.IntegrationTests;

[Collection("backend")]
public sealed class OpenAiApiTests(BackendFixture fixture)
{
    private sealed class Upstream : HttpMessageHandler
    {
        public int Calls;
        public string? Failure;
        protected override async Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken ct)
        {
            Calls++;
            using var body = JsonDocument.Parse(await request.Content!.ReadAsStringAsync(ct));
            Assert.Equal("default", body.RootElement.GetProperty("service_tier").GetString());
            Assert.Equal(SimplificationPrompt.Text, body.RootElement.GetProperty("instructions").GetString());
            Assert.False(body.RootElement.GetProperty("store").GetBoolean());
            if (Failure == "timeout") throw new TaskCanceledException("sensitive-upstream-error");
            if (Failure == "incomplete") return new HttpResponseMessage(HttpStatusCode.OK)
            { Content = new StringContent("{\"status\":\"incomplete\",\"output\":[]}") };
            return new HttpResponseMessage(Failure is not null ? HttpStatusCode.TooManyRequests : HttpStatusCode.OK)
            {
                Content = new StringContent(Failure is not null ? "sensitive-upstream-error" : JsonSerializer.Serialize(new
                {
                    status = "completed",
                    output = new[] { new { type = "message", role = "assistant", status = "completed",
                        content = new[] { new { type = "output_text", text = "Nie płać 20 zł po 31.12.2026." } } } }
                }))
            };
        }
    }

    [Theory]
    [InlineData("http")]
    [InlineData("timeout")]
    [InlineData("incomplete")]
    public async Task RealAdapterUsesQuotaAndIdempotencyWithoutLeakingUpstreamData(string failure)
    {
        fixture.Clock.Set(new(2026, 10, 14, 12, 0, 0, TimeSpan.Zero));
        var upstream = new Upstream();
        await using var factory = fixture.Factory.WithWebHostBuilder(web => web.ConfigureTestServices(services =>
        {
            services.RemoveAll<IModelProvider>();
            var config = new ConfigurationBuilder().AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["Model:Provider"] = "openai",
                ["OpenAI:ApiKey"] = "test-openai-secret"
            }).Build();
            services.AddSednoModel(config, isDevelopment: false);
            services.AddHttpClient("openai-model").ConfigurePrimaryHttpMessageHandler(() => upstream);
        }));
        using var client = factory.CreateClient();
        using var guest = await client.PostAsJsonAsync("/v1/guest-sessions", new { installationId = Guid.NewGuid().ToString() });
        guest.EnsureSuccessStatusCode();
        using var session = JsonDocument.Parse(await guest.Content.ReadAsStringAsync());
        var token = session.RootElement.GetProperty("accessToken").GetString();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);
        const string input = "Nie należy uiszczać kwoty 20 zł po 31.12.2026. PoufnyTekstAi987";
        async Task<HttpResponseMessage> Submit(string id) =>
            await client.PostAsJsonAsync("/v1/simplifications", new { requestId = id, text = input });
        using var success = await Submit("ai-success");
        Assert.Equal(HttpStatusCode.OK, success.StatusCode);
        using var result = JsonDocument.Parse(await success.Content.ReadAsStringAsync());
        Assert.Equal("Nie płać 20 zł po 31.12.2026.", result.RootElement.GetProperty("result").GetProperty("text").GetString());
        Assert.Equal(4, result.RootElement.GetProperty("quota").GetProperty("remaining").GetInt32());
        using var duplicate = await Submit("ai-success");
        Assert.Equal(HttpStatusCode.Conflict, duplicate.StatusCode);
        Assert.Equal(1, upstream.Calls);
        upstream.Failure = failure;
        using var failed = await Submit("ai-failed");
        Assert.Equal(HttpStatusCode.ServiceUnavailable, failed.StatusCode);
        Assert.DoesNotContain("sensitive-upstream-error", await failed.Content.ReadAsStringAsync());
        using var quota = JsonDocument.Parse(await client.GetStringAsync("/v1/quota"));
        Assert.Equal(4, quota.RootElement.GetProperty("remaining").GetInt32());
        using var failedDuplicate = await Submit("ai-failed");
        Assert.Equal(HttpStatusCode.Conflict, failedDuplicate.StatusCode);
        Assert.Equal(2, upstream.Calls);
        Assert.Contains(fixture.Logs.Messages, line => line.Contains("ResponsesCompleteMs="));
        var logs = string.Join('\n', fixture.Logs.Messages);
        Assert.DoesNotContain(input, logs);
        Assert.DoesNotContain("Nie płać 20 zł", logs);
        Assert.DoesNotContain("test-openai-secret", logs);
        Assert.DoesNotContain("sensitive-upstream-error", logs);
        Assert.DoesNotContain(token!, logs);
        Assert.DoesNotContain("https://api.openai.com/v1/responses", logs);
    }
}
