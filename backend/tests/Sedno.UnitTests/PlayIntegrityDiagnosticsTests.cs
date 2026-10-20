using System.Net;
using System.Text.Json.Nodes;
using Microsoft.Extensions.Logging;
using Sedno.Infrastructure;
using Xunit;

namespace Sedno.UnitTests;

public sealed class PlayIntegrityDiagnosticsTests
{
    private const string Secret = "sensitive-token-or-response";
    private sealed class Clock : TimeProvider
    {
        public override DateTimeOffset GetUtcNow() => DateTimeOffset.FromUnixTimeMilliseconds(1791979200000);
    }
    private sealed class AccessTokens : IPlayAccessTokenSource
    {
        public Task<string> GetAsync(CancellationToken ct) => Task.FromResult(Secret);
    }
    private sealed class Handler(Func<HttpResponseMessage> response) : HttpMessageHandler
    {
        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken ct) =>
            Task.FromResult(response());
    }
    private sealed class Logger : ILogger<PlayIntegrityVerifier>
    {
        public List<(EventId Event, Dictionary<string, object?> Fields, string Message)> Entries { get; } = [];
        public IDisposable? BeginScope<TState>(TState state) where TState : notnull => null;
        public bool IsEnabled(LogLevel level) => true;
        public void Log<TState>(LogLevel level, EventId eventId, TState state, Exception? exception,
            Func<TState, Exception?, string> formatter)
        {
            Assert.Equal(LogLevel.Warning, level);
            Assert.Null(exception);
            Entries.Add((eventId, ((IEnumerable<KeyValuePair<string, object?>>)(object)state!).ToDictionary(), formatter(state, exception)));
        }
    }

    [Theory]
    [InlineData("missing_token")]
    [InlineData("token_too_long")]
    [InlineData("decode_http_error")]
    [InlineData("token_from_future")]
    [InlineData("token_expired")]
    [InlineData("package_mismatch")]
    [InlineData("request_hash_mismatch")]
    [InlineData("app_not_recognized")]
    [InlineData("device_not_trusted")]
    [InlineData("invalid_response")]
    [InlineData("transport_error")]
    [InlineData("io_error")]
    public async Task RejectionLogsOnlyReasonAndNumericMetadata(string reason)
    {
        var payload = JsonNode.Parse("""
            {"tokenPayloadExternal":{
              "requestDetails":{"timestampMillis":"1791979200000","requestPackageName":"xyz.sedno.app","requestHash":"expected"},
              "appIntegrity":{"appRecognitionVerdict":"PLAY_RECOGNIZED"},
              "deviceIntegrity":{"deviceRecognitionVerdict":["MEETS_DEVICE_INTEGRITY"]}}}
            """)!;
        var verdict = payload["tokenPayloadExternal"]!;
        var details = verdict["requestDetails"]!;
        switch (reason)
        {
            case "token_from_future": details["timestampMillis"] = "1791979205001"; break;
            case "token_expired": details["timestampMillis"] = "1791978899000"; break;
            case "package_mismatch": details["requestPackageName"] = Secret; break;
            case "request_hash_mismatch": details["requestHash"] = Secret; break;
            case "app_not_recognized": verdict["appIntegrity"]!["appRecognitionVerdict"] = Secret; break;
            case "device_not_trusted": verdict["deviceIntegrity"]!["deviceRecognitionVerdict"] = new JsonArray(Secret); break;
        }
        using var client = new HttpClient(new Handler(() => reason switch
        {
            "transport_error" => throw new HttpRequestException(Secret),
            "io_error" => throw new IOException(Secret),
            _ => new HttpResponseMessage(reason == "decode_http_error" ? HttpStatusCode.Forbidden : HttpStatusCode.OK)
            {
                Content = new StringContent(reason == "invalid_response" ? Secret : payload.ToJsonString())
            }
        }));
        var logger = new Logger();
        var verifier = new PlayIntegrityVerifier(client, new AccessTokens(), "xyz.sedno.app", new Clock(), logger);
        var token = reason switch { "missing_token" => null, "token_too_long" => new string('x', 8193), _ => Secret };
        Assert.False(await verifier.VerifyAsync(token, "expected", default));
        var entry = Assert.Single(logger.Entries);
        Assert.Equal("PlayIntegrityRejected", entry.Event.Name);
        Assert.Equal(reason, entry.Fields["Reason"]);
        Assert.Equal(new[] { "HttpStatus", "Reason", "TokenAgeSeconds", "{OriginalFormat}" }, entry.Fields.Keys.Order(StringComparer.Ordinal).ToArray());
        Assert.DoesNotContain(Secret, entry.Message);
        if (reason == "decode_http_error") Assert.Equal(403, entry.Fields["HttpStatus"]);
        if (reason == "token_from_future") Assert.Equal(-5.001d, entry.Fields["TokenAgeSeconds"]);
        if (reason == "token_expired") Assert.Equal(301d, entry.Fields["TokenAgeSeconds"]);
    }

    [Theory]
    [InlineData(-605, true)]
    [InlineData(-253, true)]
    [InlineData(-5000, true)]
    [InlineData(-5001, false)]
    [InlineData(0, true)]
    [InlineData(300000, true)]
    [InlineData(300001, false)]
    public async Task TokenAgeAllowsSmallClockSkewWithoutExtendingMaximumAge(long ageMilliseconds, bool accepted)
    {
        var timestamp = (1791979200000 - ageMilliseconds).ToString(System.Globalization.CultureInfo.InvariantCulture);
        var payload = System.Text.Json.JsonSerializer.Serialize(new
        {
            tokenPayloadExternal = new
            {
                requestDetails = new { timestampMillis = timestamp, requestPackageName = "xyz.sedno.app", requestHash = "expected" },
                appIntegrity = new { appRecognitionVerdict = "PLAY_RECOGNIZED" },
                deviceIntegrity = new { deviceRecognitionVerdict = new[] { "MEETS_DEVICE_INTEGRITY" } }
            }
        });
        using var client = new HttpClient(new Handler(() => new HttpResponseMessage(HttpStatusCode.OK)
            { Content = new StringContent(payload) }));
        var logger = new Logger();
        var verifier = new PlayIntegrityVerifier(client, new AccessTokens(), "xyz.sedno.app", new Clock(), logger);
        Assert.Equal(accepted, await verifier.VerifyAsync(Secret, "expected", default));
        if (accepted)
        {
            Assert.Empty(logger.Entries);
            // Clock tolerance must not bypass verification of request binding.
            Assert.False(await verifier.VerifyAsync(Secret, "wrong-hash", default));
            Assert.Equal("request_hash_mismatch", Assert.Single(logger.Entries).Fields["Reason"]);
        }
        else
        {
            Assert.Equal(ageMilliseconds < 0 ? "token_from_future" : "token_expired",
                Assert.Single(logger.Entries).Fields["Reason"]);
        }
    }

    [Fact]
    public async Task CancellationPropagatesWithoutMisreportingInvalidVerdict()
    {
        using var client = new HttpClient(new Handler(() => throw new OperationCanceledException(Secret)));
        var logger = new Logger();
        var verifier = new PlayIntegrityVerifier(client, new AccessTokens(), "xyz.sedno.app", new Clock(), logger);
        await Assert.ThrowsAnyAsync<OperationCanceledException>(() => verifier.VerifyAsync(Secret, "expected", default));
        Assert.Empty(logger.Entries);
    }
}
