using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Google.Cloud.Firestore;
using Microsoft.Extensions.DependencyInjection;
using Sedno.Infrastructure;
using Sedno.Application;
using Xunit;

namespace Sedno.IntegrationTests;

[Collection("backend")]
public sealed class ApiTests(BackendFixture fixture)
{
    private HttpClient Client() => fixture.Factory.CreateClient();
    private async Task<(HttpClient Client, Guid Id, string Token)> GuestAsync(string? installationId = null)
    {
        var client = Client();
        var response = await client.PostAsJsonAsync("/v1/guest-sessions", new { installationId = installationId ?? Guid.NewGuid().ToString() });
        response.EnsureSuccessStatusCode();
        using var doc = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        var token = doc.RootElement.GetProperty("accessToken").GetString()!;
        var id = Guid.Parse(doc.RootElement.GetProperty("account").GetProperty("id").GetString()!);
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);
        return (client, id, token);
    }
    private static Task<HttpResponseMessage> Submit(HttpClient client, string id, string text) =>
        client.PostAsJsonAsync("/v1/simplifications", new { requestId = id, text });
    private static async Task<int> Remaining(HttpClient client)
    {
        using var doc = JsonDocument.Parse(await client.GetStringAsync("/v1/quota"));
        return doc.RootElement.GetProperty("remaining").GetInt32();
    }
    private static async Task<string> Code(HttpResponseMessage response)
    {
        using var doc = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        return doc.RootElement.GetProperty("code").GetString()!;
    }

    [Fact]
    public async Task LinkingGuestCarriesUsageOnceAndSignOutRevokesSession()
    {
        fixture.Clock.Set(new(2026, 10, 14, 12, 0, 0, TimeSpan.Zero));
        var first = await GuestAsync();
        Assert.Equal(HttpStatusCode.OK, (await Submit(first.Client, "before-login", "Tekst")).StatusCode);
        Assert.Equal("invalid_id_token", await Code(await first.Client.PostAsJsonAsync("/v1/auth/sessions",
            new { idToken = "forged" })));
        Assert.Equal(4, await Remaining(first.Client));
        var linked = await first.Client.PostAsJsonAsync("/v1/auth/sessions", new { idToken = "google-user-1" });
        linked.EnsureSuccessStatusCode();
        using var doc = JsonDocument.Parse(await linked.Content.ReadAsStringAsync());
        var accountToken = doc.RootElement.GetProperty("accessToken").GetString()!;
        Assert.Equal(1, doc.RootElement.GetProperty("quota").GetProperty("used").GetInt32());
        Assert.Equal(HttpStatusCode.Unauthorized, (await first.Client.GetAsync("/v1/quota")).StatusCode);
        first.Client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", accountToken);
        Assert.Equal(4, await Remaining(first.Client));
        Assert.Equal(HttpStatusCode.OK, (await Submit(first.Client, "after-login", "Drugi tekst")).StatusCode);
        Assert.Equal(3, await Remaining(first.Client));

        var second = await GuestAsync();
        Assert.Equal(5, await Remaining(second.Client));
        var secondLink = await second.Client.PostAsJsonAsync("/v1/auth/sessions", new { idToken = "email-user-1" });
        secondLink.EnsureSuccessStatusCode();
        using var secondDoc = JsonDocument.Parse(await secondLink.Content.ReadAsStringAsync());
        Assert.Equal(2, secondDoc.RootElement.GetProperty("quota").GetProperty("used").GetInt32());
        Assert.Equal(3, secondDoc.RootElement.GetProperty("quota").GetProperty("remaining").GetInt32());
        Assert.Equal(HttpStatusCode.NoContent, (await first.Client.PostAsync("/v1/auth/sign-out", null)).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await first.Client.GetAsync("/v1/quota")).StatusCode);
    }

    [Fact]
    public async Task UnverifiedEmailCannotLinkAndGuestUsageSurvivesVerification()
    {
        fixture.Clock.Set(new(2026, 10, 14, 12, 0, 0, TimeSpan.Zero));
        var guest = await GuestAsync();
        Assert.Equal(HttpStatusCode.OK, (await Submit(guest.Client, "before-email-verification", "Tekst")).StatusCode);
        var denied = await guest.Client.PostAsJsonAsync("/v1/auth/sessions", new { idToken = "email-verification-pending" });
        Assert.Equal(HttpStatusCode.Forbidden, denied.StatusCode);
        Assert.Equal("email_not_verified", await Code(denied));
        Assert.Equal(4, await Remaining(guest.Client));
        // The store also refuses an unverified identity if called outside the endpoint.
        using var scope = fixture.Factory.Services.CreateScope();
        var store = scope.ServiceProvider.GetRequiredService<IGuestStore>();
        var identity = await store.AuthenticateAsync(guest.Token, default);
        Assert.NotNull(identity);
        Assert.Null(await store.LinkAsync(identity, new("verification-user", "email"), default));
        var linked = await guest.Client.PostAsJsonAsync("/v1/auth/sessions", new { idToken = "email-verification-complete" });
        linked.EnsureSuccessStatusCode();
        using var doc = JsonDocument.Parse(await linked.Content.ReadAsStringAsync());
        Assert.Equal(4, doc.RootElement.GetProperty("quota").GetProperty("remaining").GetInt32());
    }

    [Theory]
    [InlineData("verified-email-legacy", true)]
    [InlineData("verified-email-legacy", false)]
    [InlineData("billing-legacy-google", true)]
    [InlineData("billing-legacy-google", false)]
    public async Task LegacyAccountSessionsCannotAccessAnyProtectedEndpoint(string idToken, bool missingField)
    {
        idToken += Guid.NewGuid().ToString("N");
        var installation = Guid.NewGuid().ToString();
        var guest = await GuestAsync(installation);
        Assert.Equal(HttpStatusCode.OK, (await Submit(guest.Client, "legacy-before", "Tekst")).StatusCode);
        var linked = await guest.Client.PostAsJsonAsync("/v1/auth/sessions", new { idToken });
        linked.EnsureSuccessStatusCode();
        var session = (await linked.Content.ReadFromJsonAsync<AuthenticatedSessionDto>())!;
        guest.Client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", session.AccessToken);
        Assert.Equal(4, await Remaining(guest.Client));
        using var scope = fixture.Factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<FirestoreStore>();
        // An absent field reproduces documents written before email verification.
        var reference = db.Sessions.Document(session.AccessToken.Split('.')[0]);
        await reference.UpdateAsync(new Dictionary<string, object>
        {
            ["AccountAccessVerified"] = missingField ? FieldValue.Delete : false
        });
        Assert.Equal(HttpStatusCode.Unauthorized, (await guest.Client.GetAsync("/v1/quota")).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await guest.Client.GetAsync("/v1/subscription")).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await Submit(guest.Client, "legacy-denied", "Tekst")).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await guest.Client.DeleteAsync("/v1/account")).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await guest.Client.PostAsJsonAsync("/v1/auth/sessions", new { idToken })).StatusCode);
        Assert.Null(await scope.ServiceProvider.GetRequiredService<IGuestStore>().AuthenticateAsync(session.AccessToken, default));
        var recovery = await GuestAsync(installation);
        Assert.Equal(4, await Remaining(recovery.Client));
        var renewed = await recovery.Client.PostAsJsonAsync("/v1/auth/sessions", new { idToken });
        renewed.EnsureSuccessStatusCode();
        var renewedSession = (await renewed.Content.ReadFromJsonAsync<AuthenticatedSessionDto>())!;
        recovery.Client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", renewedSession.AccessToken);
        Assert.Equal(4, await Remaining(recovery.Client));
        // A later verified login must not re-enable an older credential.
        Assert.Equal(HttpStatusCode.Unauthorized, (await guest.Client.GetAsync("/v1/quota")).StatusCode);
    }

    [Fact]
    public async Task IntegrityFailureDoesNotCreateGuest()
    {
        fixture.Integrity.Allow = false;
        try
        {
            using var client = Client();
            var response = await client.PostAsJsonAsync("/v1/guest-sessions",
                new { installationId = Guid.NewGuid().ToString(), integrityToken = "bad" });
            Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
            Assert.Equal("integrity_failed", await Code(response));
        }
        finally { fixture.Integrity.Allow = true; }
    }

    [Fact]
    public async Task LinkingSharedInstallationAndAnotherDeviceCountsEachRequestOnce()
    {
        fixture.Clock.Set(new(2026, 10, 14, 12, 0, 0, TimeSpan.Zero));
        var installation = Guid.NewGuid().ToString();
        var first = await GuestAsync(installation);
        Assert.Equal(HttpStatusCode.OK, (await Submit(first.Client, "one", "Pierwszy")).StatusCode);
        (await first.Client.PostAsJsonAsync("/v1/auth/sessions", new { idToken = "google-user-2" }))
            .EnsureSuccessStatusCode();
        var sameInstallation = await GuestAsync(installation);
        Assert.Equal(4, await Remaining(sameInstallation.Client));
        var sameLink = await sameInstallation.Client.PostAsJsonAsync("/v1/auth/sessions",
            new { idToken = "google-user-2" });
        sameLink.EnsureSuccessStatusCode();
        using var sameDoc = JsonDocument.Parse(await sameLink.Content.ReadAsStringAsync());
        Assert.Equal(1, sameDoc.RootElement.GetProperty("quota").GetProperty("used").GetInt32());

        var anotherDevice = await GuestAsync();
        Assert.Equal(HttpStatusCode.OK, (await Submit(anotherDevice.Client, "two", "Drugi")).StatusCode);
        var anotherLink = await anotherDevice.Client.PostAsJsonAsync("/v1/auth/sessions",
            new { idToken = "google-user-2" });
        anotherLink.EnsureSuccessStatusCode();
        using var anotherDoc = JsonDocument.Parse(await anotherLink.Content.ReadAsStringAsync());
        Assert.Equal(2, anotherDoc.RootElement.GetProperty("quota").GetProperty("used").GetInt32());
        Assert.Equal(3, anotherDoc.RootElement.GetProperty("quota").GetProperty("remaining").GetInt32());
    }

    [Fact]
    public async Task GuestAuthenticationAndOwnership()
    {
        fixture.Clock.Set(new(2026, 10, 14, 12, 0, 0, TimeSpan.Zero));
        using var anonymous = Client();
        Assert.Equal(HttpStatusCode.Unauthorized, (await anonymous.GetAsync("/v1/quota")).StatusCode);
        var a = await GuestAsync(); var b = await GuestAsync();
        Assert.Equal(HttpStatusCode.Unauthorized, (await anonymous.GetAsync("/v1/simplifications/requests/one")).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await Submit(a.Client, "one", "Zażółć gęślą jaźń")).StatusCode);
        using var ownStatus = JsonDocument.Parse(await a.Client.GetStringAsync("/v1/simplifications/requests/one"));
        Assert.Equal("succeeded", ownStatus.RootElement.GetProperty("status").GetString());
        Assert.False(ownStatus.RootElement.TryGetProperty("text", out _));
        Assert.Equal(HttpStatusCode.NotFound, (await b.Client.GetAsync("/v1/simplifications/requests/one")).StatusCode);
        a.Client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", a.Token + "x");
        Assert.Equal(HttpStatusCode.Unauthorized, (await a.Client.GetAsync("/v1/quota")).StatusCode);
    }

    [Fact]
    public async Task SameInstallationSharesQuotaWithoutSharingAuthentication()
    {
        fixture.Clock.Set(new(2026, 10, 14, 12, 0, 0, TimeSpan.Zero));
        var installationId = Guid.NewGuid().ToString();
        var a = await GuestAsync(installationId);
        var b = await GuestAsync(installationId);
        Assert.NotEqual(a.Id, b.Id);
        Assert.NotEqual(a.Token, b.Token);
        Assert.Equal(HttpStatusCode.OK, (await Submit(a.Client, "shared", "Tekst")).StatusCode);
        Assert.Equal(4, await Remaining(b.Client));
        Assert.Equal(HttpStatusCode.NotFound,
            (await b.Client.GetAsync("/v1/simplifications/requests/shared")).StatusCode);
    }

    [Fact]
    public async Task ValidatesBlankLongPolishAndEmojiText()
    {
        fixture.Clock.Set(new(2026, 10, 14, 12, 0, 0, TimeSpan.Zero));
        var guest = await GuestAsync();
        Assert.Equal("empty_text", await Code(await Submit(guest.Client, "blank", " \n ")));
        Assert.Equal("text_too_long", await Code(await Submit(guest.Client, "long", new string('ą', 4001))));
        Assert.Equal(HttpStatusCode.OK, (await Submit(guest.Client, "polish", "Zażółć gęślą jaźń")).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await Submit(guest.Client, "emoji", string.Concat(Enumerable.Repeat("👩‍💻", 4000)))).StatusCode);
        Assert.Equal(3, await Remaining(guest.Client));
        var oversized = await Submit(guest.Client, "body", new string('a', 140_000));
        Assert.Equal(HttpStatusCode.RequestEntityTooLarge, oversized.StatusCode);
    }

    [Fact]
    public async Task FreeLimitParallelBoundaryAndDuplicateKeys()
    {
        fixture.Clock.Set(new(2026, 10, 14, 12, 0, 0, TimeSpan.Zero));
        fixture.Model.Reset();
        var guest = await GuestAsync();
        var calls = Enumerable.Range(0, 6).Select(i => Submit(guest.Client, $"parallel{i}", "Tekst" + i));
        var results = await Task.WhenAll(calls);
        Assert.True(results.Count(x => x.StatusCode == HttpStatusCode.OK) == 5, string.Join(", ", results.Select(x => x.StatusCode)) + "\n" + string.Join("\n", fixture.Logs.Messages.Where(x => x.StartsWith("Czas upraszczania")).TakeLast(6)));
        Assert.Single(results, x => x.StatusCode == HttpStatusCode.TooManyRequests);
        Assert.Equal(5, fixture.Model.Calls);
        var completed = Array.FindIndex(results, x => x.StatusCode == HttpStatusCode.OK);
        var duplicate = await Submit(guest.Client, $"parallel{completed}", "Tekst" + completed);
        Assert.Equal("result_unavailable", await Code(duplicate));
        Assert.Equal("key_conflict", await Code(await Submit(guest.Client, $"parallel{completed}", "Inny tekst")));
        Assert.Equal(5, fixture.Model.Calls);
    }

    [Fact]
    public async Task PendingDuplicateCallsModelOnce()
    {
        fixture.Clock.Set(new(2026, 10, 14, 12, 0, 0, TimeSpan.Zero));
        fixture.Model.Reset();
        fixture.Model.Gate = new(TaskCreationOptions.RunContinuationsAsynchronously);
        var guest = await GuestAsync();
        var first = Submit(guest.Client, "pending", "Tekst");
        await SpinWaitUntil(() => fixture.Model.Calls == 1);
        Assert.Equal(HttpStatusCode.Accepted, (await Submit(guest.Client, "pending", "Tekst")).StatusCode);
        Assert.Equal(1, fixture.Model.Calls);
        fixture.Model.Gate.SetResult(true);
        Assert.Equal(HttpStatusCode.OK, (await first).StatusCode);
        fixture.Model.Reset();
    }

    [Fact]
    public async Task FailureReleasesReservation()
    {
        fixture.Clock.Set(new(2026, 10, 14, 12, 0, 0, TimeSpan.Zero));
        fixture.Model.Reset(); fixture.Model.Fail = true;
        var guest = await GuestAsync();
        Assert.Equal(HttpStatusCode.ServiceUnavailable, (await Submit(guest.Client, "fail", "Tekst")).StatusCode);
        Assert.Equal(5, await Remaining(guest.Client));
        fixture.Model.Fail = false;
        Assert.Equal(HttpStatusCode.OK, (await Submit(guest.Client, "new", "Tekst")).StatusCode);
        fixture.Model.Reset();
    }

    [Fact]
    public async Task PaidLimitIncludesFreeUsage()
    {
        fixture.Clock.Set(new(2026, 10, 14, 12, 0, 0, TimeSpan.Zero));
        var guest = await GuestAsync();
        Assert.Equal(HttpStatusCode.OK, (await Submit(guest.Client, "free", "Tekst")).StatusCode);
        fixture.Entitlements.Paid.Add(guest.Id);
        Assert.Equal(399, await Remaining(guest.Client));
        using var scope = fixture.Factory.Services.CreateScope();
        var usage = scope.ServiceProvider.GetRequiredService<IUsageStore>();
        for (var i = 0; i < 399; i++)
        {
            Assert.Equal("reserved", (await usage.ReserveAsync(guest.Id, $"paid{i}", $"fingerprint{i}", default)).Kind);
            Assert.True(await usage.CompleteAsync(guest.Id, $"paid{i}", default));
        }
        Assert.Equal(0, (await usage.GetQuotaAsync(guest.Id, default)).Remaining);
        Assert.Equal("quota_exceeded", (await usage.ReserveAsync(guest.Id, "extra", "fingerprint", default)).Kind);
    }

    [Fact]
    public async Task MidnightReservationAndCrashRecovery()
    {
        fixture.Clock.Set(new(2026, 10, 14, 23, 59, 30, TimeSpan.Zero));
        var guest = await GuestAsync();
        using var scope = fixture.Factory.Services.CreateScope();
        var usage = scope.ServiceProvider.GetRequiredService<IUsageStore>();
        Assert.Equal("reserved", (await usage.ReserveAsync(guest.Id, "cross", "fingerprint", default)).Kind);
        fixture.Clock.Set(new(2026, 10, 15, 0, 0, 10, TimeSpan.Zero));
        Assert.True(await usage.CompleteAsync(guest.Id, "cross", default));
        Assert.Equal(5, (await usage.GetQuotaAsync(guest.Id, default)).Remaining);
        Assert.Equal("reserved", (await usage.ReserveAsync(guest.Id, "crashed", "fingerprint", default)).Kind);
        fixture.Clock.Set(new(2026, 10, 15, 0, 6, 0, TimeSpan.Zero));
        Assert.Equal(5, (await usage.GetQuotaAsync(guest.Id, default)).Remaining);
        Assert.False(await usage.CompleteAsync(guest.Id, "crashed", default));
        Assert.Equal("expired", (await usage.GetStatusAsync(guest.Id, "crashed", default))!.Status);
    }

    [Fact]
    public async Task LogsExcludeTextAndCredential()
    {
        fixture.Clock.Set(new(2026, 10, 14, 12, 0, 0, TimeSpan.Zero));
        var guest = await GuestAsync();
        const string sensitive = "PoufnyTekstZolty42";
        await Submit(guest.Client, "logcheck", sensitive);
        var logs = string.Join('\n', fixture.Logs.Messages);
        Assert.DoesNotContain(sensitive, logs);
        Assert.DoesNotContain(guest.Token, logs);
    }

    private sealed class GatedEntitlements(Guid blockedIdentity) : IEntitlementResolver
    {
        public TaskCompletionSource Entered { get; } = new(TaskCreationOptions.RunContinuationsAsynchronously);
        public TaskCompletionSource Release { get; } = new(TaskCreationOptions.RunContinuationsAsynchronously);
        public async Task<bool> HasSubscriptionAsync(Guid id, CancellationToken ct)
        {
            if (id == blockedIdentity)
            {
                Entered.TrySetResult();
                await Release.Task.WaitAsync(ct);
            }
            return false;
        }
    }

    [Fact]
    public async Task SlowEntitlementLookupDoesNotBlockOtherReservations()
    {
        var installation = Guid.NewGuid().ToString();
        var first = await GuestAsync(installation);
        var same = await GuestAsync(installation);
        var other = await GuestAsync();
        using var firstScope = fixture.Factory.Services.CreateScope();
        using var sameScope = fixture.Factory.Services.CreateScope();
        using var otherScope = fixture.Factory.Services.CreateScope();
        var gate = new GatedEntitlements(first.Id);
        UsageStore Store(IServiceScope scope) => new(scope.ServiceProvider.GetRequiredService<FirestoreStore>(), gate, fixture.Clock);
        using var timeout = new CancellationTokenSource(TimeSpan.FromSeconds(10));
        var pending = Store(firstScope).ReserveAsync(first.Id, "held", "fingerprint", timeout.Token);
        Task<ReservationOutcome>? samePending = null;
        try
        {
            await gate.Entered.Task.WaitAsync(timeout.Token);
            samePending = Store(sameScope).ReserveAsync(same.Id, "same", "fingerprint", timeout.Token);
            // External dependency waits do not hold Firestore transaction locks.
            var independent = await Store(otherScope).ReserveAsync(other.Id, "other", "fingerprint", timeout.Token);
            Assert.Equal("reserved", independent.Kind);
            Assert.Equal("reserved", (await samePending).Kind);
        }
        finally
        {
            gate.Release.TrySetResult();
            await pending;
            if (samePending is not null) await samePending;
        }
    }

    private sealed class GatedIdentity : IIdentityAccountDeletion
    {
        public TaskCompletionSource Entered { get; } = new(TaskCreationOptions.RunContinuationsAsynchronously);
        public TaskCompletionSource Release { get; } = new(TaskCreationOptions.RunContinuationsAsynchronously);
        public async Task<IdentityAccountStatus> GetStatusAsync(string uid, CancellationToken ct)
        {
            Entered.TrySetResult();
            await Release.Task.WaitAsync(ct);
            return new(true, 0);
        }
        public Task DeleteAsync(string uid, CancellationToken ct) => Task.CompletedTask;
    }

    [Fact]
    public async Task SlowIdentityLookupDoesNotBlockUnrelatedSimplification()
    {
        var first = await GuestAsync();
        var other = await GuestAsync();
        using var scope = fixture.Factory.Services.CreateScope();
        var gate = new GatedIdentity();
        var store = new GuestStore(scope.ServiceProvider.GetRequiredService<FirestoreStore>(),
            scope.ServiceProvider.GetRequiredService<IUsageStore>(), fixture.Clock,
            Enumerable.Repeat((byte)1, 32).ToArray(), new FirebaseAccountAccess(gate, fixture.Clock));
        using var timeout = new CancellationTokenSource(TimeSpan.FromSeconds(10));
        var pending = store.LinkAsync(new(first.Id, null, Guid.ParseExact(first.Token.Split('.')[0], "N")), new("parallel-" + Guid.NewGuid(), "google", AuthTime: fixture.Clock.GetUtcNow().ToUnixTimeSeconds()), timeout.Token);
        try
        {
            await gate.Entered.Task.WaitAsync(timeout.Token);
            var response = await Submit(other.Client, "during-login", "Tekst").WaitAsync(timeout.Token);
            Assert.Equal(HttpStatusCode.OK, response.StatusCode);
            Assert.False(pending.IsCompleted);
        }
        finally
        {
            gate.Release.TrySetResult();
            await pending;
        }
    }

    private static async Task SpinWaitUntil(Func<bool> condition)
    {
        for (var i = 0; i < 100 && !condition(); i++) await Task.Delay(10);
        Assert.True(condition());
    }
}
