using System.Text.Json;
using System.Threading.RateLimiting;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Simplifier.Application;
using Simplifier.Infrastructure;

var builder = WebApplication.CreateBuilder(args);
builder.WebHost.ConfigureKestrel(options => options.Limits.MaxRequestBodySize = 128 * 1024);
builder.Services.AddProblemDetails();
builder.Services.AddHealthChecks();
var connectionString = builder.Configuration.GetConnectionString("Postgres");
if (string.IsNullOrWhiteSpace(connectionString)) throw new InvalidOperationException("ConnectionStrings:Postgres is required.");
builder.Services.AddDbContext<AppDbContext>(options => options.UseNpgsql(connectionString));
builder.Services.AddSingleton(TimeProvider.System);
builder.Services.AddScoped<IUsageStore, UsageStore>();
builder.Services.AddScoped<IEntitlementResolver, FreeEntitlementResolver>();
builder.Services.AddScoped<IIntegrityVerifier, PendingIntegrityVerifier>();
builder.Services.AddHostedService<MetadataCleanup>();

var credentialKey = ReadKey(builder.Configuration, "Security:CredentialKey");
var fingerprintKey = ReadKey(builder.Configuration, "Security:FingerprintKey");
builder.Services.AddScoped<GuestStore>(sp => new(sp.GetRequiredService<AppDbContext>(),
    sp.GetRequiredService<IUsageStore>(), sp.GetRequiredService<TimeProvider>(), credentialKey));
builder.Services.AddScoped<IGuestStore>(sp => sp.GetRequiredService<GuestStore>());
builder.Services.AddScoped<SimplificationService>(sp => new(sp.GetRequiredService<IUsageStore>(),
    sp.GetRequiredService<IModelProvider>(), sp.GetRequiredService<TimeProvider>(), fingerprintKey));
var provider = builder.Configuration["Model:Provider"] ?? "disabled";
if (provider == "mock" && !builder.Environment.IsDevelopment())
    throw new InvalidOperationException("Development mock cannot run outside Development.");
if (provider == "mock") builder.Services.AddScoped<IModelProvider, DevelopmentMockProvider>();
else if (provider == "disabled") builder.Services.AddScoped<IModelProvider, DisabledModelProvider>();
else throw new InvalidOperationException("Unsupported model provider.");

builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    options.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(context =>
        RateLimitPartition.GetFixedWindowLimiter(
            $"ip:{context.Connection.RemoteIpAddress}",
            _ => new FixedWindowRateLimiterOptions { PermitLimit = 60, Window = TimeSpan.FromMinutes(1), QueueLimit = 0 }));
    options.OnRejected = async (context, _) =>
    {
        var details = new ProblemDetails { Status = 429, Title = "Zbyt wiele żądań." };
        details.Extensions["code"] = "rate_limited";
        await Results.Problem(details).ExecuteAsync(context.HttpContext);
    };
});

var app = builder.Build();
app.Use(async (context, next) =>
{
    try { await next(context); }
    catch (BadHttpRequestException ex) when (!context.Response.HasStarted)
    {
        var status = ex.StatusCode == 413 ? 413 : 400;
        var code = status == 413 ? "request_too_large" : "invalid_request";
        await Problem(context, status, code, status == 413 ? "Żądanie jest zbyt duże." : "Nieprawidłowe żądanie.").ExecuteAsync(context);
    }
    catch (Exception) when (!context.Response.HasStarted && !context.RequestAborted.IsCancellationRequested)
    {
        await Problem(context, 500, "server_error", "Wystąpił błąd serwera.").ExecuteAsync(context);
    }
});
app.UseRateLimiter();
app.Use(async (context, next) =>
{
    if (context.Request.ContentLength > 128 * 1024)
    {
        await Problem(context, 413, "request_too_large", "Żądanie jest zbyt duże.").ExecuteAsync(context);
        return;
    }
    if (!app.Environment.IsDevelopment() && !context.Request.IsHttps)
    {
        await Problem(context, 400, "https_required", "Wymagane jest połączenie HTTPS.").ExecuteAsync(context);
        return;
    }
    if (context.Request.Path.StartsWithSegments("/v1") &&
        !string.Equals(context.Request.Path.Value, "/v1/guest-sessions", StringComparison.OrdinalIgnoreCase))
    {
        var authorization = context.Request.Headers.Authorization.ToString();
        if (!authorization.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase) ||
            await context.RequestServices.GetRequiredService<IGuestStore>()
                .AuthenticateAsync(authorization[7..], context.RequestAborted) is not Guid identityId)
        {
            await Problem(context, 401, "unauthorized", "Brak ważnej sesji.").ExecuteAsync(context);
            return;
        }
        context.Items["identity"] = identityId;
    }
    await next(context);
});
app.MapHealthChecks("/health/live", new() { Predicate = _ => false });
app.MapGet("/health/ready", async (AppDbContext db, CancellationToken ct) =>
    await db.Database.CanConnectAsync(ct) ? Results.Ok(new { status = "ready" }) : Results.StatusCode(503));

app.MapPost("/v1/guest-sessions", async (HttpContext context, IGuestStore guests, IIntegrityVerifier integrity) =>
{
    GuestInput? request;
    try { request = await context.Request.ReadFromJsonAsync<GuestInput>(cancellationToken: context.RequestAborted); }
    catch (JsonException) { return Problem(context, 400, "invalid_json", "Nieprawidłowe dane."); }
    if (request is null || string.IsNullOrWhiteSpace(request.InstallationId) || request.InstallationId.Length > 200)
        return Problem(context, 400, "invalid_installation_id", "Nieprawidłowy identyfikator instalacji.");
    if (!await integrity.VerifyAsync(request.IntegrityToken, context.RequestAborted))
        return Problem(context, 403, "integrity_failed", "Nie można potwierdzić instalacji.");
    return Results.Ok(await guests.CreateAsync(request.InstallationId, context.RequestAborted));
});
app.MapGet("/v1/quota", async (HttpContext context, IUsageStore usage) =>
    Results.Ok(await usage.GetQuotaAsync((Guid)context.Items["identity"]!, context.RequestAborted)));
app.MapGet("/v1/simplifications/requests/{requestId}", async (HttpContext context, string requestId, IUsageStore usage) =>
{
    if (!ValidRequestId(requestId)) return Problem(context, 400, "invalid_request_id", "Nieprawidłowy identyfikator żądania.");
    var status = await usage.GetStatusAsync((Guid)context.Items["identity"]!, requestId, context.RequestAborted);
    return status is null ? Problem(context, 404, "request_not_found", "Nie znaleziono żądania.") : Results.Ok(status);
});
app.MapPost("/v1/simplifications", async (HttpContext context, SimplificationService service) =>
{
    SimplificationInput? input;
    try { input = await context.Request.ReadFromJsonAsync<SimplificationInput>(cancellationToken: context.RequestAborted); }
    catch (JsonException) { return Problem(context, 400, "invalid_json", "Nieprawidłowe dane."); }
    if (input is null) return Problem(context, 400, "invalid_json", "Nieprawidłowe dane.");
    try
    {
        var outcome = await service.RunAsync((Guid)context.Items["identity"]!, input, context.RequestAborted);
        return outcome.Kind switch
        {
            "succeeded" => Results.Ok(outcome.Response),
            "processing" => Results.Accepted($"/v1/simplifications/requests/{input.RequestId}",
                new { status = "processing", quota = outcome.Quota }),
            "key_conflict" => Problem(context, 409, "key_conflict", "Identyfikator żądania jest już użyty."),
            "result_unavailable" => Problem(context, 409, "result_unavailable", "Wynik tego żądania nie jest już dostępny. Użyj nowego identyfikatora."),
            "quota_exceeded" => Problem(context, 429, "quota_exceeded", "Wykorzystano dzienny limit.", outcome.Quota),
            "expired" => Problem(context, 409, "reservation_expired", "Czas tego żądania minął. Użyj nowego identyfikatora."),
            "failed" => Problem(context, 409, "request_failed", "Poprzednia próba nie powiodła się. Użyj nowego identyfikatora."),
            _ => Problem(context, 503, "provider_unavailable", "Usługa upraszczania jest chwilowo niedostępna.")
        };
    }
    catch (InputValidationException ex) { return Problem(context, 400, ex.Code, ex.Message); }
});
app.Run();

static byte[] ReadKey(IConfiguration configuration, string name)
{
    var value = configuration[name] ?? throw new InvalidOperationException($"{name} is required.");
    byte[] bytes;
    try { bytes = Convert.FromBase64String(value); }
    catch (FormatException) { throw new InvalidOperationException($"{name} must be base64."); }
    if (bytes.Length < 32) throw new InvalidOperationException($"{name} must contain at least 32 random bytes.");
    return bytes;
}
static bool ValidRequestId(string id) => id.Length is > 0 and <= 100 &&
    id.All(c => char.IsAsciiLetterOrDigit(c) || c is '-' or '_');
static IResult Problem(HttpContext context, int status, string code, string title, QuotaDto? quota = null)
{
    var details = new ProblemDetails { Status = status, Title = title, Type = "about:blank" };
    details.Extensions["code"] = code;
    if (quota is not null) details.Extensions["quota"] = quota;
    return Results.Problem(details);
}
public sealed record GuestInput(string InstallationId, string? IntegrityToken);
public partial class Program { }
