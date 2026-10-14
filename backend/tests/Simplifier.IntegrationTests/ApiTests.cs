using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.Extensions.DependencyInjection;
using Simplifier.Application;
using Xunit;

namespace Simplifier.IntegrationTests;

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
        Assert.Equal(1, await Remaining(b.Client));
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
        Assert.Equal(0, await Remaining(guest.Client));
        var oversized = await Submit(guest.Client, "body", new string('a', 140_000));
        Assert.Equal(HttpStatusCode.RequestEntityTooLarge, oversized.StatusCode);
    }

    [Fact]
    public async Task FreeLimitParallelBoundaryAndDuplicateKeys()
    {
        fixture.Clock.Set(new(2026, 10, 14, 12, 0, 0, TimeSpan.Zero));
        fixture.Model.Reset();
        var guest = await GuestAsync();
        var calls = Enumerable.Range(0, 3).Select(i => Submit(guest.Client, $"parallel{i}", "Tekst" + i));
        var results = await Task.WhenAll(calls);
        Assert.Equal(2, results.Count(x => x.StatusCode == HttpStatusCode.OK));
        Assert.Single(results, x => x.StatusCode == HttpStatusCode.TooManyRequests);
        Assert.Equal(2, fixture.Model.Calls);
        var completed = Array.FindIndex(results, x => x.StatusCode == HttpStatusCode.OK);
        var duplicate = await Submit(guest.Client, $"parallel{completed}", "Tekst" + completed);
        Assert.Equal("result_unavailable", await Code(duplicate));
        Assert.Equal("key_conflict", await Code(await Submit(guest.Client, $"parallel{completed}", "Inny tekst")));
        Assert.Equal(2, fixture.Model.Calls);
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
        Assert.Equal(2, await Remaining(guest.Client));
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
        Assert.Equal(2, (await usage.GetQuotaAsync(guest.Id, default)).Remaining);
        Assert.Equal("reserved", (await usage.ReserveAsync(guest.Id, "crashed", "fingerprint", default)).Kind);
        fixture.Clock.Set(new(2026, 10, 15, 0, 6, 0, TimeSpan.Zero));
        Assert.Equal(2, (await usage.GetQuotaAsync(guest.Id, default)).Remaining);
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

    private static async Task SpinWaitUntil(Func<bool> condition)
    {
        for (var i = 0; i < 100 && !condition(); i++) await Task.Delay(10);
        Assert.True(condition());
    }
}
