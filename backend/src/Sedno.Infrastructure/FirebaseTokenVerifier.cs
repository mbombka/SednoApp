using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;
using System.Text;
using System.Text.Json;
using Sedno.Application;

namespace Sedno.Infrastructure;

/// <summary>Verifies Firebase ID tokens using Google's published X.509 signing keys.</summary>
public sealed class FirebaseTokenVerifier(HttpClient client, string projectId, TimeProvider clock) : IIdentityTokenVerifier
{
    private readonly SemaphoreSlim _refresh = new(1, 1);
    private Dictionary<string, X509Certificate2> _certificates = [];
    private DateTimeOffset _expiresAt;
    private const string CertificatesUrl = "https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com";

    public async Task<VerifiedIdentity?> VerifyAsync(string token, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(token) || token.Length > 8192) return null;
        var pieces = token.Split('.');
        if (pieces.Length != 3) return null;
        try
        {
            using var header = JsonDocument.Parse(Decode(pieces[0]));
            using var payload = JsonDocument.Parse(Decode(pieces[1]));
            var h = header.RootElement;
            var p = payload.RootElement;
            if (h.GetProperty("alg").GetString() != "RS256" ||
                h.GetProperty("kid").GetString() is not { Length: > 0 } kid ||
                p.GetProperty("aud").GetString() != projectId ||
                p.GetProperty("iss").GetString() != $"https://securetoken.google.com/{projectId}" ||
                p.GetProperty("sub").GetString() is not { Length: > 0 and <= 128 } uid)
                return null;
            var now = clock.GetUtcNow().ToUnixTimeSeconds();
            if (p.GetProperty("exp").GetInt64() <= now || p.GetProperty("iat").GetInt64() > now ||
                p.GetProperty("auth_time").GetInt64() > now) return null;
            var certs = await GetCertificatesAsync(ct);
            if (!certs.TryGetValue(kid, out var certificate)) return null;
            using var rsa = certificate.GetRSAPublicKey();
            if (rsa is null || !rsa.VerifyData(Encoding.ASCII.GetBytes(pieces[0] + "." + pieces[1]),
                Decode(pieces[2]), HashAlgorithmName.SHA256, RSASignaturePadding.Pkcs1)) return null;
            var provider = p.GetProperty("firebase").GetProperty("sign_in_provider").GetString() switch
            {
                "google.com" => "google", "password" => "email", _ => null
            };
            return provider is null ? null : new(uid, provider,
                p.TryGetProperty("email_verified", out var emailVerified) && emailVerified.ValueKind == JsonValueKind.True);
        }
        catch (Exception ex) when (ex is JsonException or KeyNotFoundException or FormatException or
            InvalidOperationException or ArgumentException or CryptographicException or HttpRequestException)
        { return null; }
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
