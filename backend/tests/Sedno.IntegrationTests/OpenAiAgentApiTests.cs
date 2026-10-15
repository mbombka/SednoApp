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
public sealed class OpenAiAgentApiTests(BackendFixture fixture)
{
    private sealed class Upstream : HttpMessageHandler
    {
        public int Submissions;
        public int Deletions;
        public string? Failure;
        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken ct)
        {
            var path = request.RequestUri!.AbsolutePath;
            if (request.Method == HttpMethod.Delete)
            {
                Deletions++;
                return Task.FromResult(Json(new { deleted = true }));
            }
            if (request.Method == HttpMethod.Post && path.EndsWith("/sessions"))
            {
                Submissions++;
                if (Failure == "timeout") throw new TaskCanceledException("sensitive-agent-error");
                if (Failure == "http") return Task.FromResult(Json(new { error = "sensitive-agent-error" }, HttpStatusCode.TooManyRequests));
                return Task.FromResult(Json(new { id = "sess_test" }, HttpStatusCode.Created));
            }
            if (path.EndsWith("/turns")) return Task.FromResult(Json(new
            {
                has_more = false, data = new[] { new { id = "turn_test", status = Failure == "failed" ? "failed" : "completed" } }
            }));
            if (path.EndsWith("/items")) return Task.FromResult(Json(new
            {
                has_more = false, data = new[] { new { type = "message", role = "assistant", phase = "final_answer",
                    status = "completed", turn_id = "turn_test", content = new[]
                    { new { type = "output_text", text = "Dostarcz dokumenty do 20 listopada." } } } }
            }));
            return Task.FromResult(Json(new { id = "sess_test" }, HttpStatusCode.Created));
        }
        private static HttpResponseMessage Json(object value, HttpStatusCode status = HttpStatusCode.OK) =>
            new(status) { Content = new StringContent(JsonSerializer.Serialize(value)) };
    }

    [Theory]
    [InlineData("http")]
    [InlineData("timeout")]
    [InlineData("failed")]
    public async Task AgentAdapterPreservesQuotaIdempotencyAndContentPrivacy(string failure)
    {
        fixture.Clock.Set(new(2026, 10, 14, 12, 0, 0, TimeSpan.Zero));
        var upstream = new Upstream();
        await using var factory = fixture.Factory.WithWebHostBuilder(web => web.ConfigureTestServices(services =>
        {
            services.RemoveAll<IModelProvider>();
            var configuration = new ConfigurationBuilder().AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["Model:Provider"] = "openai-agent", ["OpenAI:ApiKey"] = "test-agent-secret", ["OpenAI:AgentId"] = "agent_test"
            }).Build();
            services.AddSednoModel(configuration, isDevelopment: false);
            services.AddHttpClient("openai-agent").ConfigurePrimaryHttpMessageHandler(() => upstream);
        }));
        using var client = factory.CreateClient();
        using var guest = await client.PostAsJsonAsync("/v1/guest-sessions", new { installationId = Guid.NewGuid().ToString() });
        guest.EnsureSuccessStatusCode();
        using var session = JsonDocument.Parse(await guest.Content.ReadAsStringAsync());
        var token = session.RootElement.GetProperty("accessToken").GetString();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);
        const string text = "Dokumenty należy dostarczyć do 20 listopada. PoufnyTekstAgenta987";
        Task<HttpResponseMessage> Submit(string id) => client.PostAsJsonAsync("/v1/simplifications", new { requestId = id, text });

        using var success = await Submit("agent-success");
        Assert.Equal(HttpStatusCode.OK, success.StatusCode);
        using var result = JsonDocument.Parse(await success.Content.ReadAsStringAsync());
        Assert.Equal("Dostarcz dokumenty do 20 listopada.", result.RootElement.GetProperty("result").GetProperty("text").GetString());
        Assert.Equal(1, result.RootElement.GetProperty("quota").GetProperty("remaining").GetInt32());
        using var duplicate = await Submit("agent-success");
        Assert.Equal(HttpStatusCode.Conflict, duplicate.StatusCode);
        Assert.Equal(1, upstream.Submissions);
        upstream.Failure = failure;
        using var failed = await Submit("agent-failed");
        Assert.Equal(HttpStatusCode.ServiceUnavailable, failed.StatusCode);
        Assert.DoesNotContain("sensitive-agent-error", await failed.Content.ReadAsStringAsync());
        using var quota = JsonDocument.Parse(await client.GetStringAsync("/v1/quota"));
        Assert.Equal(1, quota.RootElement.GetProperty("remaining").GetInt32());
        using var retry = await Submit("agent-failed");
        Assert.Equal(HttpStatusCode.Conflict, retry.StatusCode);
        Assert.Equal(2, upstream.Submissions);
        Assert.Equal(failure == "failed" ? 2 : 1, upstream.Deletions);
        var logs = string.Join('\n', fixture.Logs.Messages);
        foreach (var sensitive in new[] { text, "Dostarcz dokumenty do 20 listopada.", "test-agent-secret",
            "sensitive-agent-error", token!, "https://api.openai.com/v1/agents" })
            Assert.DoesNotContain(sensitive, logs);
    }
}
