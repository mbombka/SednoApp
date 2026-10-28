using System.Net.Http.Json;
using Microsoft.Extensions.DependencyInjection;
using Sedno.Application;
using Sedno.Domain;
using Sedno.Infrastructure;
using Xunit;

namespace Sedno.IntegrationTests;

[Collection("backend")]
public sealed class AppleIdentityLinkingTests(BackendFixture fixture)
{
    [Theory]
    [InlineData(false)]
    [InlineData(true)]
    public async Task LinkedProviderKeepsAccountAndUsedAllowanceOnSameInstallationAndAnotherPhone(bool appleFirst)
    {
        var uid = "linked-apple-" + Guid.NewGuid();
        var googleToken = "google-" + uid;
        var appleToken = "apple-" + uid;
        fixture.Identities.Tokens[googleToken] = new(uid, "google", true, fixture.Clock.GetUtcNow().ToUnixTimeSeconds());
        fixture.Identities.Tokens[appleToken] = new(uid, "apple", true, fixture.Clock.GetUtcNow().ToUnixTimeSeconds());
        var installation = Guid.NewGuid().ToString();
        var first = await LinkAsync(installation, appleFirst ? appleToken : googleToken);
        var db = fixture.Factory.Services.GetRequiredService<FirestoreStore>();
        var accountId = Guid.Parse(first.Account.Id);
        var identity = (await db.GetAsync<VerifiedAccount>(db.Accounts.Document(FirestoreStore.Id(accountId))))!.PrimaryIdentityId;
        var usage = new UsageStore(db, fixture.Entitlements, fixture.Clock);
        for (var i = 0; i < 5; i++)
        {
            var request = Guid.NewGuid().ToString();
            Assert.Equal("reserved", (await usage.ReserveAsync(identity, request, "fingerprint", default)).Kind);
            Assert.True(await usage.CompleteAsync(identity, request, default));
        }
        var secondToken = appleFirst ? googleToken : appleToken;
        var linked = await LinkAsync(installation, secondToken);
        Assert.Equal(first.Account.Id, linked.Account.Id);
        Assert.Equal(appleFirst ? "google" : "apple", linked.Account.Provider);
        Assert.Equal(5, linked.Quota.Used);
        Assert.Equal(0, linked.Quota.Remaining);
        var otherPhone = await LinkAsync(Guid.NewGuid().ToString(), secondToken);
        Assert.Equal(first.Account.Id, otherPhone.Account.Id);
        Assert.Equal(5, otherPhone.Quota.Used);
        Assert.Equal(0, otherPhone.Quota.Remaining);
    }
    private async Task<AuthenticatedSessionDto> LinkAsync(string installation, string identityToken)
    {
        using var client = fixture.Factory.CreateClient();
        var guestResponse = await client.PostAsJsonAsync("/v1/guest-sessions", new { installationId = installation });
        guestResponse.EnsureSuccessStatusCode();
        var guest = await guestResponse.Content.ReadFromJsonAsync<GuestSessionDto>();
        client.DefaultRequestHeaders.Authorization = new("Bearer", guest!.AccessToken);
        var linked = await client.PostAsJsonAsync("/v1/auth/sessions", new { idToken = identityToken });
        linked.EnsureSuccessStatusCode();
        return (await linked.Content.ReadFromJsonAsync<AuthenticatedSessionDto>())!;
    }
}
