using System.Net.Http.Json;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.Extensions.DependencyInjection;
using Sedno.Application;
using Sedno.Domain;
using Sedno.Infrastructure;
using Xunit;

namespace Sedno.IntegrationTests;

[Collection("backend")]
public sealed class AppleSubscriptionTests(BackendFixture fixture)
{
    private readonly AppleBillingOptions _options = new() { Enabled = true };
    private async Task<(Guid Account, Guid Identity, FirestoreStore Db)> AccountAsync()
    {
        var client = fixture.Factory.CreateClient();
        var guest = await (await client.PostAsJsonAsync("/v1/guest-sessions", new { installationId = Guid.NewGuid().ToString() })).Content.ReadFromJsonAsync<GuestSessionDto>();
        client.DefaultRequestHeaders.Authorization = new("Bearer", guest!.AccessToken);
        var account = await (await client.PostAsJsonAsync("/v1/auth/sessions", new { idToken = "billing-apple-" + Guid.NewGuid() })).Content.ReadFromJsonAsync<AuthenticatedSessionDto>();
        var db = fixture.Factory.Services.GetRequiredService<FirestoreStore>();
        var accountId = Guid.Parse(account!.Account.Id);
        var identity = (await db.GetAsync<VerifiedAccount>(db.Accounts.Document(FirestoreStore.Id(accountId))))!.PrimaryIdentityId;
        return (accountId, identity, db);
    }
    private AppleSubscriptionService Service(FirestoreStore db, Billing billing) => new(db, billing, _options, fixture.Clock);
    private Billing Client(Guid account) => new(new("100" + Guid.NewGuid().ToString("N"), "200", AppleSubscriptionService.Binding(account), "active",
        fixture.Clock.GetUtcNow().AddDays(30), fixture.Clock.GetUtcNow(), false));
    private sealed class Billing(AppleSubscription status) : IAppleBillingClient
    {
        public AppleSubscription Status = status;
        public int Calls;
        public bool Fail;
        public Task<AppleSubscription> GetAsync(string transactionId, CancellationToken ct)
        {
            Calls++;
            if (Fail) throw new HttpRequestException("Unavailable");
            return Task.FromResult(Status);
        }
        public AppleNotification VerifyNotification(string signedPayload) => new(signedPayload, Status.OriginalTransactionId, Status.SignedAt);
    }
    [Fact]
    public async Task OwnershipIsBoundToAccountAndOriginalTransactionAndVerificationIsIdempotent()
    {
        var (account, identity, db) = await AccountAsync();
        var other = await AccountAsync();
        var billing = Client(account);
        var service = Service(db, billing);
        Assert.True((await service.VerifyAsync(account, "200", default)).Active);
        Assert.True((await service.VerifyAsync(account, "200", default)).Active);
        Assert.Single(await db.ListAsync<ApplePurchase>(db.Database.Collection("apple_purchases").WhereEqualTo("AccountId", account.ToString())));
        await Assert.ThrowsAsync<InvalidOperationException>(() => service.VerifyAsync(other.Account, "200", default));
        billing.Status = billing.Status with { AccountToken = AppleSubscriptionService.Binding(other.Account) };
        await Assert.ThrowsAsync<InvalidOperationException>(() => service.VerifyAsync(other.Account, "200", default));
        billing.Fail = true;
        Assert.True(await service.HasSubscriptionAsync(identity, default)); // fresh cache makes no HTTP call
    }
    [Fact]
    public async Task ExpiredVerificationFailsClosedAndKeepsExistingUsage()
    {
        var (account, identity, db) = await AccountAsync();
        var billing = Client(account);
        var service = Service(db, billing);
        await service.VerifyAsync(account, "200", default);
        var usage = new UsageStore(db, service, fixture.Clock);
        for (var i = 0; i < 6; i++)
        {
            var request = Guid.NewGuid().ToString();
            Assert.Equal("reserved", (await usage.ReserveAsync(identity, request, "fingerprint", default)).Kind);
            Assert.True(await usage.CompleteAsync(identity, request, default));
        }
        var now = fixture.Clock.GetUtcNow();
        try
        {
            fixture.Clock.Set(now.AddMinutes(15));
            billing.Fail = true;
            usage = new UsageStore(db, service, fixture.Clock);
            var quota = await usage.GetQuotaAsync(identity, default);
            Assert.Equal(5, quota.Limit);
            Assert.Equal(6, quota.Used);
            Assert.Equal(0, quota.Remaining);
            Assert.Equal(2, billing.Calls);
            await usage.GetQuotaAsync(identity, default);
            Assert.Equal(2, billing.Calls); // shared cooldown without extending verification
        }
        finally { fixture.Clock.Set(now); }
    }
    [Fact]
    public async Task DuplicateAndDelayedNotificationsUseCurrentStoreState()
    {
        var (account, identity, db) = await AccountAsync();
        var billing = Client(account);
        var service = Service(db, billing);
        await service.VerifyAsync(account, "200", default);
        billing.Status = billing.Status with { State = "revoked", Revoked = true };
        var notice = Guid.NewGuid().ToString();
        await service.NotifyAsync(notice, default);
        await service.NotifyAsync(notice, default);
        Assert.Equal(2, billing.Calls);
        Assert.False(await service.HasSubscriptionAsync(identity, default));
        // An old event must not restore its historical state. The service fetches
        // current status under the same account lease as client verification.
        await service.NotifyAsync(Guid.NewGuid().ToString(), default);
        Assert.False(await service.HasSubscriptionAsync(identity, default));
    }
    [Fact]
    public async Task TwoStoresGrantOneFourHundredLimitAndOneUsageCounter()
    {
        var (account, identity, db) = await AccountAsync();
        var apple = Service(db, Client(account));
        await apple.VerifyAsync(account, "200", default);
        var play = new SubscriptionService(db, fixture.Billing, fixture.Factory.Services.GetRequiredService<IDataProtectionProvider>(), fixture.Clock);
        var token = Guid.NewGuid().ToString();
        fixture.Billing.Purchases[token] = new("SUBSCRIPTION_STATE_ACTIVE", fixture.Clock.GetUtcNow().AddDays(30), true, SubscriptionService.Binding(account));
        await play.VerifyAsync(account, token, default);
        var resolver = new StoreEntitlementResolver(play, apple, _options, true);
        var usage = new UsageStore(db, resolver, fixture.Clock);
        Assert.Equal(400, (await usage.GetQuotaAsync(identity, default)).Limit);
        var request = Guid.NewGuid().ToString();
        Assert.Equal("reserved", (await usage.ReserveAsync(identity, request, "fingerprint", default)).Kind);
        Assert.True(await usage.CompleteAsync(identity, request, default));
        Assert.Equal(1, (await new UsageStore(db, apple, fixture.Clock).GetQuotaAsync(identity, default)).Used);
        Assert.Equal(1, (await new UsageStore(db, play, fixture.Clock).GetQuotaAsync(identity, default)).Used);
    }
}
