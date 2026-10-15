using System.Net;
using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Sedno.Application;

namespace Sedno.Infrastructure;

public sealed record PlayBillingOptions(string PackageName, string ProductId);

public sealed class PlayBillingClient(HttpClient client, IPlayAccessTokenSource tokens,
    PlayBillingOptions options) : IPlayBillingClient
{
    private string BaseUrl => $"https://androidpublisher.googleapis.com/androidpublisher/v3/applications/{Uri.EscapeDataString(options.PackageName)}/purchases/";
    public async Task<PlaySubscription> GetAsync(string token, CancellationToken ct)
    {
        using var request = new HttpRequestMessage(HttpMethod.Get,
            BaseUrl + $"subscriptionsv2/tokens/{Uri.EscapeDataString(token)}");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", await tokens.GetAsync(ct));
        using var response = await client.SendAsync(request, ct);
        // Google stops exposing old expired purchase tokens. They cannot block free usage forever.
        if (response.StatusCode is HttpStatusCode.NotFound or HttpStatusCode.Gone)
            return new("SUBSCRIPTION_STATE_EXPIRED", null, true, null);
        // Do not include Google's response or URL (which contains a purchase token) in exceptions/logs.
        if (!response.IsSuccessStatusCode) throw new InvalidOperationException("Google Play verification unavailable.");
        using var doc = JsonDocument.Parse(await response.Content.ReadAsStringAsync(ct));
        var p = doc.RootElement;
        var items = p.GetProperty("lineItems").EnumerateArray().ToArray();
        if (items.Length != 1 || items[0].GetProperty("productId").GetString() != options.ProductId)
            throw new InvalidOperationException("Unexpected Play product.");
        DateTimeOffset? expiry = items[0].TryGetProperty("expiryTime", out var e) ? e.GetDateTimeOffset() : null;
        string? binding = p.TryGetProperty("externalAccountIdentifiers", out var ids) &&
            ids.TryGetProperty("obfuscatedExternalAccountId", out var id) ? id.GetString() : null;
        return new(p.GetProperty("subscriptionState").GetString()!, expiry,
            p.GetProperty("acknowledgementState").GetString() == "ACKNOWLEDGEMENT_STATE_ACKNOWLEDGED",
            binding, p.TryGetProperty("linkedPurchaseToken", out var linked) ? linked.GetString() : null);
    }
    public async Task AcknowledgeAsync(string token, CancellationToken ct)
    {
        using var request = new HttpRequestMessage(HttpMethod.Post,
            BaseUrl + $"subscriptions/{Uri.EscapeDataString(options.ProductId)}/tokens/{Uri.EscapeDataString(token)}:acknowledge");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", await tokens.GetAsync(ct));
        request.Content = JsonContent.Create(new { });
        using var response = await client.SendAsync(request, ct);
        if (!response.IsSuccessStatusCode) throw new InvalidOperationException("Google Play acknowledgement unavailable.");
    }
}

public sealed class DisabledPlayBillingClient : IPlayBillingClient
{
    public Task<PlaySubscription> GetAsync(string token, CancellationToken ct) => throw new InvalidOperationException("Billing is disabled.");
    public Task AcknowledgeAsync(string token, CancellationToken ct) => throw new InvalidOperationException("Billing is disabled.");
}
