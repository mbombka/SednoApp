using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Google.Cloud.Firestore;
using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.Hosting;
using Xunit;

namespace Sedno.IntegrationTests;

[Collection("backend")]
public sealed class FirebaseTransportApiTests(BackendFixture fixture)
{
    [Theory]
    [InlineData(true, HttpStatusCode.OK, false)]
    [InlineData(true, HttpStatusCode.OK, true)]
    [InlineData(false, HttpStatusCode.BadRequest, false)]
    [InlineData(false, HttpStatusCode.BadRequest, true)]
    public async Task ProductionAcceptsManagedTransportButRejectsSpoofedHttpsOutsideCloudRun(bool cloud, HttpStatusCode expected, bool serviceIdentity)
    {
        // Startup guards read configuration before deferred test-host callbacks.
        // The backend collection serializes changes to process configuration.
        var values = new Dictionary<string, string?>
        {
            ["K_SERVICE"] = cloud ? "sedno-api" : null,
            ["Firestore__UseEmulator"] = "false",
            ["FIRESTORE_EMULATOR_HOST"] = null,
            ["PORT"] = "8080",
            ["Model__Provider"] = "openai",
            ["OpenAI__ApiKey"] = "synthetic-test-key",
            ["PlayIntegrity__Provider"] = "google",
            ["PlayIntegrity__ServiceAccountJsonPath"] = serviceIdentity ? null : "/not-used-by-test-verifier",
            ["Firebase__ProjectId"] = "sedno-test-project",
            ["Firebase__DeletionServiceAccountJsonPath"] = serviceIdentity ? null : "/not-used-by-test-verifier",
            ["Billing__Enabled"] = "false",
            ["Google__CredentialProvider"] = serviceIdentity ? "cloud-run" : "file"
        };
        var original = values.Keys.ToDictionary(key => key, Environment.GetEnvironmentVariable);
        try
        {
            foreach (var (key, value) in values) Environment.SetEnvironmentVariable(key, value);
            await using var factory = fixture.Factory.WithWebHostBuilder(web =>
            {
                web.UseEnvironment("Production");
                web.ConfigureServices(services =>
                {
                    services.RemoveAll<FirestoreDb>();
                    services.AddSingleton(fixture.Factory.Services.GetRequiredService<FirestoreDb>());
                });
            });
            if (serviceIdentity && !cloud)
            {
                var error = Assert.Throws<InvalidOperationException>(() => factory.CreateClient());
                Assert.Contains("Google:CredentialProvider", error.Message);
                return;
            }
            using var client = factory.CreateClient();
            client.DefaultRequestHeaders.Add("X-Forwarded-Proto", cloud ? "http" : "https");
            using var health = await client.GetAsync("/health/live");
            Assert.Equal(expected, health.StatusCode);
            Assert.True(health.Headers.CacheControl?.NoStore);
            using var quota = await client.GetAsync("/v1/quota");
            Assert.Equal(cloud ? HttpStatusCode.Unauthorized : HttpStatusCode.BadRequest, quota.StatusCode);
            Assert.True(quota.Headers.CacheControl?.NoStore);
            using var guest = await client.PostAsJsonAsync("/v1/guest-sessions", new { installationId = Guid.NewGuid().ToString() });
            Assert.Equal(expected, guest.StatusCode);
            Assert.True(guest.Headers.CacheControl?.NoStore);
        }
        finally
        {
            foreach (var (key, value) in original) Environment.SetEnvironmentVariable(key, value);
        }
    }
}
