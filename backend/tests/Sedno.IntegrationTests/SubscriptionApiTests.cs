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

    private SubscriptionService Service(FirestoreStore db, IPlayBillingClient billing, TimeProvider? clock = null) => new(db, billing,
        fixture.Factory.Services.GetRequiredService<Microsoft.AspNetCore.DataProtection.IDataProtectionProvider>(), clock ?? fixture.Clock);

    private async Task<(Guid Identity, string Token, FirestoreStore Db)> PaidAsync()
    {
        var (client, account) = await AccountAsync();
        var token = Guid.NewGuid().ToString();
        fixture.Billing.Purchases[token] = new("SUBSCRIPTION_STATE_ACTIVE", fixture.Clock.GetUtcNow().AddDays(1), true, SubscriptionService.Binding(account));
        (await client.PostAsJsonAsync("/v1/subscription", new { purchaseToken = token })).EnsureSuccessStatusCode();
        var db = fixture.Factory.Services.GetRequiredService<FirestoreStore>();
        var identity = (await db.GetAsync<Sedno.Domain.VerifiedAccount>(db.Accounts.Document(FirestoreStore.Id(account))))!.PrimaryIdentityId;
        return (identity, token, db);
    }

    private sealed class RefreshBilling(TestBilling inner) : IPlayBillingClient
    {
        public int Calls;
        public Exception? Failure;
        public TaskCompletionSource Entered { get; } = new(TaskCreationOptions.RunContinuationsAsynchronously);
        public TaskCompletionSource? Release;
        public async Task<PlaySubscription> GetAsync(string token, CancellationToken ct)
        {
            Interlocked.Increment(ref Calls);
            Entered.TrySetResult();
            if (Release is not null) await Release.Task.WaitAsync(ct);
            if (Failure is not null) throw Failure;
            return await inner.GetAsync(token, ct);
        }
        public Task AcknowledgeAsync(string token, CancellationToken ct) => inner.AcknowledgeAsync(token, ct);
    }

    [Fact]
    public async Task FreshVerificationDoesNotCallGoogleOrWriteFirestore()
    {
        var (identity, token, db) = await PaidAsync();
        var now = fixture.Clock.GetUtcNow();
        var reference = db.Purchases.Document(FirestoreStore.Hash(token));
        var before = await reference.GetSnapshotAsync();
        var leases = await db.Leases.GetSnapshotAsync();
        try
        {
            fixture.Clock.Set(now.AddMinutes(15).AddTicks(-1));
            Assert.True(await Service(db, new NoNetworkBilling()).HasSubscriptionAsync(identity, default));
            Assert.Equal(before.UpdateTime, (await reference.GetSnapshotAsync()).UpdateTime);
            Assert.Equal(leases.Documents.Select(x => (x.Id, x.UpdateTime)),
                (await db.Leases.GetSnapshotAsync()).Documents.Select(x => (x.Id, x.UpdateTime)));
        }
        finally { fixture.Clock.Set(now); }
    }

    [Fact]
    public async Task LostRtdnRevokedPurchaseLosesPaidQuotaAtFifteenMinutesWithoutResettingUsage()
    {
        var (identity, token, db) = await PaidAsync();
        var now = fixture.Clock.GetUtcNow();
        var billing = new RefreshBilling(fixture.Billing);
        var resolver = Service(db, billing);
        // More than the free allowance has already been used under the paid tier.
        for (var i = 0; i < 6; i++)
        {
            var usage = new UsageStore(db, resolver, fixture.Clock);
            var request = Guid.NewGuid().ToString();
            Assert.Equal("reserved", (await usage.ReserveAsync(identity, request, "fingerprint", default)).Kind);
            Assert.True(await usage.CompleteAsync(identity, request, default));
        }
        fixture.Billing.Purchases[token] = fixture.Billing.Purchases[token] with { State = "SUBSCRIPTION_STATE_EXPIRED" };
        try
        {
            fixture.Clock.Set(now.AddMinutes(15));
            var usage = new UsageStore(db, resolver, fixture.Clock);
            var quota = await usage.GetQuotaAsync(identity, default);
            Assert.Equal(5, quota.Limit);
            Assert.Equal(6, quota.Used);
            Assert.Equal(0, quota.Remaining);
            Assert.Equal("quota_exceeded", (await usage.ReserveAsync(identity, Guid.NewGuid().ToString(), "fingerprint", default)).Kind);
            Assert.Equal(1, billing.Calls);
        }
        finally { fixture.Clock.Set(now); }
    }

    [Theory]
    [InlineData(false)]
    [InlineData(true)]
    public async Task ConcurrentReplicasShareRefreshAndRecheckAfterLease(bool fail)
    {
        var (identity, token, db) = await PaidAsync();
        var now = fixture.Clock.GetUtcNow();
        var billing = new RefreshBilling(fixture.Billing)
        {
            Release = new(TaskCreationOptions.RunContinuationsAsynchronously),
            Failure = fail ? new HttpRequestException("Unavailable") : null
        };
        using var timeout = new CancellationTokenSource(TimeSpan.FromSeconds(20));
        fixture.Clock.Set(now.AddMinutes(15));
        var first = Service(db, billing).HasSubscriptionAsync(identity, timeout.Token);
        Task<bool>[] others = [];
        try
        {
            await billing.Entered.Task.WaitAsync(timeout.Token);
            // Independent stores/services share only Firestore, as separate replicas do.
            others = Enumerable.Range(0, 5).Select(_ => Service(new FirestoreStore(db.Database), billing)
                .HasSubscriptionAsync(identity, timeout.Token)).ToArray();
            billing.Release.TrySetResult();
            Assert.Equal(!fail, await first);
            Assert.All(await Task.WhenAll(others), active => Assert.Equal(!fail, active));
            Assert.Equal(1, billing.Calls);
            var row = (await db.GetAsync<Sedno.Domain.PlayPurchase>(db.Purchases.Document(FirestoreStore.Hash(token))))!;
            Assert.Equal(fail ? now : now.AddMinutes(15), row.VerifiedAt);
            Assert.Equal(now.AddDays(1), row.ExpiresAt);
        }
        finally
        {
            billing.Release.TrySetResult();
            try { await Task.WhenAll(others.Append(first)); }
            finally { fixture.Clock.Set(now); }
        }
    }

    [Theory]
    [InlineData(false)]
    [InlineData(true)]
    public async Task GoogleFailureUsesFreeQuotaAndSharedCooldownThenRecovers(bool timeout)
    {
        var (identity, token, db) = await PaidAsync();
        var now = fixture.Clock.GetUtcNow();
        var billing = new RefreshBilling(fixture.Billing)
        {
            Failure = timeout ? new TaskCanceledException("Google timeout") : new InvalidOperationException("Google unavailable")
        };
        var resolver = Service(db, billing);
        var usage = new UsageStore(db, resolver, fixture.Clock);
        var request = Guid.NewGuid().ToString();
        Assert.Equal("reserved", (await usage.ReserveAsync(identity, request, "fingerprint", default)).Kind);
        Assert.True(await usage.CompleteAsync(identity, request, default));
        try
        {
            fixture.Clock.Set(now.AddMinutes(15));
            var quota = await new UsageStore(db, resolver, fixture.Clock).GetQuotaAsync(identity, default);
            Assert.Equal(5, quota.Limit);
            Assert.Equal(1, quota.Used);
            Assert.Equal(4, quota.Remaining);
            var reference = db.Purchases.Document(FirestoreStore.Hash(token));
            var failed = await reference.GetSnapshotAsync();
            var row = FirestoreStore.Decode<Sedno.Domain.PlayPurchase>(failed)!;
            Assert.Equal(now, row.VerifiedAt);
            Assert.Equal(now.AddDays(1), row.ExpiresAt);
            fixture.Clock.Set(now.AddMinutes(16).AddTicks(-1));
            Assert.False(await Service(new FirestoreStore(db.Database), billing).HasSubscriptionAsync(identity, default));
            Assert.Equal(1, billing.Calls);
            Assert.Equal(failed.UpdateTime, (await reference.GetSnapshotAsync()).UpdateTime);
            billing.Failure = null;
            fixture.Clock.Set(now.AddMinutes(16));
            quota = await new UsageStore(db, resolver, fixture.Clock).GetQuotaAsync(identity, default);
            Assert.Equal(400, quota.Limit);
            Assert.Equal(1, quota.Used);
            Assert.Equal(2, billing.Calls);
        }
        finally { fixture.Clock.Set(now); }
    }

    [Fact]
    public async Task RtdnBypassesRefreshCooldownAndImmediatelyRevokesAccess()
    {
        var (identity, token, db) = await PaidAsync();
        var now = fixture.Clock.GetUtcNow();
        try
        {
            fixture.Clock.Set(now.AddMinutes(15));
            Assert.False(await Service(db, new NoNetworkBilling()).HasSubscriptionAsync(identity, default));
            Assert.Equal(HttpStatusCode.NoContent, (await NotifyAsync(token, Guid.NewGuid().ToString())).StatusCode);
            Assert.True(await Service(db, new NoNetworkBilling()).HasSubscriptionAsync(identity, default));
            fixture.Billing.Purchases[token] = fixture.Billing.Purchases[token] with { State = "SUBSCRIPTION_STATE_EXPIRED" };
            Assert.Equal(HttpStatusCode.NoContent, (await NotifyAsync(token, Guid.NewGuid().ToString(), refund: true)).StatusCode);
            Assert.False(await Service(db, new NoNetworkBilling()).HasSubscriptionAsync(identity, default));
        }
        finally { fixture.Clock.Set(now); }
    }

    [Theory]
    [InlineData(false)]
    [InlineData(true)]
    public async Task MissingOrFutureVerificationRequiresServerRefresh(bool future)
    {
        var (identity, token, db) = await PaidAsync();
        var reference = db.Purchases.Document(FirestoreStore.Hash(token));
        var row = (await db.GetAsync<Sedno.Domain.PlayPurchase>(reference))!;
        row.VerifiedAt = future ? fixture.Clock.GetUtcNow().AddMinutes(1) : null;
        await db.PutAsync(reference, row);
        var billing = new RefreshBilling(fixture.Billing);
        Assert.True(await Service(db, billing).HasSubscriptionAsync(identity, default));
        Assert.Equal(1, billing.Calls);
    }

    private sealed class RefreshClock(TimeProvider inner) : TimeProvider
    {
        public Action? Expire;
        public override DateTimeOffset GetUtcNow() => inner.GetUtcNow();
        public override ITimer CreateTimer(TimerCallback callback, object? state, TimeSpan dueTime, TimeSpan period)
        {
            Assert.Equal(TimeSpan.FromSeconds(2), dueTime);
            Expire = () => callback(state);
            return new Timer();
        }
        private sealed class Timer : ITimer
        {
            public bool Change(TimeSpan dueTime, TimeSpan period) => true;
            public void Dispose() { }
            public ValueTask DisposeAsync() => ValueTask.CompletedTask;
        }
    }

    [Fact]
    public async Task SlowGoogleRefreshTimesOutAndFallsBackWithoutCancelingRequest()
    {
        var (identity, _, db) = await PaidAsync();
        var now = fixture.Clock.GetUtcNow();
        var billing = new RefreshBilling(fixture.Billing) { Release = new(TaskCreationOptions.RunContinuationsAsynchronously) };
        var clock = new RefreshClock(fixture.Clock);
        using var request = new CancellationTokenSource(TimeSpan.FromSeconds(10));
        try
        {
            fixture.Clock.Set(now.AddMinutes(15));
            var pending = Service(db, billing, clock).HasSubscriptionAsync(identity, request.Token);
            await billing.Entered.Task.WaitAsync(request.Token);
            clock.Expire!();
            Assert.False(await pending);
            Assert.False(request.IsCancellationRequested);
            Assert.False(await Service(new FirestoreStore(db.Database), billing).HasSubscriptionAsync(identity, request.Token));
            Assert.Equal(1, billing.Calls);
        }
        finally { fixture.Clock.Set(now); }
    }

    [Fact]
    public async Task CanceledRefreshRetainsCooldownForNextReplica()
    {
        var (identity, _, db) = await PaidAsync();
        var now = fixture.Clock.GetUtcNow();
        var billing = new RefreshBilling(fixture.Billing) { Release = new(TaskCreationOptions.RunContinuationsAsynchronously) };
        using var cancellation = new CancellationTokenSource();
        try
        {
            fixture.Clock.Set(now.AddMinutes(15));
            var pending = Service(db, billing).HasSubscriptionAsync(identity, cancellation.Token);
            await billing.Entered.Task.WaitAsync(TimeSpan.FromSeconds(10));
            cancellation.Cancel();
            await Assert.ThrowsAnyAsync<OperationCanceledException>(() => pending);
            Assert.False(await Service(new FirestoreStore(db.Database), billing).HasSubscriptionAsync(identity, default));
            Assert.Equal(1, billing.Calls);
        }
        finally { fixture.Clock.Set(now); }
    }

    [Fact]
    public async Task FailedRtdnIsNotAcknowledgedAndCanBeRetriedDuringCooldown()
    {
        var (identity, token, db) = await PaidAsync();
        var now = fixture.Clock.GetUtcNow();
        var billing = new RefreshBilling(fixture.Billing) { Failure = new HttpRequestException("Google unavailable") };
        var id = Guid.NewGuid().ToString();
        try
        {
            fixture.Clock.Set(now.AddMinutes(15));
            Assert.False(await Service(db, billing).HasSubscriptionAsync(identity, default));
            await Assert.ThrowsAsync<HttpRequestException>(() => Service(db, billing).NotifyAsync(id, token, default));
            Assert.False((await db.PlayNotifications.Document(FirestoreStore.Hash(id)).GetSnapshotAsync()).Exists);
            billing.Failure = null;
            await Service(db, billing).NotifyAsync(id, token, default);
            Assert.True((await db.PlayNotifications.Document(FirestoreStore.Hash(id)).GetSnapshotAsync()).Exists);
            Assert.True(await Service(db, new NoNetworkBilling()).HasSubscriptionAsync(identity, default));
        }
        finally { fixture.Clock.Set(now); }
    }

    private sealed class CountingEntitlements : IEntitlementResolver
    {
        public int Calls;
        public Task<bool> HasSubscriptionAsync(Guid id, CancellationToken ct)
        {
            Interlocked.Increment(ref Calls);
            return Task.FromResult(true);
        }
    }

    [Fact]
    public async Task RequestScopedUsageLooksUpEntitlementOnce()
    {
        var client = fixture.Factory.CreateClient();
        var guest = await (await client.PostAsJsonAsync("/v1/guest-sessions", new { installationId = Guid.NewGuid().ToString() })).Content.ReadFromJsonAsync<GuestSessionDto>();
        var identity = Guid.Parse(guest!.Account.Id);
        using var scope = fixture.Factory.Services.CreateScope();
        var entitlements = new CountingEntitlements();
        var usage = new UsageStore(scope.ServiceProvider.GetRequiredService<FirestoreStore>(), entitlements, fixture.Clock);
        Assert.Equal("reserved", (await usage.ReserveAsync(identity, "once-" + Guid.NewGuid().ToString("N"), "fingerprint", default)).Kind);
        Assert.Equal(400, (await usage.GetQuotaAsync(identity, default)).Limit);
        Assert.Equal(1, entitlements.Calls);
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
