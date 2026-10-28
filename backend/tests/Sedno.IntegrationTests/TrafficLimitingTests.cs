using System.Net;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.Configuration;
using Sedno.Application;
using Xunit;

namespace Sedno.IntegrationTests;

public sealed class TrafficLimitingTests
{
    private static async Task<WebApplication> Start(bool cloud = true)
    {
        var builder = WebApplication.CreateBuilder();
        builder.WebHost.UseTestServer();
        builder.Services.AddTrafficLimiting(new ConfigurationBuilder().AddInMemoryCollection(new Dictionary<string, string?>
        {
            ["RateLimiting:PermitLimit"] = "2", ["RateLimiting:NotificationPermitLimit"] = "3"
        }).Build(), cloud);
        var app = builder.Build();
        app.Use(async (context, next) =>
        {
            context.Connection.RemoteIpAddress = IPAddress.Parse("169.254.1.1");
            await next(context);
        });
        app.UseRateLimiter();
        app.MapGet("/v1/quota", () => Results.Unauthorized());
        app.MapPost("/notifications/google-play", (HttpContext context) =>
            // Signature verification remains in the real endpoint; this harness has no credentials.
            Results.Unauthorized()).WithMetadata(new NotificationTraffic());
        app.MapPost("/notifications/apple", () => Results.BadRequest()).WithMetadata(new NotificationTraffic("apple"));
        await app.StartAsync();
        return app;
    }

    private static async Task<HttpStatusCode> Send(HttpClient client, string peer, string prefix = "203.0.113.1", bool notification = false)
    {
        using var request = new HttpRequestMessage(notification ? HttpMethod.Post : HttpMethod.Get,
            notification ? "/notifications/google-play" : "/v1/quota");
        request.Headers.Add("X-Forwarded-For", $"{prefix}, {peer}");
        request.Headers.Add("Fastly-Client-IP", prefix);
        request.Headers.Add("X-Forwarded-Host", "sednoapp-79241-api.web.app");
        request.Headers.TryAddWithoutValidation("Authorization", "Bearer " + prefix);
        using var response = await client.SendAsync(request);
        return response.StatusCode;
    }

    [Fact]
    public async Task DirectCloudRunPeersAreIsolatedAndForgedHeadersDoNotResetCounters()
    {
        await using var app = await Start();
        using var client = app.GetTestClient();
        Assert.Equal(HttpStatusCode.Unauthorized, await Send(client, "198.51.100.1"));
        Assert.Equal(HttpStatusCode.Unauthorized, await Send(client, "198.51.100.1", "garbage, 203.0.113.9"));
        Assert.Equal(HttpStatusCode.TooManyRequests, await Send(client, "198.51.100.1", "203.0.113.77"));
        Assert.Equal(HttpStatusCode.Unauthorized, await Send(client, "198.51.100.2"));
    }

    [Fact]
    public async Task HostingPeerCannotBeUsedToTrustAnEarlierClaimedClient()
    {
        await using var app = await Start();
        using var client = app.GetTestClient();
        Assert.Equal(HttpStatusCode.Unauthorized, await Send(client, "66.249.93.1", "203.0.113.1"));
        Assert.Equal(HttpStatusCode.Unauthorized, await Send(client, "66.249.93.1", "203.0.113.2"));
        Assert.Equal(HttpStatusCode.TooManyRequests, await Send(client, "66.249.93.1", "203.0.113.3"));
    }

    [Fact]
    public async Task OutsideCloudRunForwardingHeadersCannotChooseABucket()
    {
        await using var app = await Start(cloud: false);
        using var client = app.GetTestClient();
        Assert.Equal(HttpStatusCode.Unauthorized, await Send(client, "198.51.100.1"));
        Assert.Equal(HttpStatusCode.Unauthorized, await Send(client, "198.51.100.2"));
        Assert.Equal(HttpStatusCode.TooManyRequests, await Send(client, "198.51.100.3"));
    }

    [Fact]
    public async Task CountersBelongToEachInstanceAndRestartStartsEmpty()
    {
        await using (var first = await Start())
        {
            using var client = first.GetTestClient();
            await Send(client, "198.51.100.1");
            await Send(client, "198.51.100.1");
            Assert.Equal(HttpStatusCode.TooManyRequests, await Send(client, "198.51.100.1"));
            await using var second = await Start();
            using var other = second.GetTestClient();
            Assert.Equal(HttpStatusCode.Unauthorized, await Send(other, "198.51.100.1"));
        }
        await using var restarted = await Start();
        using var fresh = restarted.GetTestClient();
        Assert.Equal(HttpStatusCode.Unauthorized, await Send(fresh, "198.51.100.1"));
    }

    [Fact]
    public async Task NotificationAndPublicCountersAreIndependentAndBothAreBounded()
    {
        await using var app = await Start();
        using var client = app.GetTestClient();
        await Send(client, "198.51.100.1");
        await Send(client, "198.51.100.1");
        Assert.Equal(HttpStatusCode.TooManyRequests, await Send(client, "198.51.100.1"));
        for (var i = 0; i < 3; i++)
            Assert.Equal(HttpStatusCode.Unauthorized, await Send(client, "198.51.100.1", notification: true));
        Assert.Equal(HttpStatusCode.TooManyRequests, await Send(client, "198.51.100.2", notification: true));
        Assert.Equal(HttpStatusCode.Unauthorized, await Send(client, "198.51.100.2"));
    }

    [Fact]
    public async Task InvalidAppleNotificationsCannotExhaustGoogleNotificationBucket()
    {
        await using var app = await Start();
        using var client = app.GetTestClient();
        for (var i = 0; i < 3; i++)
        {
            using var response = await client.PostAsync("/notifications/apple", null);
            Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
        }
        using var limited = await client.PostAsync("/notifications/apple", null);
        Assert.Equal(HttpStatusCode.TooManyRequests, limited.StatusCode);
        Assert.Equal(HttpStatusCode.Unauthorized, await Send(client, "198.51.100.1", notification: true));
    }

    [Fact]
    public void OnlyVerifiedIdentitiesChooseIdentityBucketsAndAccountSessionsShareThem()
    {
        var context = new DefaultHttpContext();
        var identity = Guid.NewGuid();
        context.Items["session"] = new SessionIdentity(identity, null, Guid.NewGuid());
        var guest = TrafficLimiting.PublicKey(context, true);
        context.Items["session"] = new SessionIdentity(Guid.NewGuid(), null, Guid.NewGuid());
        Assert.NotEqual(guest, TrafficLimiting.PublicKey(context, true));
        var account = Guid.NewGuid();
        context.Items["session"] = new SessionIdentity(identity, account, Guid.NewGuid());
        var key = TrafficLimiting.PublicKey(context, true);
        context.Items["session"] = new SessionIdentity(Guid.NewGuid(), account, Guid.NewGuid());
        Assert.Equal(key, TrafficLimiting.PublicKey(context, true));
        Assert.NotEqual(guest, key);
        context.Items.Clear();
        context.Request.Headers.Authorization = "Bearer " + identity;
        Assert.Equal("network:unknown", TrafficLimiting.PublicKey(context, true));
    }

    [Theory]
    [InlineData("")]
    [InlineData("203.0.113.1, broken")]
    [InlineData("203.0.113.1,")]
    public void MissingOrMalformedFinalPeerFailsClosed(string header)
    {
        var context = new DefaultHttpContext();
        context.Request.Headers["X-Forwarded-For"] = header;
        Assert.Equal("network:unknown", TrafficLimiting.PublicKey(context, true));
    }

    [Fact]
    public void MultipleHeaderLinesAndMappedIpv4UseTheFinalNormalizedPeer()
    {
        var context = new DefaultHttpContext();
        context.Request.Headers["X-Forwarded-For"] = new Microsoft.Extensions.Primitives.StringValues(
            ["203.0.113.1", "::ffff:198.51.100.1"]);
        Assert.Equal("network:198.51.100.1", TrafficLimiting.PublicKey(context, true));
    }
}
