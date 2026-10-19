using System.Net;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.Configuration;
using Xunit;

namespace Sedno.IntegrationTests;

public sealed class CloudRunHostingTests
{
    private static WebApplicationBuilder Builder(string environment = "Production", string? service = "sedno-api", string port = "8080")
    {
        var builder = WebApplication.CreateBuilder(new WebApplicationOptions
        {
            EnvironmentName = environment, ContentRootPath = Path.GetTempPath()
        });
        builder.Configuration.AddInMemoryCollection(new Dictionary<string, string?>
        {
            ["K_SERVICE"] = service, ["PORT"] = port
        });
        builder.WebHost.UseTestServer();
        return builder;
    }

    [Theory]
    [InlineData("Development")]
    [InlineData("Staging")]
    public void CloudRunRejectsNonProductionEnvironments(string environment) =>
        Assert.Throws<InvalidOperationException>(() => CloudRunHosting.Configure(Builder(environment)));

    [Theory]
    [InlineData("0")]
    [InlineData("65536")]
    [InlineData("8080;https://evil.invalid")]
    [InlineData("-1")]
    public void InvalidPortsFailClosed(string port) =>
        Assert.Throws<InvalidOperationException>(() => CloudRunHosting.Configure(Builder(port: port)));

    [Fact]
    public void ListensOnThePlatformPort()
    {
        var builder = Builder(port: "9090");
        Assert.True(CloudRunHosting.Configure(builder));
        Assert.Equal("http://0.0.0.0:9090", builder.Configuration["urls"]);
    }

    [Theory]
    [InlineData(true, "https")]
    [InlineData(false, "http")]
    public async Task OnlyPlatformRuntimeChangesSchemeAndNeverTrustsForwardedIdentity(bool cloud, string scheme)
    {
        var builder = Builder(service: cloud ? "sedno-api" : null);
        var enabled = CloudRunHosting.Configure(builder);
        await using var app = builder.Build();
        if (enabled) app.UseCloudRunTransport();
        app.MapGet("/health/live", (Microsoft.AspNetCore.Http.HttpContext context) =>
            context.Request.Scheme + ":" + context.Connection.RemoteIpAddress);
        await app.StartAsync();
        using var client = app.GetTestClient();
        client.DefaultRequestHeaders.Add("X-Forwarded-Proto", cloud ? "http" : "https");
        client.DefaultRequestHeaders.Add("X-Forwarded-For", "203.0.113.9");
        using var response = await client.GetAsync("/health/live");
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var text = await response.Content.ReadAsStringAsync();
        Assert.StartsWith(scheme + ":", text);
        Assert.DoesNotContain("203.0.113.9", text);
    }
}
