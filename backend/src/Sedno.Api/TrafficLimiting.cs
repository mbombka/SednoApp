using System.Net;
using System.Threading.RateLimiting;
using Microsoft.AspNetCore.Mvc;
using Sedno.Application;

/// <summary>Process-local traffic counters; no persistence, authentication or network I/O.</summary>
public static class TrafficLimiting
{
    public static void AddTrafficLimiting(this IServiceCollection services, IConfiguration configuration, bool cloudRun)
    {
        var publicLimit = configuration.GetValue<int?>("RateLimiting:PermitLimit") ?? 60;
        var notificationLimit = configuration.GetValue<int?>("RateLimiting:NotificationPermitLimit") ?? 600;
        if (publicLimit < 1 || notificationLimit < 1)
            throw new InvalidOperationException("Traffic permit limits must be positive.");
        services.AddRateLimiter(options =>
        {
            options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
            options.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(context =>
            {
                // RTDN has its own bounded bucket. Its JWT is still verified by the endpoint.
                var notification = context.GetEndpoint()?.Metadata.GetMetadata<NotificationTraffic>() is not null;
                var key = notification ? "notifications" : PublicKey(context, cloudRun);
                return RateLimitPartition.GetFixedWindowLimiter(key, _ => new FixedWindowRateLimiterOptions
                {
                    PermitLimit = notification ? notificationLimit : publicLimit,
                    Window = TimeSpan.FromMinutes(1), QueueLimit = 0
                });
            });
            options.OnRejected = async (context, _) =>
            {
                var details = new ProblemDetails { Status = 429, Title = "Zbyt wiele żądań." };
                details.Extensions["code"] = "rate_limited";
                await Results.Problem(details).ExecuteAsync(context.HttpContext);
            };
        });
    }

    public static string PublicKey(HttpContext context, bool cloudRun)
    {
        // Only the result of the existing session authentication may select an identity.
        // Account sessions share a bucket; guest sessions use their installation identity.
        if (context.Items["session"] is SessionIdentity session)
            return session.AccountId is { } account ? $"account:{account:N}" : $"guest:{session.IdentityId:N}";
        return "network:" + NetworkPeer(context, cloudRun);
    }

    private static string NetworkPeer(HttpContext context, bool cloudRun)
    {
        if (cloudRun)
        {
            // Cloud Run appends the connecting peer. Everything before that peer is
            // untrusted, including a claimed Hosting hop or Fastly-Client-IP.
            var forwarded = context.Request.Headers["X-Forwarded-For"].ToString();
            var last = forwarded.AsSpan(forwarded.LastIndexOf(',') + 1).Trim();
            return IPAddress.TryParse(last, out var peer) ? Normalize(peer) : "unknown";
        }
        return context.Connection.RemoteIpAddress is { } remote ? Normalize(remote) : "unknown";
    }

    private static string Normalize(IPAddress address) =>
        (address.IsIPv4MappedToIPv6 ? address.MapToIPv4() : address).ToString();
}

public sealed class NotificationTraffic;
