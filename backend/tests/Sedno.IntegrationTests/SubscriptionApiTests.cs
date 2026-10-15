using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Sedno.Application;
using Sedno.Infrastructure;
using Xunit;

namespace Sedno.IntegrationTests;

[Collection("backend")]
public sealed class SubscriptionApiTests(BackendFixture fixture)
{
    private async Task<(HttpClient Client, Guid Account)> AccountAsync(string? user = null)
    {
        var client = fixture.Factory.CreateClient();
        var guest = await (await client.PostAsJsonAsync("/v1/guest-sessions", new { installationId = Guid.NewGuid().ToString() })).Content.ReadFromJsonAsync<GuestSessionDto>();
        client.DefaultRequestHeaders.Authorization = new("Bearer", guest!.AccessToken);
        var account = await (await client.PostAsJsonAsync("/v1/auth/sessions", new { idToken = user ?? "billing-" + Guid.NewGuid() })).Content.ReadFromJsonAsync<AuthenticatedSessionDto>();
        client.DefaultRequestHeaders.Authorization = new("Bearer", account!.AccessToken);
        return (client, Guid.Parse(account.Account.Id));
    }
    private Task<HttpResponseMessage> NotifyAsync(string token, string id, bool refund = false, string auth = "trusted-push")
    {
        var client = fixture.Factory.CreateClient();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", auth);
        object payload = refund
            ? new { packageName = "pl.sedno.test", voidedPurchaseNotification = new { purchaseToken = token, productType = 1, refundType = 1 } }
            : new { packageName = "pl.sedno.test", subscriptionNotification = new { purchaseToken = token, notificationType = 2 } };
        return client.PostAsJsonAsync("/notifications/google-play", new { message = new { messageId = id, data = Convert.ToBase64String(JsonSerializer.SerializeToUtf8Bytes(payload)) } });
    }
    [Theory]
    [InlineData("PENDING", false, 0)]
    [InlineData("ACTIVE", true, 1)]
    [InlineData("CANCELED", true, 1)]
    [InlineData("EXPIRED", false, 0)]
    public async Task VerifyRestoreAndDuplicateNotifications(string state, bool active, int acknowledgements)
    {
        var (client, account) = await AccountAsync();
        var token = Guid.NewGuid().ToString();
        fixture.Billing.Purchases[token] = new("SUBSCRIPTION_STATE_" + state, fixture.Clock.GetUtcNow().AddDays(1), false, SubscriptionService.Binding(account));
        var result = await client.PostAsJsonAsync("/v1/subscription", new { purchaseToken = token });
        Assert.Equal(HttpStatusCode.OK, result.StatusCode);
        Assert.Equal(active, (await result.Content.ReadFromJsonAsync<SubscriptionDto>())!.Active);
        // Restoring the same token and duplicate Pub/Sub deliveries must not acknowledge twice.
        Assert.Equal(HttpStatusCode.OK, (await client.PostAsJsonAsync("/v1/subscription", new { purchaseToken = token })).StatusCode);
        var id = Guid.NewGuid().ToString();
        Assert.Equal(HttpStatusCode.NoContent, (await NotifyAsync(token, id)).StatusCode);
        Assert.Equal(HttpStatusCode.NoContent, (await NotifyAsync(token, id)).StatusCode);
        Assert.Equal(acknowledgements, fixture.Billing.Acknowledgements.GetValueOrDefault(token));
        using var scope = fixture.Factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        Assert.Equal(1, await db.PlayNotifications.CountAsync(x => x.Id == id));
        var row = await db.Purchases.SingleAsync(x => x.TokenHash == Convert.ToHexString(System.Security.Cryptography.SHA256.HashData(System.Text.Encoding.UTF8.GetBytes(token))));
        Assert.DoesNotContain(token, row.ProtectedToken);
        var resolver = new SubscriptionService(db, fixture.Billing, scope.ServiceProvider.GetRequiredService<Microsoft.AspNetCore.DataProtection.IDataProtectionProvider>(), fixture.Clock);
        var identity = await db.Accounts.Where(x => x.Id == account).Select(x => x.PrimaryIdentityId).SingleAsync();
        // Resolver is real here; existing quota tests retain their injected entitlement mock.
        Assert.Equal(active, await resolver.HasSubscriptionAsync(identity, default));
        var quota = await new UsageStore(db, resolver, fixture.Clock).GetQuotaAsync(identity, default);
        Assert.Equal(active ? 400 : 2, quota.Limit);
    }
    [Fact]
    public async Task PendingToActiveAcknowledgesAndConcurrentDuplicateIsIdempotent()
    {
        var (client, account) = await AccountAsync();
        var token = Guid.NewGuid().ToString();
        fixture.Billing.Purchases[token] = new("SUBSCRIPTION_STATE_PENDING", null, false, SubscriptionService.Binding(account));
        Assert.Equal(HttpStatusCode.OK, (await client.PostAsJsonAsync("/v1/subscription", new { purchaseToken = token })).StatusCode);
        fixture.Billing.Purchases[token] = fixture.Billing.Purchases[token] with
            { State = "SUBSCRIPTION_STATE_ACTIVE", ExpiresAt = fixture.Clock.GetUtcNow().AddDays(1) };
        var id = Guid.NewGuid().ToString();
        var responses = await Task.WhenAll(NotifyAsync(token, id), NotifyAsync(token, id));
        Assert.All(responses, response => Assert.Equal(HttpStatusCode.NoContent, response.StatusCode));
        Assert.True((await client.GetFromJsonAsync<SubscriptionDto>("/v1/subscription"))!.Active);
        Assert.Equal(1, fixture.Billing.Acknowledgements[token]);
    }
    [Fact]
    public async Task RefundRevocationAndOutOfOrderNotificationUseCurrentGoogleState()
    {
        var (client, account) = await AccountAsync();
        var token = Guid.NewGuid().ToString();
        fixture.Billing.Purchases[token] = new("SUBSCRIPTION_STATE_ACTIVE", fixture.Clock.GetUtcNow().AddDays(1), false, SubscriptionService.Binding(account));
        await client.PostAsJsonAsync("/v1/subscription", new { purchaseToken = token });
        fixture.Billing.Purchases[token] = fixture.Billing.Purchases[token] with { State = "SUBSCRIPTION_STATE_EXPIRED" };
        Assert.Equal(HttpStatusCode.NoContent, (await NotifyAsync(token, Guid.NewGuid().ToString(), refund: true)).StatusCode);
        Assert.Equal(HttpStatusCode.NoContent, (await NotifyAsync(token, Guid.NewGuid().ToString())).StatusCode);
        Assert.False((await client.GetFromJsonAsync<SubscriptionDto>("/v1/subscription"))!.Active);
    }
    [Fact]
    public async Task RejectsPurchaseOnDifferentAccountAndUnauthenticatedNotification()
    {
        var (first, account) = await AccountAsync();
        var (second, _) = await AccountAsync("google-user-2");
        var token = Guid.NewGuid().ToString();
        fixture.Billing.Purchases[token] = new("SUBSCRIPTION_STATE_ACTIVE", fixture.Clock.GetUtcNow().AddDays(1), false, SubscriptionService.Binding(account));
        Assert.Equal(HttpStatusCode.OK, (await first.PostAsJsonAsync("/v1/subscription", new { purchaseToken = token })).StatusCode);
        Assert.False((await second.PostAsJsonAsync("/v1/subscription", new { purchaseToken = token })).IsSuccessStatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await NotifyAsync(token, Guid.NewGuid().ToString(), auth: "forged")).StatusCode);
        Assert.DoesNotContain(fixture.Logs.Messages, message => message.Contains(token));
    }
}
