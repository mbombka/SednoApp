using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;
using System.Text;
using System.Text.Json;
using Sedno.Application;

namespace Sedno.Infrastructure;

/// <summary>Verifies the OIDC identity of an authenticated Pub/Sub push.</summary>
public sealed class PubSubTokenVerifier(HttpClient client, string audience, string serviceAccountEmail, TimeProvider clock) : INotificationVerifier
{
    private readonly SemaphoreSlim _refresh = new(1, 1);
    private Dictionary<string, X509Certificate2> _certificates = [];
    private DateTimeOffset _expiresAt;
    private const string CertificatesUrl = "https://www.googleapis.com/oauth2/v1/certs";

    public async Task<bool> VerifyAsync(string token, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(token) || token.Length > 8192) return false;
        var pieces = token.Split('.');
        if (pieces.Length != 3) return false;
        try
        {
            using var header = JsonDocument.Parse(Decode(pieces[0]));
            using var payload = JsonDocument.Parse(Decode(pieces[1]));
            var h = header.RootElement;
            var p = payload.RootElement;
            if (h.GetProperty("alg").GetString() != "RS256" ||
                h.GetProperty("kid").GetString() is not { Length: > 0 } kid ||
                p.GetProperty("aud").GetString() != audience ||
                p.GetProperty("iss").GetString() is not ("https://accounts.google.com" or "accounts.google.com") ||
                p.GetProperty("sub").GetString() is not { Length: > 0 and <= 128 } uid)
                return false;
            var now = clock.GetUtcNow().ToUnixTimeSeconds();
            if (p.GetProperty("exp").GetInt64() <= now || p.GetProperty("iat").GetInt64() > now) return false;
            var certs = await GetCertificatesAsync(ct);
            if (!certs.TryGetValue(kid, out var certificate)) return false;
            using var rsa = certificate.GetRSAPublicKey();
            if (rsa is null || !rsa.VerifyData(Encoding.ASCII.GetBytes(pieces[0] + "." + pieces[1]),
                Decode(pieces[2]), HashAlgorithmName.SHA256, RSASignaturePadding.Pkcs1)) return false;
            return p.GetProperty("email_verified").GetBoolean() &&
                p.GetProperty("email").GetString() == serviceAccountEmail;
        }
        catch (Exception ex) when (ex is JsonException or KeyNotFoundException or FormatException or
            InvalidOperationException or ArgumentException or CryptographicException or HttpRequestException)
        { return false; }
    }

    private async Task<Dictionary<string, X509Certificate2>> GetCertificatesAsync(CancellationToken ct)
    {
        if (_expiresAt > clock.GetUtcNow()) return _certificates;
        await _refresh.WaitAsync(ct);
        try
        {
            if (_expiresAt > clock.GetUtcNow()) return _certificates;
            using var response = await client.GetAsync(CertificatesUrl, ct);
            response.EnsureSuccessStatusCode();
            using var doc = JsonDocument.Parse(await response.Content.ReadAsStringAsync(ct));
            var certificates = new Dictionary<string, X509Certificate2>();
            foreach (var property in doc.RootElement.EnumerateObject())
                certificates.Add(property.Name, X509Certificate2.CreateFromPem(property.Value.GetString()!));
            if (certificates.Count == 0) throw new InvalidOperationException("No signing certificates.");
            _certificates = certificates;
            _expiresAt = clock.GetUtcNow().Add(response.Headers.CacheControl?.MaxAge ?? TimeSpan.FromMinutes(5));
            return _certificates;
        }
        finally { _refresh.Release(); }
    }

    private static byte[] Decode(string text)
    {
        var padded = text.Replace('-', '+').Replace('_', '/');
        return Convert.FromBase64String(padded.PadRight((padded.Length + 3) / 4 * 4, '='));
    }
}
