using System.Net.Http.Json;
using Google.Cloud.Firestore;
using Microsoft.Extensions.DependencyInjection;
using Sedno.Application;
using Sedno.Domain;
using Sedno.Infrastructure;
using Xunit;

namespace Sedno.IntegrationTests;

[Collection("backend")]
public sealed class TesterAccessTests(BackendFixture fixture)
{
    private FirestoreStore Db => fixture.Factory.Services.GetRequiredService<FirestoreStore>();

    private async Task<(HttpClient Client, VerifiedAccount Account)> AccountAsync(string? user = null)
    {
        var client = fixture.Factory.CreateClient();
        var guest = await (await client.PostAsJsonAsync("/v1/guest-sessions", new { installationId = Guid.NewGuid().ToString() }))
            .Content.ReadFromJsonAsync<GuestSessionDto>();
        client.DefaultRequestHeaders.Authorization = new("Bearer", guest!.AccessToken);
        var session = await (await client.PostAsJsonAsync("/v1/auth/sessions", new { idToken = user ?? "billing-" + Guid.NewGuid() }))
            .Content.ReadFromJsonAsync<AuthenticatedSessionDto>();
        client.DefaultRequestHeaders.Authorization = new("Bearer", session!.AccessToken);
        return (client, (await Db.GetAsync<VerifiedAccount>(Db.Accounts.Document(FirestoreStore.Id(Guid.Parse(session.Account.Id)))))!);
    }

    private Task GrantAsync(VerifiedAccount account, DateTimeOffset? expiry) =>
        Db.Accounts.Document(FirestoreStore.Id(account.Id)).UpdateAsync(
            new Dictionary<string, object> { ["TesterAccessExpiresAt"] = expiry is null ? FieldValue.Delete : Timestamp.FromDateTimeOffset(expiry.Value) });

    private async Task SeedUsageAsync(VerifiedAccount account, int used)
    {
        var identity = (await Db.GetAsync<GuestIdentity>(Db.Identities.Document(FirestoreStore.Id(account.PrimaryIdentityId))))!;
        var day = QuotaPolicy.Day(fixture.Clock.GetUtcNow());
        await Db.PutAsync(Db.Day(identity.InstallationHash, day), new DailyUsage
        {
            InstallationHash = identity.InstallationHash, Day = day.ToString("yyyy-MM-dd"),
            ExpiresAt = fixture.Clock.GetUtcNow().AddDays(8),
            Used = new() { [FirestoreStore.Id(identity.Id)] = used }
        });
    }

    [Fact]
    public async Task GrantExtensionExpiryAndRemovalPreserveUsageAndSerializeStatus()
    {
        var (client, account) = await AccountAsync();
        var now = fixture.Clock.GetUtcNow();
        var expiry = now.AddMinutes(1);
        try
        {
            Assert.Equal("free", (await client.GetFromJsonAsync<QuotaDto>("/v1/quota"))!.Tier);
            await SeedUsageAsync(account, 5);
            await GrantAsync(account, expiry);
            var quota = (await client.GetFromJsonAsync<QuotaDto>("/v1/quota"))!;
            Assert.Equal("tester", quota.Tier);
            Assert.Equal(400, quota.Limit);
            Assert.Equal(5, quota.Used);
            Assert.Equal(395, quota.Remaining);
            Assert.Equal(expiry, quota.TesterAccessExpiresAt);
            // The flag really is a Firestore timestamp, including writes via the SDK mapper.
            var mapped = FirestoreStore.Encode((await Db.GetAsync<VerifiedAccount>(Db.Accounts.Document(FirestoreStore.Id(account.Id))))!);
            Assert.IsType<Timestamp>(mapped["TesterAccessExpiresAt"]);
            await GrantAsync(account, expiry.AddMinutes(1));
            await SeedUsageAsync(account, 30);
            fixture.Clock.Set(expiry.AddMinutes(1).AddTicks(-10)); // Firestore timestamp microsecond precision
            Assert.Equal("tester", (await client.GetFromJsonAsync<QuotaDto>("/v1/quota"))!.Tier);
            fixture.Clock.Set(expiry.AddMinutes(1));
            quota = (await client.GetFromJsonAsync<QuotaDto>("/v1/quota"))!;
            Assert.Equal("free", quota.Tier);
            Assert.Equal(5, quota.Limit);
            Assert.Equal(30, quota.Used);
            Assert.Equal(0, quota.Remaining);
            Assert.Equal("quota_exceeded", (await new UsageStore(Db, fixture.Entitlements, fixture.Clock)
                .ReserveAsync(account.PrimaryIdentityId, Guid.NewGuid().ToString(), "fp", default)).Kind);
            await GrantAsync(account, null);
            Assert.Null((await client.GetFromJsonAsync<QuotaDto>("/v1/quota"))!.TesterAccessExpiresAt);
            Assert.False((await client.GetFromJsonAsync<SubscriptionDto>("/v1/subscription"))!.Active);
            fixture.Clock.Set(QuotaPolicy.ResetAt(now));
            quota = (await client.GetFromJsonAsync<QuotaDto>("/v1/quota"))!;
            Assert.Equal(0, quota.Used);
            Assert.Equal(5, quota.Remaining);
        }
        finally { fixture.Clock.Set(now); }
    }

    [Fact]
    public async Task ExistingSubscriptionSurvivesTesterExpiryAndRemovalWithoutStackingLimits()
    {
        var (client, account) = await AccountAsync();
        var token = Guid.NewGuid().ToString();
        fixture.Billing.Purchases[token] = new("SUBSCRIPTION_STATE_ACTIVE", fixture.Clock.GetUtcNow().AddDays(1), true, SubscriptionService.Binding(account.Id));
        (await client.PostAsJsonAsync("/v1/subscription", new { purchaseToken = token })).EnsureSuccessStatusCode();
        using var scope = fixture.Factory.Services.CreateScope();
        var resolver = scope.ServiceProvider.GetRequiredService<SubscriptionService>();
        await GrantAsync(account, fixture.Clock.GetUtcNow().AddDays(1));
        Assert.Equal("subscription", (await new UsageStore(Db, resolver, fixture.Clock).GetQuotaAsync(account.PrimaryIdentityId, default)).Tier);
        await GrantAsync(account, fixture.Clock.GetUtcNow());
        await SeedUsageAsync(account, 30);
        await GrantAsync(account, null);
        var quota = await new UsageStore(Db, resolver, fixture.Clock).GetQuotaAsync(account.PrimaryIdentityId, default);
        Assert.Equal("subscription", quota.Tier);
        Assert.Equal(400, quota.Limit);
        Assert.Equal(370, quota.Remaining);
        Assert.True((await client.GetFromJsonAsync<SubscriptionDto>("/v1/subscription"))!.Active);
    }

    [Fact]
    public async Task LinkingSecondPhonePreservesGrantAndConcurrentRequestsShareFourHundred()
    {
        var user = "billing-" + Guid.NewGuid();
        var (first, account) = await AccountAsync(user);
        var expiresAt = fixture.Clock.GetUtcNow().AddDays(1);
        await GrantAsync(account, expiresAt);
        var (second, linked) = await AccountAsync(user);
        Assert.Equal(account.Id, linked.Id);
        Assert.Equal(expiresAt, linked.TesterAccessExpiresAt);
        await SeedUsageAsync(account, 395);
        var requests = Enumerable.Range(0, 10).Select(async i =>
        {
            // Independent stores exercise the shared Firestore lease and transaction.
            var usage = new UsageStore(new FirestoreStore(Db.Database), fixture.Entitlements, fixture.Clock);
            return await usage.ReserveAsync(account.PrimaryIdentityId, Guid.NewGuid().ToString(), "fp", default);
        });
        var outcomes = await Task.WhenAll(requests);
        Assert.Equal(5, outcomes.Count(x => x.Kind == "reserved"));
        Assert.Equal(5, outcomes.Count(x => x.Kind == "quota_exceeded"));
        Assert.Equal(0, (await first.GetFromJsonAsync<QuotaDto>("/v1/quota"))!.Remaining);
        Assert.Equal(0, (await second.GetFromJsonAsync<QuotaDto>("/v1/quota"))!.Remaining);
    }

    private sealed class GatedEntitlements : IEntitlementResolver
    {
        public TaskCompletionSource Entered { get; } = new(TaskCreationOptions.RunContinuationsAsynchronously);
        public TaskCompletionSource Release { get; } = new(TaskCreationOptions.RunContinuationsAsynchronously);
        public async Task<bool> HasSubscriptionAsync(Guid id, CancellationToken ct)
        {
            Entered.TrySetResult();
            await Release.Task.WaitAsync(ct);
            return false;
        }
    }

    [Fact]
    public async Task RevocationAfterEntitlementLookupIsRecheckedInReservationTransaction()
    {
        var (_, account) = await AccountAsync();
        await GrantAsync(account, fixture.Clock.GetUtcNow().AddDays(1));
        await SeedUsageAsync(account, 5);
        var gate = new GatedEntitlements();
        using var timeout = new CancellationTokenSource(TimeSpan.FromSeconds(20));
        var pending = new UsageStore(Db, gate, fixture.Clock).ReserveAsync(account.PrimaryIdentityId, Guid.NewGuid().ToString(), "fp", timeout.Token);
        try
        {
            await gate.Entered.Task.WaitAsync(timeout.Token);
            await GrantAsync(account, null);
        }
        finally { gate.Release.TrySetResult(); }
        Assert.Equal("quota_exceeded", (await pending).Kind);
    }

    [Fact]
    public async Task OrdinaryClientsCannotGrantAccessAndGuestsNeverInheritIt()
    {
        var (client, account) = await AccountAsync();
        Assert.False((await client.PatchAsJsonAsync("/v1/account", new { testerAccessExpiresAt = fixture.Clock.GetUtcNow().AddDays(1) })).IsSuccessStatusCode);
        Assert.Null((await Db.GetAsync<VerifiedAccount>(Db.Accounts.Document(FirestoreStore.Id(account.Id))))!.TesterAccessExpiresAt);
        await GrantAsync(account, fixture.Clock.GetUtcNow().AddDays(1));
        var anonymous = fixture.Factory.CreateClient();
        var guest = await (await anonymous.PostAsJsonAsync("/v1/guest-sessions", new { installationId = Guid.NewGuid().ToString() }))
            .Content.ReadFromJsonAsync<GuestSessionDto>();
        Assert.Equal("free", guest!.Quota.Tier);
        Assert.Null(guest.Quota.TesterAccessExpiresAt);
    }
}
