using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using Sedno.Application;
using Sedno.Infrastructure;
using Xunit;

namespace Sedno.IntegrationTests;

[Collection("backend")]
public sealed class SessionRevocationTests(BackendFixture fixture)
{
    private async Task<(HttpClient Client, string Bearer)> LoginAsync(string token)
    {
        var client = fixture.Factory.CreateClient();
        var guest = await (await client.PostAsJsonAsync("/v1/guest-sessions", new { installationId = Guid.NewGuid().ToString() }))
            .Content.ReadFromJsonAsync<GuestSessionDto>();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", guest!.AccessToken);
        var linked = await client.PostAsJsonAsync("/v1/auth/sessions", new { idToken = token });
        linked.EnsureSuccessStatusCode();
        var account = await linked.Content.ReadFromJsonAsync<AuthenticatedSessionDto>();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", account!.AccessToken);
        return (client, account.AccessToken);
    }

    [Theory]
    [InlineData("password-reset")]
    [InlineData("revoked")]
    [InlineData("disabled")]
    [InlineData("deleted")]
    public async Task RevocationRejectsOldSessionAndOldFirebaseAuthentication(string reason)
    {
        fixture.Clock.Set(new(2026, 10, 20, 12, 0, 0, TimeSpan.Zero));
        var uid = "revocation-" + Guid.NewGuid();
        var time = fixture.Clock.GetUtcNow().ToUnixTimeSeconds();
        fixture.Identities.Tokens[uid] = new(uid, "email", true, time);
        var (client, bearer) = await LoginAsync(uid);
        Assert.Equal(HttpStatusCode.OK, (await client.GetAsync("/v1/quota")).StatusCode);
        fixture.Clock.Advance(TimeSpan.FromSeconds(1));
        if (reason == "deleted") fixture.IdentityAccounts.Deleted[uid] = true;
        else fixture.IdentityAccounts.Statuses[uid] = new(reason != "disabled", time + 1);
        // Login must bypass even a warm successful cache; the old auth_time stays revoked.
        using var guest = fixture.Factory.CreateClient();
        var created = await (await guest.PostAsJsonAsync("/v1/guest-sessions", new { installationId = Guid.NewGuid().ToString() }))
            .Content.ReadFromJsonAsync<GuestSessionDto>();
        guest.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", created!.AccessToken);
        Assert.Equal(HttpStatusCode.Conflict, (await guest.PostAsJsonAsync("/v1/auth/sessions", new { idToken = uid })).StatusCode);
        fixture.Clock.Advance(TimeSpan.FromSeconds(298));
        Assert.Equal(HttpStatusCode.OK, (await client.GetAsync("/v1/quota")).StatusCode);
        fixture.Clock.Advance(TimeSpan.FromSeconds(1));
        Assert.Equal(HttpStatusCode.Unauthorized, (await client.GetAsync("/v1/quota")).StatusCode);
        if (reason is "password-reset" or "revoked")
        {
            fixture.Identities.Tokens[uid] = new(uid, "email", true, fixture.Clock.GetUtcNow().ToUnixTimeSeconds());
            var renewed = await guest.PostAsJsonAsync("/v1/auth/sessions", new { idToken = uid });
            renewed.EnsureSuccessStatusCode();
            client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", bearer);
            Assert.Equal(HttpStatusCode.Unauthorized, (await client.GetAsync("/v1/quota")).StatusCode);
        }
    }

    [Fact]
    public async Task FirebaseFailureAfterCacheExpirationNeverExtendsAccess()
    {
        fixture.Clock.Set(new(2026, 10, 20, 12, 0, 0, TimeSpan.Zero));
        var uid = "outage-" + Guid.NewGuid();
        fixture.Identities.Tokens[uid] = new(uid, "google", AuthTime: fixture.Clock.GetUtcNow().ToUnixTimeSeconds());
        var (client, _) = await LoginAsync(uid);
        Assert.Equal(1, fixture.IdentityAccounts.Lookups[uid]); // Uncached login.
        Assert.Equal(HttpStatusCode.OK, (await client.GetAsync("/v1/quota")).StatusCode);
        Assert.Equal(2, fixture.IdentityAccounts.Lookups[uid]);
        fixture.IdentityAccounts.LookupFailures[uid] = true;
        fixture.Clock.Advance(TimeSpan.FromMinutes(4));
        Assert.Equal(HttpStatusCode.OK, (await client.GetAsync("/v1/quota")).StatusCode);
        Assert.Equal(2, fixture.IdentityAccounts.Lookups[uid]);
        fixture.Clock.Advance(TimeSpan.FromMinutes(1));
        Assert.Equal(HttpStatusCode.InternalServerError, (await client.GetAsync("/v1/quota")).StatusCode);
        Assert.Equal(HttpStatusCode.InternalServerError, (await client.GetAsync("/v1/quota")).StatusCode);
        Assert.Equal(4, fixture.IdentityAccounts.Lookups[uid]);
        fixture.IdentityAccounts.LookupFailures.TryRemove(uid, out _);
    }

    [Fact]
    public async Task DeleteRequiresFreshSameUserAuthenticationAndUncachedAccountStatus()
    {
        fixture.Clock.Set(new(2026, 10, 20, 12, 0, 0, TimeSpan.Zero));
        var uid = "deletion-" + Guid.NewGuid();
        var time = fixture.Clock.GetUtcNow().ToUnixTimeSeconds();
        fixture.Identities.Tokens[uid] = new(uid, "google", AuthTime: time);
        var (client, _) = await LoginAsync(uid);
        Assert.Equal(HttpStatusCode.OK, (await client.GetAsync("/v1/quota")).StatusCode);
        async Task<HttpStatusCode> Delete(string? token)
        {
            using var response = await client.SendAsync(new HttpRequestMessage(HttpMethod.Delete, "/v1/account")
                { Content = JsonContent.Create(new { idToken = token }) });
            return response.StatusCode;
        }
        Assert.Equal(HttpStatusCode.Forbidden, await Delete(null));
        Assert.Equal(HttpStatusCode.Forbidden, (await client.DeleteAsync("/v1/account")).StatusCode);
        fixture.Clock.Advance(TimeSpan.FromSeconds(301));
        // A refreshed ID token still carries the original auth_time.
        Assert.Equal(HttpStatusCode.Forbidden, await Delete(uid));
        fixture.Identities.Tokens["other-fresh"] = new("another-user", "google", AuthTime: fixture.Clock.GetUtcNow().ToUnixTimeSeconds());
        Assert.Equal(HttpStatusCode.Forbidden, await Delete("other-fresh"));
        fixture.Identities.Tokens[uid] = new(uid, "google", AuthTime: fixture.Clock.GetUtcNow().ToUnixTimeSeconds());
        fixture.IdentityAccounts.Statuses[uid] = new(false, 0);
        Assert.Equal(HttpStatusCode.Forbidden, await Delete(uid)); // Warm cache cannot authorize deletion.
        fixture.IdentityAccounts.Statuses[uid] = new(true, time + 1);
        Assert.Equal(HttpStatusCode.Forbidden, await Delete(uid)); // Sedno bearer itself is revoked.
        fixture.IdentityAccounts.Statuses[uid] = new(true, 0);
        Assert.Equal(HttpStatusCode.NoContent, await Delete(uid));
        Assert.Equal(HttpStatusCode.Unauthorized, (await client.GetAsync("/v1/quota")).StatusCode);
    }
}
