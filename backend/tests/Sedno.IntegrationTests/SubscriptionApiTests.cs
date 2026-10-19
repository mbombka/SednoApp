using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
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
    private sealed class NoNetworkBilling : IPlayBillingClient
    {
        public Task<PlaySubscription> GetAsync(string token, CancellationToken ct) => throw new InvalidOperationException("Quota must not call Google.");
        public Task AcknowledgeAsync(string token, CancellationToken ct) => throw new InvalidOperationException("Quota must not acknowledge.");
    }

    [Fact]
    public async Task QuotaUsesVerifiedSnapshotAndBackgroundRefreshUpdatesIt()
    {
        var now = new DateTimeOffset(2026, 10, 16, 12, 0, 0, TimeSpan.Zero);
        fixture.Clock.Set(now);
        var (client, account) = await AccountAsync();
        var token = Guid.NewGuid().ToString();
        fixture.Billing.Purchases[token] = new("SUBSCRIPTION_STATE_ACTIVE", now.AddDays(1), true, SubscriptionService.Binding(account));
        (await client.PostAsJsonAsync("/v1/subscription", new { purchaseToken = token })).EnsureSuccessStatusCode();
        using var scope = fixture.Factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<FirestoreStore>();
        var identity = (await db.GetAsync<Sedno.Domain.VerifiedAccount>(db.Accounts.Document(FirestoreStore.Id(account))))!.PrimaryIdentityId;
        var resolver = new SubscriptionService(db, new NoNetworkBilling(),
            scope.ServiceProvider.GetRequiredService<Microsoft.AspNetCore.DataProtection.IDataProtectionProvider>(), fixture.Clock);
        Assert.True(await resolver.HasSubscriptionAsync(identity, default));
        fixture.Clock.Set(now + SubscriptionService.VerificationLifetime);
        Assert.False(await resolver.HasSubscriptionAsync(identity, default));
        // The app's background GET refreshes the persisted verification.
        Assert.True((await client.GetFromJsonAsync<SubscriptionDto>("/v1/subscription"))!.Active);
        Assert.True(await resolver.HasSubscriptionAsync(identity, default));
        fixture.Billing.Purchases[token] = fixture.Billing.Purchases[token] with { State = "SUBSCRIPTION_STATE_EXPIRED" };
        Assert.Equal(HttpStatusCode.NoContent, (await NotifyAsync(token, Guid.NewGuid().ToString())).StatusCode);
        Assert.False(await resolver.HasSubscriptionAsync(identity, default));
        fixture.Clock.Set(now);
    }

    [Fact]
    public async Task CachedVerificationNeverExtendsPurchaseExpiry()
    {
        var now = new DateTimeOffset(2026, 10, 16, 12, 0, 0, TimeSpan.Zero);
        fixture.Clock.Set(now);
        var (client, account) = await AccountAsync();
        var token = Guid.NewGuid().ToString();
        fixture.Billing.Purchases[token] = new("SUBSCRIPTION_STATE_CANCELED", now.AddMinutes(1), true, SubscriptionService.Binding(account));
        (await client.PostAsJsonAsync("/v1/subscription", new { purchaseToken = token })).EnsureSuccessStatusCode();
        using var scope = fixture.Factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<FirestoreStore>();
        var identity = (await db.GetAsync<Sedno.Domain.VerifiedAccount>(db.Accounts.Document(FirestoreStore.Id(account))))!.PrimaryIdentityId;
        var resolver = new SubscriptionService(db, new NoNetworkBilling(),
            scope.ServiceProvider.GetRequiredService<Microsoft.AspNetCore.DataProtection.IDataProtectionProvider>(), fixture.Clock);
        Assert.True(await resolver.HasSubscriptionAsync(identity, default));
        fixture.Clock.Set(now.AddMinutes(1));
        Assert.False(await resolver.HasSubscriptionAsync(identity, default));
        fixture.Clock.Set(now);
    }

    private sealed class GatedBilling(TestBilling inner, string blockedToken) : IPlayBillingClient
    {
        public TaskCompletionSource Entered { get; } = new(TaskCreationOptions.RunContinuationsAsynchronously);
        public TaskCompletionSource Release { get; } = new(TaskCreationOptions.RunContinuationsAsynchronously);
        public async Task<PlaySubscription> GetAsync(string token, CancellationToken ct)
        {
            if (token == blockedToken)
            {
                Entered.TrySetResult();
                await Release.Task.WaitAsync(ct);
            }
            return await inner.GetAsync(token, ct);
        }
        public Task AcknowledgeAsync(string token, CancellationToken ct) => inner.AcknowledgeAsync(token, ct);
    }

    [Fact]
    public async Task SlowGoogleVerificationDoesNotBlockAnotherAccount()
    {
        var (_, first) = await AccountAsync();
        var (_, other) = await AccountAsync();
        var firstToken = Guid.NewGuid().ToString();
        var otherToken = Guid.NewGuid().ToString();
        fixture.Billing.Purchases[firstToken] = new("SUBSCRIPTION_STATE_ACTIVE", fixture.Clock.GetUtcNow().AddDays(1), true, SubscriptionService.Binding(first));
        fixture.Billing.Purchases[otherToken] = new("SUBSCRIPTION_STATE_ACTIVE", fixture.Clock.GetUtcNow().AddDays(1), true, SubscriptionService.Binding(other));
        var gate = new GatedBilling(fixture.Billing, firstToken);
        using var firstScope = fixture.Factory.Services.CreateScope();
        using var otherScope = fixture.Factory.Services.CreateScope();
        SubscriptionService Service(IServiceScope scope) => new(scope.ServiceProvider.GetRequiredService<FirestoreStore>(), gate,
            scope.ServiceProvider.GetRequiredService<Microsoft.AspNetCore.DataProtection.IDataProtectionProvider>(), fixture.Clock);
        using var timeout = new CancellationTokenSource(TimeSpan.FromSeconds(10));
        var pending = Service(firstScope).VerifyAsync(first, firstToken, timeout.Token);
        try
        {
            await gate.Entered.Task.WaitAsync(timeout.Token);
            Assert.True((await Service(otherScope).VerifyAsync(other, otherToken, timeout.Token)).Active);
            Assert.False(pending.IsCompleted);
        }
        finally
        {
            gate.Release.TrySetResult();
            await pending;
        }
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
        var db = scope.ServiceProvider.GetRequiredService<FirestoreStore>();
        Assert.True((await db.PlayNotifications.Document(FirestoreStore.Hash(id)).GetSnapshotAsync()).Exists);
        var row = (await db.GetAsync<Sedno.Domain.PlayPurchase>(db.Purchases.Document(FirestoreStore.Hash(token))))!;
        Assert.DoesNotContain(token, row.ProtectedToken);
        var resolver = new SubscriptionService(db, fixture.Billing, scope.ServiceProvider.GetRequiredService<Microsoft.AspNetCore.DataProtection.IDataProtectionProvider>(), fixture.Clock);
        var identity = (await db.GetAsync<Sedno.Domain.VerifiedAccount>(db.Accounts.Document(FirestoreStore.Id(account))))!.PrimaryIdentityId;
        // Resolver is real here; existing quota tests retain their injected entitlement mock.
        Assert.Equal(active, await resolver.HasSubscriptionAsync(identity, default));
        var quota = await new UsageStore(db, resolver, fixture.Clock).GetQuotaAsync(identity, default);
        Assert.Equal(active ? 400 : 5, quota.Limit);
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
