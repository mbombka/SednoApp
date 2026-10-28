using System.Net;
using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;
using System.Text;
using System.Text.Json;
using Sedno.Application;
using Sedno.Infrastructure;
using Xunit;

namespace Sedno.UnitTests;

public sealed class AppleBillingTests
{
    private static readonly DateTimeOffset Now = DateTimeOffset.Parse("2026-10-28T12:00:00Z");
    [Theory]
    [InlineData("active", false, true)]
    [InlineData("grace_period", false, true)]
    [InlineData("active", true, false)]
    [InlineData("expired", false, false)]
    [InlineData("billing_retry", false, false)]
    [InlineData("revoked", true, false)]
    public void OnlyPaidUnrevokedStatesGrantAccess(string state, bool revoked, bool expected)
    {
        var status = new AppleSubscription("1", "2", Guid.NewGuid().ToString(), state, Now.AddMinutes(1), Now, revoked);
        Assert.Equal(expected, status.Entitled(Now));
        Assert.False(status.Entitled(Now.AddMinutes(1)));
    }

    [Fact]
    public void AppleAccountBindingIsStableUuidAndDiffersFromGoogle()
    {
        var account = Guid.NewGuid();
        Assert.True(Guid.TryParse(AppleSubscriptionService.Binding(account), out _));
        Assert.Equal(AppleSubscriptionService.Binding(account), AppleSubscriptionService.Binding(account));
        Assert.NotEqual(AppleSubscriptionService.Binding(account), AppleSubscriptionService.Binding(Guid.NewGuid()));
        Assert.NotEqual(SubscriptionService.Binding(account), AppleSubscriptionService.Binding(account));
    }

    [Fact]
    public void AppleBillingIsDisabledByDefaultAndRejectsIncompleteOrLocalStoreKitConfig()
    {
        var options = new AppleBillingOptions();
        Assert.False(options.Enabled);
        options.Validate();
        options.Enabled = true;
        Assert.Throws<InvalidOperationException>(options.Validate);
        options.Environment = "Xcode";
        Assert.Throws<InvalidOperationException>(options.Validate);
    }

    [Theory]
    [InlineData(1, false, true)]
    [InlineData(4, false, true)]
    [InlineData(3, false, false)]
    [InlineData(5, false, false)]
    [InlineData(1, true, false)]
    public async Task ServerLooksUpCurrentSignedStoreStatus(int state, bool revoked, bool active)
    {
        using var fixture = new ClientFixture(state, revoked);
        var status = await fixture.Client.GetAsync("100", default);
        Assert.Equal(active, status.Entitled(Now));
        Assert.Equal(state == 4 ? Now.AddHours(1) : Now.AddDays(30), status.ExpiresAt);
        Assert.Equal("100", status.OriginalTransactionId);
        Assert.Equal(2, fixture.Signatures.Calls); // transaction and renewal verified independently
    }

    [Theory]
    [InlineData("bundleId", "attacker.app")]
    [InlineData("environment", "Sandbox")]
    [InlineData("appAccountToken", "not-a-uuid")]
    [InlineData("type", "Consumable")]
    public async Task RejectsTransactionFromWrongAppEnvironmentAccountOrType(string field, string value)
    {
        using var fixture = new ClientFixture(1, false);
        fixture.Signatures.Transaction[field] = value;
        await Assert.ThrowsAsync<InvalidOperationException>(() => fixture.Client.GetAsync("100", default));
    }

    [Fact]
    public async Task WrongProductNeverGrantsAccess()
    {
        using var fixture = new ClientFixture(1, false);
        fixture.Signatures.Transaction["productId"] = "unrelated";
        await Assert.ThrowsAsync<InvalidOperationException>(() => fixture.Client.GetAsync("100", default));
    }

    [Fact]
    public async Task UnsignedOrMismatchedRenewalCannotExtendGracePeriod()
    {
        using var fixture = new ClientFixture(4, false);
        fixture.Signatures.Renewal["originalTransactionId"] = "999";
        await Assert.ThrowsAsync<InvalidOperationException>(() => fixture.Client.GetAsync("100", default));
    }

    [Fact]
    public void NotificationsCheckSignatureVersionBundleAndEnvironment()
    {
        using var fixture = new ClientFixture(1, false);
        var notification = fixture.Client.VerifyNotification("notice");
        Assert.Equal("100", notification.OriginalTransactionId);
        fixture.Signatures.Notification["version"] = "1.0";
        Assert.Throws<InvalidOperationException>(() => fixture.Client.VerifyNotification("notice"));
    }

    [Theory]
    [InlineData("none")]
    [InlineData("HS256")]
    [InlineData("ES256")]
    public void SignedDataVerifierRejectsUnsignedOrUnchainedData(string algorithm)
    {
        using var key = ECDsa.Create(ECCurve.NamedCurves.nistP256);
        var request = new CertificateRequest("CN=Test Root", key, HashAlgorithmName.SHA256);
        request.CertificateExtensions.Add(new X509BasicConstraintsExtension(true, false, 0, true));
        using var root = request.CreateSelfSigned(Now.AddDays(-1), Now.AddDays(1));
        var path = Path.GetTempFileName();
        try
        {
            File.WriteAllBytes(path, root.RawData);
            using var verifier = new AppleSignedDataVerifier(new AppleBillingOptions { RootCertificatePaths = [path] }, new Clock());
            static string Encode(string text) => Convert.ToBase64String(Encoding.UTF8.GetBytes(text)).TrimEnd('=').Replace('+', '-').Replace('/', '_');
            var header = Encode(JsonSerializer.Serialize(new { alg = algorithm, x5c = Array.Empty<string>() }));
            var payload = Encode(JsonSerializer.Serialize(new { signedDate = Now.ToUnixTimeMilliseconds() }));
            Assert.Throws<InvalidOperationException>(() => verifier.Verify(header + "." + payload + ".AA"));
        }
        finally { File.Delete(path); }
    }

    private sealed class Clock : TimeProvider { public override DateTimeOffset GetUtcNow() => Now; }
    private sealed class Signatures : IAppleSignedDataVerifier
    {
        public int Calls;
        public Dictionary<string, object> Transaction = new()
        {
            ["bundleId"] = "xyz.sedno.app", ["environment"] = "Production", ["productId"] = "monthly",
            ["type"] = "Auto-Renewable Subscription", ["originalTransactionId"] = "100", ["transactionId"] = "101",
            ["appAccountToken"] = Guid.NewGuid().ToString(), ["expiresDate"] = Now.AddDays(30).ToUnixTimeMilliseconds(),
            ["signedDate"] = Now.ToUnixTimeMilliseconds()
        };
        public Dictionary<string, object> Renewal = new()
        {
            ["environment"] = "Production", ["productId"] = "monthly", ["originalTransactionId"] = "100",
            ["gracePeriodExpiresDate"] = Now.AddHours(1).ToUnixTimeMilliseconds()
        };
        public Dictionary<string, object> Notification = new()
        {
            ["version"] = "2.0", ["notificationUUID"] = Guid.NewGuid().ToString(), ["notificationType"] = "DID_RENEW",
            ["signedDate"] = Now.ToUnixTimeMilliseconds(),
            ["data"] = new { bundleId = "xyz.sedno.app", environment = "Production", appAppleId = 123, signedTransactionInfo = "transaction" }
        };
        public JsonElement Verify(string signedData)
        {
            Calls++;
            return JsonSerializer.SerializeToElement(signedData switch
            {
                "transaction" => Transaction, "renewal" => Renewal, "notice" => Notification,
                _ => throw new InvalidOperationException("Bad signature")
            });
        }
    }
    private sealed class ClientFixture : IDisposable
    {
        private readonly string _keyPath = Path.GetTempFileName();
        public readonly Signatures Signatures = new();
        public AppleBillingClient Client { get; }
        public ClientFixture(int status, bool revoked)
        {
            using var key = ECDsa.Create(ECCurve.NamedCurves.nistP256);
            File.WriteAllText(_keyPath, key.ExportPkcs8PrivateKeyPem());
            if (revoked) Signatures.Transaction["revocationDate"] = Now.ToUnixTimeMilliseconds();
            var http = new HttpClient(new Handler(status));
            Client = new(http, Signatures, new AppleBillingOptions
            {
                Enabled = true, ProductId = "monthly", AppAppleId = 123, IssuerId = "issuer", KeyId = "key", PrivateKeyPath = _keyPath
            }, new Clock());
        }
        public void Dispose() => File.Delete(_keyPath);
    }
    private sealed class Handler(int status) : HttpMessageHandler
    {
        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken ct)
        {
            Assert.Equal("https://api.storekit.apple.com/inApps/v1/subscriptions/100", request.RequestUri!.ToString());
            Assert.Equal("Bearer", request.Headers.Authorization!.Scheme);
            return Task.FromResult(new HttpResponseMessage(HttpStatusCode.OK)
            {
                Content = new StringContent(JsonSerializer.Serialize(new
                {
                    bundleId = "xyz.sedno.app", environment = "Production", appAppleId = 123,
                    data = new[] { new { lastTransactions = new[] { new { originalTransactionId = "100", status,
                        signedTransactionInfo = "transaction", signedRenewalInfo = "renewal" } } } }
                }))
            });
        }
    }
}
