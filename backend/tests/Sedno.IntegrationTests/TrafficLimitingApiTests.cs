using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.Configuration;
using Sedno.Application;
using Xunit;

namespace Sedno.IntegrationTests;

[Collection("backend")]
public sealed class TrafficLimitingApiTests(BackendFixture fixture)
{
    private WebApplicationFactory<Program> Limited() => fixture.Factory.WithWebHostBuilder(web =>
        web.ConfigureTestServices(services => services.AddTrafficLimiting(new ConfigurationBuilder()
            .AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["RateLimiting:PermitLimit"] = "3", ["RateLimiting:NotificationPermitLimit"] = "10"
            }).Build(), false)));

    private async Task<string> Token(bool account)
    {
        using var client = fixture.Factory.CreateClient();
        using var response = await client.PostAsJsonAsync("/v1/guest-sessions", new { installationId = Guid.NewGuid().ToString() });
        response.EnsureSuccessStatusCode();
        var guest = (await response.Content.ReadFromJsonAsync<GuestSessionDto>())!;
        if (!account) return guest.AccessToken;
        client.DefaultRequestHeaders.Authorization = new("Bearer", guest.AccessToken);
        using var linked = await client.PostAsJsonAsync("/v1/auth/sessions", new { idToken = "billing-rate-limit-account" });
        linked.EnsureSuccessStatusCode();
        return (await linked.Content.ReadFromJsonAsync<AuthenticatedSessionDto>())!.AccessToken;
    }

    [Fact]
    public async Task GuestsAccountsAndInvalidCredentialsHaveIndependentCounters()
    {
        var guest1 = await Token(false);
        var guest2 = await Token(false);
        var account1 = await Token(true);
        var account2 = await Token(true);
        await using var factory = Limited();
        using var client = factory.CreateClient();
        for (var i = 0; i < 3; i++)
        {
            client.DefaultRequestHeaders.Authorization = new("Bearer", "forged-" + i);
            using var denied = await client.GetAsync("/v1/quota");
            Assert.Equal(HttpStatusCode.Unauthorized, denied.StatusCode);
        }
        using (var blocked = await client.GetAsync("/v1/quota"))
            Assert.Equal(HttpStatusCode.TooManyRequests, blocked.StatusCode);
        // Even a real session ID with a forged secret must stay in the network bucket.
        client.DefaultRequestHeaders.Authorization = new("Bearer", guest1.Split('.')[0] + "." + new string('x', 43));
        using (var forged = await client.GetAsync("/v1/quota"))
            Assert.Equal(HttpStatusCode.TooManyRequests, forged.StatusCode);
        foreach (var token in new[] { guest1, guest2, account1 })
        {
            client.DefaultRequestHeaders.Authorization = new("Bearer", token);
            for (var i = 0; i < 3; i++)
            {
                using var allowed = await client.GetAsync("/v1/quota");
                Assert.Equal(HttpStatusCode.OK, allowed.StatusCode);
            }
            using var blocked = await client.GetAsync("/v1/quota");
            Assert.Equal(HttpStatusCode.TooManyRequests, blocked.StatusCode);
        }
        // Another valid session for the same account cannot reset the account bucket.
        client.DefaultRequestHeaders.Authorization = new("Bearer", account2);
        using var sameAccount = await client.GetAsync("/v1/quota");
        Assert.Equal(HttpStatusCode.TooManyRequests, sameAccount.StatusCode);
    }

    [Fact]
    public async Task PublicExhaustionDoesNotBlockVerifiedRtdnAndInvalidSignatureIsRejected()
    {
        await using var factory = Limited();
        using var client = factory.CreateClient();
        for (var i = 0; i < 4; i++)
        {
            using var response = await client.GetAsync("/v1/quota");
            Assert.Equal(i == 3 ? HttpStatusCode.TooManyRequests : HttpStatusCode.Unauthorized, response.StatusCode);
        }
        var envelope = new
        {
            message = new
            {
                messageId = Guid.NewGuid().ToString(),
                data = Convert.ToBase64String(Encoding.UTF8.GetBytes("{\"packageName\":\"pl.sedno.test\",\"testNotification\":{}}"))
            }
        };
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", "trusted-push");
        using var valid = await client.PostAsJsonAsync("/NOTIFICATIONS/google-play/", envelope);
        Assert.Equal(HttpStatusCode.NoContent, valid.StatusCode);
        client.DefaultRequestHeaders.Authorization = new("Bearer", "forged-push");
        using var invalid = await client.PostAsJsonAsync("/notifications/google-play", envelope);
        Assert.Equal(HttpStatusCode.Unauthorized, invalid.StatusCode);
    }
}
