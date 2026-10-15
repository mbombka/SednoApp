using System.Net;
using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;
using System.Text;
using System.Text.Json;
using Sedno.Infrastructure;
using Xunit;

namespace Sedno.UnitTests;

public sealed class PushAuthenticationTests
{
    private sealed class Clock : TimeProvider
    {
        public override DateTimeOffset GetUtcNow() => DateTimeOffset.Parse("2026-10-15T12:00:00Z");
    }
    private sealed class Certificates(string pem) : HttpMessageHandler
    {
        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken ct)
        {
            Assert.Equal("https://www.googleapis.com/oauth2/v1/certs", request.RequestUri!.ToString());
            return Task.FromResult(new HttpResponseMessage(HttpStatusCode.OK) { Content = new StringContent(JsonSerializer.Serialize(new { key = pem })) });
        }
    }
    [Fact]
    public async Task PushRequiresGoogleSignatureAudienceIssuerAndVerifiedEmail()
    {
        using var rsa = RSA.Create(2048);
        using var certificate = new CertificateRequest("CN=test", rsa, HashAlgorithmName.SHA256, RSASignaturePadding.Pkcs1)
            .CreateSelfSigned(DateTimeOffset.UtcNow.AddDays(-1), DateTimeOffset.UtcNow.AddDays(1));
        using var client = new HttpClient(new Certificates(certificate.ExportCertificatePem()));
        var clock = new Clock();
        var verifier = new PubSubTokenVerifier(client, "https://api/push", "push@test.invalid", clock);
        var now = clock.GetUtcNow().ToUnixTimeSeconds();
        string Token(string audience = "https://api/push", string email = "push@test.invalid", bool verified = true,
            string issuer = "https://accounts.google.com", long? expiry = null, RSA? signer = null)
        {
            static string B64(byte[] value) => Convert.ToBase64String(value).TrimEnd('=').Replace('+', '-').Replace('/', '_');
            var header = B64(JsonSerializer.SerializeToUtf8Bytes(new { alg = "RS256", kid = "key" }));
            var payload = B64(JsonSerializer.SerializeToUtf8Bytes(new { aud = audience, iss = issuer, sub = "service-account", email,
                email_verified = verified, iat = now - 10, exp = expiry ?? now + 600 }));
            var text = header + "." + payload;
            return text + "." + B64((signer ?? rsa).SignData(Encoding.ASCII.GetBytes(text), HashAlgorithmName.SHA256, RSASignaturePadding.Pkcs1));
        }
        Assert.True(await verifier.VerifyAsync(Token(), default));
        Assert.False(await verifier.VerifyAsync(Token(audience: "wrong"), default));
        Assert.False(await verifier.VerifyAsync(Token(email: "attacker@test.invalid"), default));
        Assert.False(await verifier.VerifyAsync(Token(verified: false), default));
        Assert.False(await verifier.VerifyAsync(Token(issuer: "attacker"), default));
        Assert.False(await verifier.VerifyAsync(Token(expiry: now), default));
        using var attacker = RSA.Create(2048);
        Assert.False(await verifier.VerifyAsync(Token(signer: attacker), default));
        Assert.False(await verifier.VerifyAsync("malformed", default));
    }
}
