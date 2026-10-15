using System.Net;
using System.Text;
using Sedno.Application;
using Sedno.Infrastructure;
using Xunit;

namespace Sedno.UnitTests;

public sealed class SubscriptionTests
{
    private static readonly DateTimeOffset Now = DateTimeOffset.Parse("2026-10-15T12:00:00Z");
    [Theory]
    [InlineData("PENDING", false)]
    [InlineData("ACTIVE", true)]
    [InlineData("CANCELED", true)]
    [InlineData("EXPIRED", false)]
    [InlineData("IN_GRACE_PERIOD", true)]
    [InlineData("ON_HOLD", false)]
    [InlineData("PAUSED", false)]
    [InlineData("PENDING_PURCHASE_CANCELED", false)]
    public void OnlyPaidStatesGrantAccess(string state, bool active)
    {
        var purchase = new PlaySubscription("SUBSCRIPTION_STATE_" + state, Now.AddMinutes(1), false, "account");
        Assert.Equal(active, purchase.Entitled(Now));
        Assert.False(purchase.Entitled(Now.AddMinutes(1)));
    }
    [Fact]
    public void ExpirationAndRefundRevocationRemoveAccess()
    {
        Assert.False(new PlaySubscription("SUBSCRIPTION_STATE_ACTIVE", Now, true, "a").Entitled(Now));
        Assert.False(new PlaySubscription("SUBSCRIPTION_STATE_EXPIRED", Now.AddDays(1), true, "a").Entitled(Now));
        Assert.False(new PlaySubscription("SUBSCRIPTION_STATE_PENDING", null, false, "a").Entitled(Now));
    }
    [Fact]
    public async Task GoogleAdapterChecksProductAndAcknowledges()
    {
        var handler = new Handler();
        var client = new PlayBillingClient(new HttpClient(handler), new Tokens(), new("pl.sedno", "monthly"));
        var status = await client.GetAsync("secret", default);
        Assert.Equal("account-binding", status.AccountBinding);
        Assert.True(status.Entitled(Now));
        Assert.False(status.Acknowledged);
        await client.AcknowledgeAsync("secret", default);
        Assert.Equal(1, handler.Acknowledgements);
        handler.Status = HttpStatusCode.Gone;
        Assert.False((await client.GetAsync("secret", default)).Entitled(Now));
        handler.Status = HttpStatusCode.OK;
        handler.Product = "wrong-product";
        await Assert.ThrowsAsync<InvalidOperationException>(() => client.GetAsync("secret", default));
    }
    private sealed class Tokens : IPlayAccessTokenSource
    {
        public Task<string> GetAsync(CancellationToken ct) => Task.FromResult("oauth");
    }
    private sealed class Handler : HttpMessageHandler
    {
        public HttpStatusCode Status = HttpStatusCode.OK;
        public string Product = "monthly";
        public int Acknowledgements;
        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken ct)
        {
            Assert.Equal("oauth", request.Headers.Authorization?.Parameter);
            if (request.Method == HttpMethod.Post)
            {
                Assert.EndsWith("/subscriptions/monthly/tokens/secret:acknowledge", request.RequestUri!.AbsolutePath);
                Acknowledgements++;
                return Task.FromResult(new HttpResponseMessage(HttpStatusCode.NoContent));
            }
            Assert.EndsWith("/subscriptionsv2/tokens/secret", request.RequestUri!.AbsolutePath);
            return Task.FromResult(new HttpResponseMessage(Status) { Content = new StringContent(
                $$"""{"subscriptionState":"SUBSCRIPTION_STATE_ACTIVE","acknowledgementState":"ACKNOWLEDGEMENT_STATE_PENDING","externalAccountIdentifiers":{"obfuscatedExternalAccountId":"account-binding"},"lineItems":[{"productId":"{{Product}}","expiryTime":"2026-11-15T12:00:00Z"}]}""", Encoding.UTF8, "application/json") });
        }
    }
}
