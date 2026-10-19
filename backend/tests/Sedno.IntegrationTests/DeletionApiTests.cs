using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.Extensions.DependencyInjection;
using Sedno.Infrastructure;
using Sedno.Domain;
using Xunit;

namespace Sedno.IntegrationTests;

[Collection("backend")]
public sealed class DeletionApiTests(BackendFixture fixture)
{
    private async Task<(HttpClient Client, Guid Identity)> GuestAsync()
    {
        var client = fixture.Factory.CreateClient();
        var response = await client.PostAsJsonAsync("/v1/guest-sessions", new { installationId = Guid.NewGuid().ToString() });
        response.EnsureSuccessStatusCode();
        using var doc = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", doc.RootElement.GetProperty("accessToken").GetString());
        return (client, Guid.Parse(doc.RootElement.GetProperty("account").GetProperty("id").GetString()!));
    }
    private static async Task<Guid> LinkAsync(HttpClient client, string token)
    {
        var response = await client.PostAsJsonAsync("/v1/auth/sessions", new { idToken = token });
        response.EnsureSuccessStatusCode();
        using var doc = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", doc.RootElement.GetProperty("accessToken").GetString());
        return Guid.Parse(doc.RootElement.GetProperty("account").GetProperty("id").GetString()!);
    }

    [Fact]
    public async Task DeletionRequiresAccountAndRemovesOnlyOwnersDataAcrossDevices()
    {
        fixture.Clock.Set(new(2026, 10, 15, 12, 0, 0, TimeSpan.Zero));
        using var anonymous = fixture.Factory.CreateClient();
        Assert.Equal(HttpStatusCode.Unauthorized, (await anonymous.DeleteAsync("/v1/account")).StatusCode);
        var (first, firstId) = await GuestAsync();
        Assert.Equal(HttpStatusCode.Forbidden, (await first.DeleteAsync("/v1/account")).StatusCode);
        var sensitive = "PRYWATNY TEKST USUWANIA 9d3ed";
        (await first.PostAsJsonAsync("/v1/simplifications", new { requestId = "deletion", text = sensitive })).EnsureSuccessStatusCode();
        var accountId = await LinkAsync(first, "deletion-user");
        var (second, secondId) = await GuestAsync();
        Assert.Equal(accountId, await LinkAsync(second, "deletion-user"));
        var (other, otherId) = await GuestAsync();
        var otherAccount = await LinkAsync(other, "deletion-other");
        using (var scope = fixture.Factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<FirestoreStore>();
            await db.PutAsync(db.Purchases.Document(new string('D', 64)), new PlayPurchase { TokenHash = new string('D', 64), ProtectedToken = "encrypted-test", AccountId = accountId });
        }
        fixture.IdentityAccounts.Fail = true;
        try
        {
            Assert.Equal(HttpStatusCode.InternalServerError, (await first.DeleteAsync("/v1/account")).StatusCode);
            using var scope = fixture.Factory.Services.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<FirestoreStore>();
            var pending = await db.GetAsync<VerifiedAccount>(db.Accounts.Document(FirestoreStore.Id(accountId)));
            Assert.NotNull(pending);
            Assert.True(pending.Deleting);
        }
        finally { fixture.IdentityAccounts.Fail = false; }
        var bearer = first.DefaultRequestHeaders.Authorization!.Parameter!;
        Assert.Equal(HttpStatusCode.NoContent, (await first.DeleteAsync("/v1/account")).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await first.GetAsync("/v1/quota")).StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, (await second.GetAsync("/v1/quota")).StatusCode);
        Assert.Equal(HttpStatusCode.OK, (await other.GetAsync("/v1/quota")).StatusCode);
        using (var scope = fixture.Factory.Services.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<FirestoreStore>();
            Assert.False((await db.Accounts.Document(FirestoreStore.Id(accountId)).GetSnapshotAsync()).Exists);
            Assert.False((await db.Identities.Document(FirestoreStore.Id(firstId)).GetSnapshotAsync()).Exists);
            Assert.False((await db.Identities.Document(FirestoreStore.Id(secondId)).GetSnapshotAsync()).Exists);
            Assert.Empty(await db.ListAsync<GuestSession>(db.Sessions.WhereEqualTo("AccountId", accountId.ToString())));
            foreach (var id in new[] { firstId, secondId })
            {
                Assert.Empty(await db.ListAsync<GuestSession>(db.Sessions.WhereEqualTo("IdentityId", id.ToString())));
                Assert.Empty(await db.ListAsync<SimplificationRecord>(db.Requests.WhereEqualTo("IdentityId", id.ToString())));
            }
            Assert.Empty(await db.ListAsync<PlayPurchase>(db.Purchases.WhereEqualTo("AccountId", accountId.ToString())));
            Assert.True((await db.Accounts.Document(FirestoreStore.Id(otherAccount)).GetSnapshotAsync()).Exists);
        }
        Assert.True(fixture.IdentityAccounts.Deleted.ContainsKey("user-delete"));
        var (newGuest, _) = await GuestAsync();
        Assert.Equal(HttpStatusCode.Conflict, (await newGuest.PostAsJsonAsync("/v1/auth/sessions", new { idToken = "deletion-user" })).StatusCode);
        var logs = string.Join('\n', fixture.Logs.Messages);
        Assert.DoesNotContain(sensitive, logs);
        Assert.DoesNotContain("Wersja demonstracyjna: " + sensitive, logs);
        Assert.DoesNotContain(bearer, logs);
        Assert.DoesNotContain("deletion-user", logs);
    }

    [Fact]
    public async Task PublicPrivacyPageIsEmbeddedAndNeedsNoSession()
    {
        using var client = fixture.Factory.CreateClient();
        using var response = await client.GetAsync("/prywatnosc");
        response.EnsureSuccessStatusCode();
        Assert.Equal("text/html", response.Content.Headers.ContentType!.MediaType);
        Assert.Equal("no-store", response.Headers.CacheControl!.ToString());
        Assert.Contains("frame-ancestors 'none'", response.Headers.GetValues("Content-Security-Policy").Single());
        var html = WebUtility.HtmlDecode(await response.Content.ReadAsStringAsync());
        Assert.Contains("lang=\"pl\"", html);
        Assert.Contains("Administrator: Mariusz Bąbka", html);
        Assert.Contains("Cele i podstawy przetwarzania", html);
        Assert.Contains("Twoje prawa i kontakt", html);
        Assert.Contains("Infrastruktura Sedno", html);
        Assert.Contains("płatności Google Play pozostają wyłączone", html);
        Assert.DoesNotContain("Planowana infrastruktura produkcyjna", html);
        Assert.Contains("https://sedno.xyz/#prywatnosc", html);
        Assert.Contains("https://sedno.xyz/usun-konto", html);
        Assert.DoesNotContain("DO UZUPEŁNIENIA", html);
        Assert.DoesNotContain("<script", html);
    }

    [Fact]
    public async Task PublicPageNeedsNoSessionAndExplainsExternalRequestAndSubscription()
    {
        using var client = fixture.Factory.CreateClient();
        var response = await client.GetAsync("/usun-konto");
        response.EnsureSuccessStatusCode();
        var html = await response.Content.ReadAsStringAsync();
        Assert.Contains("Sedno", html);
        Assert.Contains("href=\"https://sedno.xyz\"", html);
        Assert.Contains("mailto:privacy%40test.invalid", html);
        Assert.Contains("nie anuluje subskrypcji", html);
        Assert.Contains("Zweryfikujemy", html);
        Assert.Contains("href=\"/prywatnosc\"", html);
        Assert.DoesNotContain("DO UZUPEŁNIENIA", html);
        Assert.Equal("no-store", response.Headers.CacheControl!.ToString());
    }
}
