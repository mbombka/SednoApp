using System.Globalization;
using Microsoft.AspNetCore.DataProtection;

/// <summary>Transport at the Cloud Run TLS boundary; never trusts caller-supplied forwarding headers.</summary>
public static class CloudRunHosting
{
    public static void VerifyBillingKeyRing(IServiceProvider services)
    {
        var protector = services.GetRequiredService<IDataProtectionProvider>().CreateProtector("Sedno.StartupProbe");
        if (protector.Unprotect(protector.Protect("key-ring-probe")) != "key-ring-probe")
            throw new InvalidOperationException("Cloud Run billing key ring is unusable.");
    }

    public static bool Configure(WebApplicationBuilder builder)
    {
        var service = builder.Configuration["K_SERVICE"];
        if (string.IsNullOrWhiteSpace(service)) return false;
        if (!builder.Environment.IsProduction())
            throw new InvalidOperationException("Cloud Run requires the Production environment.");
        var rawPort = builder.Configuration["PORT"] ?? "8080";
        if (!int.TryParse(rawPort, NumberStyles.None, CultureInfo.InvariantCulture, out var port) || port is < 1 or > 65535)
            throw new InvalidOperationException("Invalid Cloud Run PORT.");
        builder.WebHost.UseUrls($"http://0.0.0.0:{port}");
        return true;
    }

    public static void UseCloudRunTransport(this WebApplication app)
    {
        app.Use(async (context, next) =>
        {
            // Public Cloud Run ingress always terminates TLS. Internal HTTP is the
            // managed proxy/probe transport, not a public cleartext listener.
            // Do not consume X-Forwarded-For: an untrusted prefix can be spoofed.
            context.Request.Scheme = "https";
            await next(context);
        });
    }
}
