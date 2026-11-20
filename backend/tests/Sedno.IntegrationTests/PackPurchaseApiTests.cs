using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.Extensions.DependencyInjection;
using Sedno.Application;
using Sedno.Domain;
using Sedno.Infrastructure;
using Xunit;

namespace Sedno.IntegrationTests;

[Collection("backend")]
public sealed class PackPurchaseApiTests(BackendFixture fixture)
{
    private async Task<(HttpClient Client, Guid Account)> AccountAsync(string user)
    {
        var client = fixture.Factory.CreateClient();
        using var guestResponse = await client.PostAsJsonAsync("/v1/guest-sessions", new { installationId = Guid.NewGuid() });
        guestResponse.EnsureSuccessStatusCode();
        var guest = (await guestResponse.Content.ReadFromJsonAsync<GuestSessionDto>())!;
        client.DefaultRequestHeaders.Authorization = new("Bearer", guest.AccessToken);
        using var accountResponse = await client.PostAsJsonAsync("/v1/auth/sessions", new { idToken = user });
        accountResponse.EnsureSuccessStatusCode();
        var account = (await accountResponse.Content.ReadFromJsonAsync<AuthenticatedSessionDto>())!;
        client.DefaultRequestHeaders.Authorization = new("Bearer", account.AccessToken);
        return (client, Guid.Parse(account.Account.Id));
    }

    private static async Task<string> VerifyAsync(HttpClient client, string token)
    {
        using var response = await client.PostAsJsonAsync("/v1/purchases/simplifications", new { purchaseToken = token });
        response.EnsureSuccessStatusCode();
        return (await response.Content.ReadFromJsonAsync<PackPurchaseDto>())!.State;
    }

    private static async Task<QuotaDto> QuotaAsync(HttpClient client) =>
        (await client.GetFromJsonAsync<QuotaDto>("/v1/quota"))!;

    private string CreatePurchase(Guid account, string state = "PURCHASED")
    {
        var token = Guid.NewGuid().ToString();
        fixture.Billing.Packs[token] = new(state, IPlayPackClient.ProductId, SubscriptionService.Binding(account), 1, false);
        return token;
    }

    [Fact]
    public async Task PendingAndAnotherAccountCannotCreditAndRetryAfterConsumeFailureCreditsOnce()
    {
        var (owner, account) = await AccountAsync("billing-" + Guid.NewGuid());
        var (other, _) = await AccountAsync("billing-" + Guid.NewGuid());
        var token = CreatePurchase(account, "PENDING");

        Assert.Equal("pending", await VerifyAsync(owner, token));
        Assert.Equal("invalid", await VerifyAsync(other, token));
        Assert.Equal(0, (await QuotaAsync(owner)).PackBalance);
        Assert.DoesNotContain(token, fixture.Billing.Consumptions.Keys);

        fixture.Billing.Packs[token] = fixture.Billing.Packs[token] with { State = "PURCHASED" };
        fixture.Billing.FailConsumption[token] = true;
        using var failure = await owner.PostAsJsonAsync("/v1/purchases/simplifications", new { purchaseToken = token });
        Assert.Equal(HttpStatusCode.InternalServerError, failure.StatusCode);
        Assert.Equal(1000, (await QuotaAsync(owner)).PackBalance);
        Assert.All(await Task.WhenAll(VerifyAsync(owner, token), VerifyAsync(owner, token)),
            state => Assert.Equal("credited", state));
        Assert.Equal(1, fixture.Billing.Consumptions[token]);
        Assert.Equal(1000, (await QuotaAsync(owner)).PackBalance);
        Assert.Equal(0, (await QuotaAsync(other)).PackBalance);
    }

    [Fact]
    public async Task PackReservationsTakePriorityAndHaveNoUtcReset()
    {
        var user = "billing-" + Guid.NewGuid();
        var (client, accountId) = await AccountAsync(user);
        var (second, _) = await AccountAsync(user);
        using var daily = await client.PostAsJsonAsync("/v1/simplifications", new { requestId = "before-pack", text = "Tekst" });
        daily.EnsureSuccessStatusCode();

        var token = CreatePurchase(accountId);
        Assert.Equal("credited", await VerifyAsync(client, token));
        Assert.Equal(1000, (await QuotaAsync(second)).PackRemaining);
        using var correction = await second.PostAsJsonAsync("/v1/simplifications",
            new { requestId = "pack-correction", text = "Tekst.", mode = "correct" });
        correction.EnsureSuccessStatusCode();
        var afterCorrection = await QuotaAsync(client);
        Assert.Equal(999, afterCorrection.PackBalance);
        Assert.Equal(1, afterCorrection.Used);

        var db = fixture.Factory.Services.GetRequiredService<FirestoreStore>();
        var accountReference = db.Accounts.Document(FirestoreStore.Id(accountId));
        var account = (await db.GetAsync<VerifiedAccount>(accountReference))!;
        account.PackCredits[FirestoreStore.Hash(token)] = 1;
        await db.PutAsync(accountReference, account);

        var identity = account.PrimaryIdentityId;
        var entitlements = fixture.Factory.Services.GetRequiredService<IServiceScopeFactory>();
        using var scope = entitlements.CreateScope();
        var usage = scope.ServiceProvider.GetRequiredService<IUsageStore>();
        Assert.Equal("reserved", (await usage.ReserveAsync(identity, "pack-failed", "fingerprint", default)).Kind);
        var held = await QuotaAsync(second);
        Assert.Equal(0, held.PackRemaining);
        Assert.Equal(1, held.PackBalance);
        Assert.Equal(4, held.Remaining);
        using var blocked = await second.PostAsJsonAsync("/v1/simplifications", new { requestId = "last-held", text = "Tekst" });
        Assert.Equal(HttpStatusCode.TooManyRequests, blocked.StatusCode);
        using var problem = JsonDocument.Parse(await blocked.Content.ReadAsStringAsync());
        Assert.Equal("pack_reserved", problem.RootElement.GetProperty("code").GetString());

        await usage.FailAsync(identity, "pack-failed", default);
        Assert.Equal(1, (await QuotaAsync(second)).PackRemaining);

        var now = fixture.Clock.GetUtcNow();
        try
        {
            fixture.Clock.Set(afterCorrection.ResetAt.AddMinutes(1));
            var tomorrow = await QuotaAsync(second);
            Assert.Equal(1, tomorrow.PackRemaining);
            Assert.Equal(5, tomorrow.Remaining);

            using var last = await client.PostAsJsonAsync("/v1/simplifications", new { requestId = "last-pack", text = "Tekst" });
            last.EnsureSuccessStatusCode();
            Assert.Equal(0, (await QuotaAsync(second)).PackBalance);
            using var free = await client.PostAsJsonAsync("/v1/simplifications", new { requestId = "back-to-free", text = "Tekst" });
            free.EnsureSuccessStatusCode();
            Assert.Equal(4, (await QuotaAsync(second)).Remaining);
        }
        finally { fixture.Clock.Set(now); }
    }

    [Fact]
    public async Task FullRefundRemovesOnlyTheRefundedPackAndCannotBeReplayed()
    {
        var (client, account) = await AccountAsync("billing-" + Guid.NewGuid());
        var first = CreatePurchase(account);
        var refunded = CreatePurchase(account);
        Assert.Equal("credited", await VerifyAsync(client, first));
        Assert.Equal("credited", await VerifyAsync(client, refunded));

        using var push = fixture.Factory.CreateClient();
        push.DefaultRequestHeaders.Authorization = new("Bearer", "trusted-push");
        var data = Convert.ToBase64String(JsonSerializer.SerializeToUtf8Bytes(new
        {
            packageName = "pl.sedno.test",
            voidedPurchaseNotification = new { purchaseToken = refunded, productType = 2, refundType = 1 }
        }));
        for (var attempt = 0; attempt < 2; attempt++)
        {
            using var response = await push.PostAsJsonAsync("/notifications/google-play",
                new { message = new { messageId = Guid.NewGuid().ToString(), data } });
            Assert.Equal(HttpStatusCode.NoContent, response.StatusCode);
        }
        Assert.Equal("invalid", await VerifyAsync(client, refunded));
        Assert.Equal(1000, (await QuotaAsync(client)).PackBalance);
    }
}
