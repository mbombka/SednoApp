using System.Net;
using Sedno.Infrastructure;
using Xunit;

namespace Sedno.UnitTests;

public sealed class CloudRunAccessTokenTests
{
    private sealed class Clock : TimeProvider
    {
        public DateTimeOffset Now = new(2026, 10, 16, 12, 0, 0, TimeSpan.Zero);
        public override DateTimeOffset GetUtcNow() => Now;
    }
    private sealed class Handler(Func<HttpRequestMessage, CancellationToken, Task<HttpResponseMessage>> action) : HttpMessageHandler
    {
        public int Calls;
        protected override Task<HttpResponseMessage> SendAsync(HttpRequestMessage request, CancellationToken ct)
        {
            Calls++;
            return action(request, ct);
        }
    }
    private static HttpResponseMessage Response(string body, bool flavor = true, HttpStatusCode status = HttpStatusCode.OK)
    {
        var response = new HttpResponseMessage(status) { Content = new StringContent(body) };
        if (flavor) response.Headers.Add("Metadata-Flavor", "Google");
        return response;
    }
    private const string Valid = """{"access_token":"synthetic-token","expires_in":3600,"token_type":"Bearer"}""";

    [Fact]
    public async Task UsesOnlyMetadataEndpointAndRefreshesUsingInjectedTime()
    {
        var clock = new Clock();
        var handler = new Handler((request, _) =>
        {
            Assert.Equal(HttpMethod.Get, request.Method);
            Assert.Equal("http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token?scopes=https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fplayintegrity", request.RequestUri!.AbsoluteUri);
            Assert.Equal("Google", Assert.Single(request.Headers.GetValues("Metadata-Flavor")));
            Assert.Null(request.Headers.Authorization);
            return Task.FromResult(Response(Valid));
        });
        using var client = new HttpClient(handler);
        var source = new CloudRunAccessTokenSource(client, clock);
        var tokens = await Task.WhenAll(Enumerable.Range(0, 8).Select(_ => source.GetAsync(default)));
        Assert.All(tokens, value => Assert.Equal("synthetic-token", value));
        Assert.Equal(1, handler.Calls);
        clock.Now = clock.Now.AddSeconds(3540);
        await source.GetAsync(default);
        Assert.Equal(2, handler.Calls);
    }

    [Theory]
    [InlineData("https://www.googleapis.com/auth/playintegrity")]
    [InlineData("https://www.googleapis.com/auth/identitytoolkit")]
    [InlineData("https://www.googleapis.com/auth/androidpublisher")]
    public async Task RequestsTheScopeRequiredByEachGoogleApi(string scope)
    {
        using var client = new HttpClient(new Handler((request, _) =>
        {
            Assert.Equal(scope, Uri.UnescapeDataString(request.RequestUri!.Query["?scopes=".Length..]));
            return Task.FromResult(Response(Valid));
        }));
        Assert.Equal("synthetic-token", await new CloudRunAccessTokenSource(client, new Clock(), scope).GetAsync(default));
    }

    [Theory]
    [InlineData("not json", true)]
    [InlineData("{}", true)]
    [InlineData(Valid, false)]
    [InlineData("{\"access_token\":\"secret\",\"expires_in\":0,\"token_type\":\"Bearer\"}", true)]
    [InlineData("{\"access_token\":\"secret\",\"expires_in\":3600,\"token_type\":\"other\"}", true)]
    public async Task RejectsUntrustedAndMalformedResponsesWithoutLeakingContent(string body, bool flavor)
    {
        using var client = new HttpClient(new Handler((_, _) => Task.FromResult(Response(body, flavor))));
        var error = await Assert.ThrowsAsync<InvalidOperationException>(() => new CloudRunAccessTokenSource(client, new Clock()).GetAsync(default));
        Assert.Equal("Google service identity is unavailable.", error.Message);
        Assert.Null(error.InnerException);
    }

    [Fact]
    public async Task RejectsOversizedAndFailedMetadataWithoutRetry()
    {
        var handler = new Handler((_, _) => Task.FromResult(Response(new string('x', 17000))));
        using var client = new HttpClient(handler);
        await Assert.ThrowsAsync<InvalidOperationException>(() => new CloudRunAccessTokenSource(client, new Clock()).GetAsync(default));
        Assert.Equal(1, handler.Calls);
        using var failed = new HttpClient(new Handler((_, _) => Task.FromResult(Response("secret", status: HttpStatusCode.Forbidden))));
        await Assert.ThrowsAsync<InvalidOperationException>(() => new CloudRunAccessTokenSource(failed, new Clock()).GetAsync(default));
    }

    [Fact]
    public async Task CancellationPropagates()
    {
        using var cancellation = new CancellationTokenSource();
        using var client = new HttpClient(new Handler(async (_, ct) =>
        {
            cancellation.Cancel();
            await Task.Delay(Timeout.Infinite, ct);
            return Response(Valid);
        }));
        await Assert.ThrowsAnyAsync<OperationCanceledException>(() => new CloudRunAccessTokenSource(client, new Clock()).GetAsync(cancellation.Token));
    }
}
