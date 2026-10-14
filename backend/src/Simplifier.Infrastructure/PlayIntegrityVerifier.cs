using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using Simplifier.Application;

namespace Simplifier.Infrastructure;

public sealed class DevelopmentIntegrityVerifier : IIntegrityVerifier
{
    public Task<bool> VerifyAsync(string? token, string requestHash, CancellationToken ct) => Task.FromResult(true);
}

public interface IPlayAccessTokenSource
{
    Task<string> GetAsync(CancellationToken ct);
}

public sealed class ServiceAccountAccessTokenSource(HttpClient client, string credentialsPath, TimeProvider clock) : IPlayAccessTokenSource
{
    private readonly SemaphoreSlim _refresh = new(1, 1);
    private string? _accessToken;
    private DateTimeOffset _expiresAt;

    public async Task<string> GetAsync(CancellationToken ct)
    {
        if (_accessToken is not null && clock.GetUtcNow() < _expiresAt) return _accessToken;
        await _refresh.WaitAsync(ct);
        try
        {
            if (_accessToken is not null && clock.GetUtcNow() < _expiresAt) return _accessToken;
            using var doc = JsonDocument.Parse(await File.ReadAllTextAsync(credentialsPath, ct));
            var root = doc.RootElement;
            if (root.GetProperty("type").GetString() != "service_account")
                throw new InvalidOperationException("A Google service account is required.");
            var email = root.GetProperty("client_email").GetString()!;
            var key = root.GetProperty("private_key").GetString()!;
            var now = clock.GetUtcNow().ToUnixTimeSeconds();
            var header = Encode(JsonSerializer.SerializeToUtf8Bytes(new { alg = "RS256", typ = "JWT" }));
            var claims = Encode(JsonSerializer.SerializeToUtf8Bytes(new
            {
                iss = email, scope = "https://www.googleapis.com/auth/playintegrity",
                aud = "https://oauth2.googleapis.com/token", iat = now, exp = now + 3600
            }));
            using var rsa = RSA.Create();
            rsa.ImportFromPem(key);
            var assertion = header + "." + claims;
            assertion += "." + Encode(rsa.SignData(Encoding.ASCII.GetBytes(assertion),
                HashAlgorithmName.SHA256, RSASignaturePadding.Pkcs1));
            using var response = await client.PostAsync("https://oauth2.googleapis.com/token",
                new FormUrlEncodedContent(new Dictionary<string, string>
                {
                    ["grant_type"] = "urn:ietf:params:oauth:grant-type:jwt-bearer", ["assertion"] = assertion
                }), ct);
            response.EnsureSuccessStatusCode();
            using var result = JsonDocument.Parse(await response.Content.ReadAsStringAsync(ct));
            _accessToken = result.RootElement.GetProperty("access_token").GetString()!;
            _expiresAt = clock.GetUtcNow().AddSeconds(result.RootElement.GetProperty("expires_in").GetInt32() - 60);
            return _accessToken;
        }
        finally { _refresh.Release(); }
    }

    private static string Encode(byte[] bytes) => Convert.ToBase64String(bytes).TrimEnd('=').Replace('+', '-').Replace('/', '_');
}

public sealed class PlayIntegrityVerifier(HttpClient client, IPlayAccessTokenSource accessTokens,
    string packageName, TimeProvider clock) : IIntegrityVerifier
{
    public async Task<bool> VerifyAsync(string? token, string requestHash, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(token) || token.Length > 8192) return false;
        try
        {
            using var request = new HttpRequestMessage(HttpMethod.Post,
                $"https://playintegrity.googleapis.com/v1/{Uri.EscapeDataString(packageName)}:decodeIntegrityToken");
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", await accessTokens.GetAsync(ct));
            request.Content = JsonContent.Create(new { integrityToken = token });
            using var response = await client.SendAsync(request, ct);
            if (!response.IsSuccessStatusCode) return false;
            using var doc = JsonDocument.Parse(await response.Content.ReadAsStringAsync(ct));
            var verdict = doc.RootElement.GetProperty("tokenPayloadExternal");
            var details = verdict.GetProperty("requestDetails");
            var issued = DateTimeOffset.FromUnixTimeMilliseconds(long.Parse(details.GetProperty("timestampMillis").GetString()!));
            var age = clock.GetUtcNow() - issued;
            if (age < TimeSpan.Zero || age > TimeSpan.FromMinutes(5) ||
                details.GetProperty("requestPackageName").GetString() != packageName ||
                details.GetProperty("requestHash").GetString() != requestHash ||
                verdict.GetProperty("appIntegrity").GetProperty("appRecognitionVerdict").GetString() != "PLAY_RECOGNIZED")
                return false;
            return verdict.GetProperty("deviceIntegrity").GetProperty("deviceRecognitionVerdict")
                .EnumerateArray().Any(x => x.GetString() == "MEETS_DEVICE_INTEGRITY");
        }
        catch (Exception ex) when (ex is HttpRequestException or JsonException or KeyNotFoundException or
            InvalidOperationException or FormatException or ArgumentException or IOException)
        { return false; }
    }

    public static string RequestHash(string installationId)
    {
        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes("guest-session:" + installationId));
        return Convert.ToBase64String(bytes).TrimEnd('=').Replace('+', '-').Replace('/', '_');
    }
}
