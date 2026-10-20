using System.Net;
using System.Net.Http;
using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;
using System.Text;
using System.Text.Json;
using Sedno.Infrastructure;
using Xunit;

namespace Sedno.UnitTests;

public sealed class AuthenticationTests
{
    private sealed class Clock : TimeProvider
    {
        public override DateTimeOffset GetUtcNow() => new(2026, 10, 14, 12, 0, 0, TimeSpan.Zero);
    }

    private sealed class Handler(Func<HttpRequestMessage, HttpResponseMessage> respond) : HttpMessageHandler
    {
        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken ct) =>
            Task.FromResult(respond(request));
    }

    private sealed class AccessTokens : IPlayAccessTokenSource
    {
        public Task<string> GetAsync(CancellationToken ct) => Task.FromResult("test-access-token");
    }

    [Fact]
    public async Task FirebaseRejectsExpiredAndForgedTokens()
    {
        using var rsa = RSA.Create(2048);
        var certificateRequest = new CertificateRequest("CN=test", rsa, HashAlgorithmName.SHA256, RSASignaturePadding.Pkcs1);
        using var certificate = certificateRequest.CreateSelfSigned(DateTimeOffset.UtcNow.AddDays(-1), DateTimeOffset.UtcNow.AddDays(1));
        var pem = certificate.ExportCertificatePem();
        using var client = new HttpClient(new Handler(_ => new(HttpStatusCode.OK)
        {
            Content = new StringContent(JsonSerializer.Serialize(new Dictionary<string, string> { ["test-key"] = pem }))
        }));
        var verifier = new FirebaseTokenVerifier(client, "test-project", new Clock());
        var valid = Token(rsa, 1791982800); // 2026-10-14 13:00 UTC
        Assert.Equal("google", (await verifier.VerifyAsync(valid, default))?.Provider);
        Assert.Null(await verifier.VerifyAsync(Token(rsa, 1791975600), default)); // expired
        using var attacker = RSA.Create(2048);
        Assert.Null(await verifier.VerifyAsync(Token(attacker, 1791982800), default));
        Assert.Null(await verifier.VerifyAsync(valid + "x", default));
    }

    [Theory]
    [InlineData(true, true)]
    [InlineData(false, false)]
    [InlineData(null, false)]
    public async Task PasswordTokenVerificationUsesSignedEmailClaim(bool? claim, bool expected)
    {
        using var rsa = RSA.Create(2048);
        var request = new CertificateRequest("CN=test", rsa, HashAlgorithmName.SHA256, RSASignaturePadding.Pkcs1);
        using var certificate = request.CreateSelfSigned(DateTimeOffset.UtcNow.AddDays(-1), DateTimeOffset.UtcNow.AddDays(1));
        using var client = new HttpClient(new Handler(_ => new(HttpStatusCode.OK)
        {
            Content = new StringContent(JsonSerializer.Serialize(new Dictionary<string, string> { ["test-key"] = certificate.ExportCertificatePem() }))
        }));
        var verifier = new FirebaseTokenVerifier(client, "test-project", new Clock());
        var identity = await verifier.VerifyAsync(Token(rsa, 1791982800, "password", claim), default);
        Assert.NotNull(identity);
        Assert.Equal("email", identity.Provider);
        Assert.Equal(expected, identity.EmailVerified);
    }

    [Fact]
    public async Task IntegrityRejectsMissingStaleAndMismatchedVerdicts()
    {
        var expected = PlayIntegrityVerifier.RequestHash("installation-1");
        Assert.NotEqual(expected, PlayIntegrityVerifier.RequestHash("installation-2"));
        var payload = Verdict(expected, "1791979200000", "PLAY_RECOGNIZED");
        using var validClient = new HttpClient(new Handler(_ => new(HttpStatusCode.OK) { Content = new StringContent(payload) }));
        var verifier = new PlayIntegrityVerifier(validClient, new AccessTokens(), "com.example.app", new Clock());
        Assert.True(await verifier.VerifyAsync("token", expected, default));
        Assert.False(await verifier.VerifyAsync(null, expected, default));
        Assert.False(await verifier.VerifyAsync("token", "wrong", default));
        using var staleClient = new HttpClient(new Handler(_ => new(HttpStatusCode.OK)
        {
            Content = new StringContent(Verdict(expected, "1791978600000", "PLAY_RECOGNIZED"))
        }));
        Assert.False(await new PlayIntegrityVerifier(staleClient, new AccessTokens(), "com.example.app", new Clock())
            .VerifyAsync("token", expected, default));
        using var unrecognizedClient = new HttpClient(new Handler(_ => new(HttpStatusCode.OK)
        {
            Content = new StringContent(Verdict(expected, "1791979200000", "UNRECOGNIZED_VERSION"))
        }));
        Assert.False(await new PlayIntegrityVerifier(unrecognizedClient, new AccessTokens(), "com.example.app", new Clock())
            .VerifyAsync("token", expected, default));
        using var compromisedClient = new HttpClient(new Handler(_ => new(HttpStatusCode.OK)
        {
            Content = new StringContent(Verdict(expected, "1791979200000", "PLAY_RECOGNIZED", deviceTrusted: false))
        }));
        Assert.False(await new PlayIntegrityVerifier(compromisedClient, new AccessTokens(), "com.example.app", new Clock())
            .VerifyAsync("token", expected, default));
    }

    private static string Verdict(string hash, string timestamp, string recognition, bool deviceTrusted = true) => JsonSerializer.Serialize(new
    {
        tokenPayloadExternal = new
        {
            requestDetails = new { requestPackageName = "com.example.app", requestHash = hash, timestampMillis = timestamp },
            appIntegrity = new { appRecognitionVerdict = recognition },
            deviceIntegrity = new { deviceRecognitionVerdict = deviceTrusted ? new[] { "MEETS_DEVICE_INTEGRITY" } : [] }
        }
    });

    private static string Token(RSA rsa, long expiry, string provider = "google.com", bool? emailVerified = null)
    {
        static string Encode(byte[] bytes) => Convert.ToBase64String(bytes).TrimEnd('=').Replace('+', '-').Replace('/', '_');
        var header = Encode(JsonSerializer.SerializeToUtf8Bytes(new { alg = "RS256", kid = "test-key" }));
        var payload = Encode(JsonSerializer.SerializeToUtf8Bytes(new
        {
            aud = "test-project", iss = "https://securetoken.google.com/test-project", sub = "user-1",
            exp = expiry, iat = 1791975600, auth_time = 1791975600,
            email_verified = emailVerified,
            firebase = new { sign_in_provider = provider }
        }));
        var value = header + "." + payload;
        return value + "." + Encode(rsa.SignData(Encoding.ASCII.GetBytes(value), HashAlgorithmName.SHA256, RSASignaturePadding.Pkcs1));
    }
}
