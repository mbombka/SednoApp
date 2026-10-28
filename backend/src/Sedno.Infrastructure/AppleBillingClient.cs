using System.Net.Http.Headers;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Sedno.Application;

namespace Sedno.Infrastructure;

public sealed class AppleBillingClient(HttpClient http, IAppleSignedDataVerifier signatures,
    AppleBillingOptions options, TimeProvider clock) : IAppleBillingClient
{
    // Use current subscription status, not a replayable historic purchase JWS.
    public async Task<AppleSubscription> GetAsync(string transactionId, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(transactionId) || transactionId.Length > 128 || !transactionId.All(char.IsAsciiDigit))
            throw new InvalidOperationException("Invalid Apple transaction identifier.");
        var host = options.Environment == "Sandbox" ? "api.storekit-sandbox.apple.com" : "api.storekit.apple.com";
        using var request = new HttpRequestMessage(HttpMethod.Get,
            $"https://{host}/inApps/v1/subscriptions/{Uri.EscapeDataString(transactionId)}");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", CreateToken());
        using var response = await http.SendAsync(request, ct);
        response.EnsureSuccessStatusCode();
        using var document = JsonDocument.Parse(await response.Content.ReadAsStringAsync(ct));
        var p = document.RootElement;
        ValidateApplication(p);
        if (options.Environment == "Production" && p.GetProperty("appAppleId").GetInt64() != options.AppAppleId)
            throw new InvalidOperationException("Apple application mismatch.");
        var matches = new List<AppleSubscription>();
        foreach (var group in p.GetProperty("data").EnumerateArray())
            foreach (var item in group.GetProperty("lastTransactions").EnumerateArray())
            {
                var transaction = signatures.Verify(item.GetProperty("signedTransactionInfo").GetString()!);
                ValidateApplication(transaction);
                if (transaction.GetProperty("productId").GetString() != options.ProductId) continue;
                if (transaction.GetProperty("type").GetString() != "Auto-Renewable Subscription")
                    throw new InvalidOperationException("Unexpected Apple purchase type.");
                var original = transaction.GetProperty("originalTransactionId").GetString()!;
                if (original != item.GetProperty("originalTransactionId").GetString())
                    throw new InvalidOperationException("Apple transaction mismatch.");
                var token = transaction.GetProperty("appAccountToken").GetString();
                if (!Guid.TryParse(token, out var accountToken)) throw new InvalidOperationException("Missing Apple account binding.");
                var status = item.GetProperty("status").GetInt32();
                DateTimeOffset? expiry = Date(transaction, "expiresDate");
                var renewal = signatures.Verify(item.GetProperty("signedRenewalInfo").GetString()!);
                if (renewal.GetProperty("environment").GetString() != options.Environment ||
                    renewal.GetProperty("originalTransactionId").GetString() != original ||
                    renewal.GetProperty("productId").GetString() != options.ProductId)
                    throw new InvalidOperationException("Apple renewal mismatch.");
                if (status == 4) expiry = Date(renewal, "gracePeriodExpiresDate");
                var revoked = status == 5 || Date(transaction, "revocationDate") is not null;
                matches.Add(new(original, transaction.GetProperty("transactionId").GetString()!, accountToken.ToString(),
                    status switch { 1 => "active", 2 => "expired", 3 => "billing_retry", 4 => "grace_period", 5 => "revoked", _ => "inactive" },
                    expiry, Date(transaction, "signedDate")!.Value, revoked));
            }
        // A lookup must resolve one subscription chain, not an unrelated product in
        // another subscription group returned for the same customer.
        var selected = matches.Where(x => x.OriginalTransactionId == transactionId || x.TransactionId == transactionId)
            .OrderByDescending(x => x.SignedAt).FirstOrDefault();
        if (selected is null && matches.Count == 1) selected = matches[0]; // lookup may use an older renewal ID
        return selected ?? throw new InvalidOperationException("Apple subscription not found.");
    }

    public AppleNotification VerifyNotification(string signedPayload)
    {
        var p = signatures.Verify(signedPayload);
        if (p.GetProperty("version").GetString() != "2.0") throw new InvalidOperationException("Unsupported Apple notification.");
        var data = p.GetProperty("data");
        ValidateApplication(data);
        if (options.Environment == "Production" && data.GetProperty("appAppleId").GetInt64() != options.AppAppleId)
            throw new InvalidOperationException("Apple application mismatch.");
        var id = p.GetProperty("notificationUUID").GetString();
        if (!Guid.TryParse(id, out _)) throw new InvalidOperationException("Invalid Apple notification ID.");
        var signedAt = Date(p, "signedDate")!.Value;
        if (p.GetProperty("notificationType").GetString() == "TEST") return new(id!, null, signedAt);
        var transaction = signatures.Verify(data.GetProperty("signedTransactionInfo").GetString()!);
        ValidateApplication(transaction);
        if (transaction.GetProperty("productId").GetString() != options.ProductId)
            throw new InvalidOperationException("Apple product mismatch.");
        return new(id!, transaction.GetProperty("originalTransactionId").GetString(), signedAt);
    }

    private void ValidateApplication(JsonElement p)
    {
        if (p.GetProperty("bundleId").GetString() != options.BundleId || p.GetProperty("environment").GetString() != options.Environment)
            throw new InvalidOperationException("Apple bundle or environment mismatch.");
    }
    private static DateTimeOffset? Date(JsonElement p, string key) => p.TryGetProperty(key, out var value) && value.ValueKind == JsonValueKind.Number
        ? DateTimeOffset.FromUnixTimeMilliseconds(value.GetInt64()) : null;
    private string CreateToken()
    {
        var now = clock.GetUtcNow();
        var header = AppleSignedDataVerifier.Encode(JsonSerializer.SerializeToUtf8Bytes(new { alg = "ES256", kid = options.KeyId, typ = "JWT" }));
        var payload = AppleSignedDataVerifier.Encode(JsonSerializer.SerializeToUtf8Bytes(new
        {
            iss = options.IssuerId, iat = now.ToUnixTimeSeconds(), exp = now.AddMinutes(5).ToUnixTimeSeconds(), aud = "appstoreconnect-v1", bid = options.BundleId
        }));
        using var key = ECDsa.Create();
        key.ImportFromPem(File.ReadAllText(options.PrivateKeyPath));
        if (key.KeySize != 256) throw new InvalidOperationException("Apple API signing key must use P-256.");
        var content = header + "." + payload;
        return content + "." + AppleSignedDataVerifier.Encode(key.SignData(Encoding.ASCII.GetBytes(content), HashAlgorithmName.SHA256,
            DSASignatureFormat.IeeeP1363FixedFieldConcatenation));
    }
}
