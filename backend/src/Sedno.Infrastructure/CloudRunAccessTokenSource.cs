using System.Text.Json;

namespace Sedno.Infrastructure;

/// <summary>Short-lived credentials of the attached Cloud Run service account; never reads key files.</summary>
public sealed class CloudRunAccessTokenSource(HttpClient client, TimeProvider clock,
    string scope = "https://www.googleapis.com/auth/playintegrity") : IPlayAccessTokenSource
{
    private readonly SemaphoreSlim _refresh = new(1, 1);
    private string? _token;
    private DateTimeOffset _refreshAt;

    public async Task<string> GetAsync(CancellationToken ct)
    {
        if (_token is not null && clock.GetUtcNow() < _refreshAt) return _token;
        await _refresh.WaitAsync(ct);
        try
        {
            if (_token is not null && clock.GetUtcNow() < _refreshAt) return _token;
            using var request = new HttpRequestMessage(HttpMethod.Get,
                "http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token?scopes=" + Uri.EscapeDataString(scope));
            request.Headers.Add("Metadata-Flavor", "Google");
            using var response = await client.SendAsync(request, HttpCompletionOption.ResponseHeadersRead, ct);
            if (!response.IsSuccessStatusCode || !response.Headers.TryGetValues("Metadata-Flavor", out var flavors) ||
                !flavors.Contains("Google", StringComparer.Ordinal)) throw Unavailable();
            await using var stream = await response.Content.ReadAsStreamAsync(ct);
            var bytes = new byte[16 * 1024 + 1];
            var length = 0;
            while (length < bytes.Length)
            {
                var count = await stream.ReadAsync(bytes.AsMemory(length), ct);
                if (count == 0) break;
                length += count;
            }
            if (length == bytes.Length) throw Unavailable();
            using var doc = JsonDocument.Parse(bytes.AsMemory(0, length));
            var root = doc.RootElement;
            var token = root.GetProperty("access_token").GetString();
            var seconds = root.GetProperty("expires_in").GetInt32();
            if (string.IsNullOrWhiteSpace(token) || seconds is <= 60 or > 86400 ||
                root.GetProperty("token_type").GetString() != "Bearer") throw Unavailable();
            _token = token;
            _refreshAt = clock.GetUtcNow().AddSeconds(seconds - 60);
            return token;
        }
        catch (Exception ex) when (ex is HttpRequestException or JsonException or KeyNotFoundException or
            InvalidOperationException or FormatException or IOException)
        { throw Unavailable(); }
        finally { _refresh.Release(); }
    }

    private static InvalidOperationException Unavailable() => new("Google service identity is unavailable.");
}
