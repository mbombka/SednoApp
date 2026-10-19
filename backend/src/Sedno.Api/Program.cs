using System.Text.Json;
using System.Threading.RateLimiting;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.EntityFrameworkCore;
using Sedno.Application;
using Sedno.Infrastructure;

var builder = WebApplication.CreateBuilder(args);
if (args is ["--init-billing-keyring", var directory])
{
    if (!builder.Environment.IsDevelopment())
        throw new InvalidOperationException("Key ring initialization is Development-only.");
    builder.Services.AddDataProtection().SetApplicationName("Sedno")
        .PersistKeysToFileSystem(new DirectoryInfo(directory));
    await using var keyApp = builder.Build();
    var manager = keyApp.Services.GetRequiredService<Microsoft.AspNetCore.DataProtection.KeyManagement.IKeyManager>();
    if (manager.GetAllKeys().Count > 0)
        throw new InvalidOperationException("Use the existing key ring; initialization requires an empty directory.");
    var now = DateTimeOffset.UtcNow;
    manager.CreateNewKey(now, now.AddYears(1));
    return;
}
var cloudRun = CloudRunHosting.Configure(builder);
builder.WebHost.ConfigureKestrel(options => options.Limits.MaxRequestBodySize = 128 * 1024);
builder.Services.AddProblemDetails();
builder.Services.AddHealthChecks();
var connectionString = builder.Configuration.GetConnectionString("Postgres");
if (string.IsNullOrWhiteSpace(connectionString)) throw new InvalidOperationException("ConnectionStrings:Postgres is required.");
builder.Services.AddDbContext<AppDbContext>(options => options.UseNpgsql(connectionString));
// Run explicitly as a one-off deployment job, before serving a new revision.
if (args.Contains("--migrate", StringComparer.Ordinal))
{
    await using var migrationApp = builder.Build();
    await using var scope = migrationApp.Services.CreateAsyncScope();
    await scope.ServiceProvider.GetRequiredService<AppDbContext>().Database.MigrateAsync();
    return;
}
builder.Services.AddSingleton(TimeProvider.System);
builder.Services.AddScoped<SimplificationTimings>();
builder.Services.AddScoped<IUsageStore, UsageStore>();
var dataProtection = builder.Services.AddDataProtection().SetApplicationName("Sedno");
builder.Services.AddScoped<SubscriptionService>();
builder.Services.AddScoped<IEntitlementResolver>(sp => sp.GetRequiredService<SubscriptionService>());
builder.Services.AddHostedService<MetadataCleanup>();
builder.Services.AddHttpClient();
var credentialProvider = builder.Configuration["Google:CredentialProvider"] ?? "file";
if (credentialProvider is not ("file" or "cloud-run") || (credentialProvider == "cloud-run" && !cloudRun))
    throw new InvalidOperationException("Google:CredentialProvider cloud-run requires the Production Cloud Run runtime.");
var serviceIdentity = credentialProvider == "cloud-run";
if (serviceIdentity)
{
    builder.Services.AddHttpClient("google-metadata", client => client.Timeout = TimeSpan.FromSeconds(3))
        .ConfigurePrimaryHttpMessageHandler(() => new SocketsHttpHandler { AllowAutoRedirect = false, UseProxy = false })
        .RemoveAllLoggers();
}
IPlayAccessTokenSource GoogleTokens(IServiceProvider sp, HttpClient client, string? path, string scope) => serviceIdentity
    ? new CloudRunAccessTokenSource(sp.GetRequiredService<IHttpClientFactory>().CreateClient("google-metadata"),
        sp.GetRequiredService<TimeProvider>(), scope)
    : new ServiceAccountAccessTokenSource(client, path!, sp.GetRequiredService<TimeProvider>(), scope);

// Purchase tokens appear in Google API URLs. Disable all HTTP client loggers for this client.
builder.Services.AddHttpClient("play-billing", client => client.Timeout = TimeSpan.FromSeconds(15)).RemoveAllLoggers();
var billingEnabled = builder.Configuration.GetValue<bool>("Billing:Enabled");
var billingPackage = builder.Configuration["Billing:PackageName"] ?? "";
var billingProduct = builder.Configuration["Billing:ProductId"] ?? "";
if (billingEnabled)
{
    var keyPath = builder.Configuration["Billing:DataProtectionKeyPath"];
    if (!builder.Environment.IsDevelopment() && string.IsNullOrWhiteSpace(keyPath))
        throw new InvalidOperationException("Billing:DataProtectionKeyPath is required in production.");
    if (!string.IsNullOrWhiteSpace(keyPath)) dataProtection.PersistKeysToFileSystem(new DirectoryInfo(keyPath));
    if (builder.Configuration.GetValue<bool>("Billing:ReadOnlyKeyRing"))
        dataProtection.DisableAutomaticKeyGeneration();
    if (cloudRun && (string.IsNullOrWhiteSpace(keyPath) || !builder.Configuration.GetValue<bool>("Billing:ReadOnlyKeyRing")))
        throw new InvalidOperationException("Cloud Run billing requires a shared, read-only key ring from Secret Manager.");
    var path = builder.Configuration["Billing:ServiceAccountJsonPath"];
    var audience = builder.Configuration["Billing:NotificationAudience"];
    var email = builder.Configuration["Billing:PushServiceAccountEmail"];
    if (new[] { billingPackage, billingProduct, serviceIdentity ? "service-identity" : path, audience, email }.Any(string.IsNullOrWhiteSpace))
        throw new InvalidOperationException("Complete Google Play Billing configuration is required.");
    builder.Services.AddSingleton<IPlayBillingClient>(sp =>
    {
        var client = sp.GetRequiredService<IHttpClientFactory>().CreateClient("play-billing");
        return new PlayBillingClient(client, GoogleTokens(sp, client, path, "https://www.googleapis.com/auth/androidpublisher"),
            new(billingPackage, billingProduct));
    });
    builder.Services.AddSingleton<INotificationVerifier>(sp => new PubSubTokenVerifier(
        sp.GetRequiredService<IHttpClientFactory>().CreateClient("play-billing"), audience!, email!, sp.GetRequiredService<TimeProvider>()));
}
else
{
    builder.Services.AddSingleton<IPlayBillingClient, DisabledPlayBillingClient>();
    builder.Services.AddScoped<IEntitlementResolver, FreeEntitlementResolver>();
}
var firebaseProject = builder.Configuration["Firebase:ProjectId"];
if (!builder.Environment.IsDevelopment() && string.IsNullOrWhiteSpace(firebaseProject))
    throw new InvalidOperationException("Firebase:ProjectId is required.");
builder.Services.AddSingleton<IIdentityTokenVerifier>(sp => new FirebaseTokenVerifier(
    sp.GetRequiredService<IHttpClientFactory>().CreateClient(), firebaseProject ?? "development",
    sp.GetRequiredService<TimeProvider>()));
builder.Services.AddScoped<AccountDeletionService>();
builder.Services.AddHttpClient("identity-deletion", client => client.Timeout = TimeSpan.FromSeconds(15)).RemoveAllLoggers();
var deletionCredentials = builder.Configuration["Firebase:DeletionServiceAccountJsonPath"];
if (!serviceIdentity && !builder.Environment.IsDevelopment() && string.IsNullOrWhiteSpace(deletionCredentials))
    throw new InvalidOperationException("Firebase:DeletionServiceAccountJsonPath is required.");
if (serviceIdentity || !string.IsNullOrWhiteSpace(deletionCredentials))
    builder.Services.AddSingleton<IIdentityAccountDeletion>(sp =>
    {
        var client = sp.GetRequiredService<IHttpClientFactory>().CreateClient("identity-deletion");
        return new FirebaseAccountDeletion(client, GoogleTokens(sp, client, deletionCredentials, "https://www.googleapis.com/auth/identitytoolkit"), firebaseProject!);
    });
else builder.Services.AddSingleton<IIdentityAccountDeletion, UnavailableAccountDeletion>();
var deletionEmail = builder.Configuration["Privacy:DeletionEmail"];
if (!builder.Environment.IsDevelopment() &&
    (string.IsNullOrWhiteSpace(deletionEmail) || !System.Net.Mail.MailAddress.TryCreate(deletionEmail, out _)))
    throw new InvalidOperationException("Privacy:DeletionEmail is required.");
var integrityProvider = builder.Configuration["PlayIntegrity:Provider"] ?? "google";
if (integrityProvider == "mock" && builder.Environment.IsDevelopment())
    builder.Services.AddSingleton<IIntegrityVerifier, DevelopmentIntegrityVerifier>();
else if (integrityProvider == "google")
{
    var packageName = builder.Configuration["PlayIntegrity:PackageName"];
    var credentialsPath = builder.Configuration["PlayIntegrity:ServiceAccountJsonPath"];
    if (string.IsNullOrWhiteSpace(packageName) || (!serviceIdentity && string.IsNullOrWhiteSpace(credentialsPath)))
        throw new InvalidOperationException("Play Integrity package and service account path are required.");
    builder.Services.AddSingleton<IPlayAccessTokenSource>(sp => GoogleTokens(sp,
        sp.GetRequiredService<IHttpClientFactory>().CreateClient(), credentialsPath, "https://www.googleapis.com/auth/playintegrity"));
    builder.Services.AddSingleton<IIntegrityVerifier>(sp => new PlayIntegrityVerifier(
        sp.GetRequiredService<IHttpClientFactory>().CreateClient(),
        sp.GetRequiredService<IPlayAccessTokenSource>(), packageName, sp.GetRequiredService<TimeProvider>()));
}
else throw new InvalidOperationException("Unsupported Play Integrity provider.");

var credentialKey = ReadKey(builder.Configuration, "Security:CredentialKey");
var fingerprintKey = ReadKey(builder.Configuration, "Security:FingerprintKey");
builder.Services.AddScoped<GuestStore>(sp => new(sp.GetRequiredService<AppDbContext>(),
    sp.GetRequiredService<IUsageStore>(), sp.GetRequiredService<TimeProvider>(), credentialKey,
    sp.GetRequiredService<IIdentityAccountDeletion>()));
builder.Services.AddScoped<IGuestStore>(sp => sp.GetRequiredService<GuestStore>());
builder.Services.AddScoped<SimplificationService>(sp => new(sp.GetRequiredService<IUsageStore>(),
    sp.GetRequiredService<IModelProvider>(), sp.GetRequiredService<TimeProvider>(), fingerprintKey, sp.GetRequiredService<SimplificationTimings>()));
builder.Services.AddSednoModel(builder.Configuration, builder.Environment.IsDevelopment());

builder.Services.AddRateLimiter(options =>
{
    var permitLimit = builder.Configuration.GetValue<int?>("RateLimiting:PermitLimit") ?? 60;
    if (permitLimit < 1) throw new InvalidOperationException("RateLimiting:PermitLimit must be positive.");
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    options.GlobalLimiter = PartitionedRateLimiter.Create<HttpContext, string>(context =>
        RateLimitPartition.GetFixedWindowLimiter(
            $"ip:{context.Connection.RemoteIpAddress}",
            _ => new FixedWindowRateLimiterOptions { PermitLimit = permitLimit, Window = TimeSpan.FromMinutes(1), QueueLimit = 0 }));
    options.OnRejected = async (context, _) =>
    {
        var details = new ProblemDetails { Status = 429, Title = "Zbyt wiele żądań." };
        details.Extensions["code"] = "rate_limited";
        await Results.Problem(details).ExecuteAsync(context.HttpContext);
    };
});

var app = builder.Build();
if (cloudRun && billingEnabled)
{
    // Fail before serving traffic if a mounted key ring is missing or unusable.
    CloudRunHosting.VerifyBillingKeyRing(app.Services);
}
if (cloudRun) app.UseCloudRunTransport();
// Firebase Hosting must never cache authenticated quota, sessions or results.
app.Use(async (context, next) =>
{
    context.Response.Headers.CacheControl = "no-store";
    await next(context);
});
// Content-free stage breakdown for each simplification, including authentication.
app.Use(async (context, next) =>
{
    if (context.Request.Path != "/v1/simplifications") { await next(context); return; }
    var clock = context.RequestServices.GetRequiredService<TimeProvider>();
    var timings = context.RequestServices.GetRequiredService<SimplificationTimings>();
    var started = clock.GetTimestamp();
    try { await next(context); }
    finally
    {
        app.Logger.LogInformation(
            "Czas upraszczania Trace={Trace} Status={Status} TotalMs={TotalMs:F1} AuthMs={AuthMs:F1} " +
            "ReserveMs={ReserveMs:F1} ModelMs={ModelMs:F1} CompleteMs={CompleteMs:F1} QuotaMs={QuotaMs:F1} " +
            "QuotaLockMs={QuotaLockMs:F1} ResponsesHeadersMs={ResponsesHeadersMs:F1} ResponsesCompleteMs={ResponsesCompleteMs:F1}",
            System.Diagnostics.Activity.Current?.TraceId.ToString() ?? context.TraceIdentifier,
            context.Response.StatusCode, clock.GetElapsedTime(started).TotalMilliseconds,
            timings[SimplificationStage.Authentication], timings[SimplificationStage.Reservation],
            timings[SimplificationStage.Model], timings[SimplificationStage.Completion], timings[SimplificationStage.QuotaRead],
            timings[SimplificationStage.QuotaLock], timings[SimplificationStage.ResponsesHeaders], timings[SimplificationStage.ResponsesComplete]);
    }
});
// Covers authentication, database work and model I/O. Leave a network margin
// before the mobile client's single 10-second end-to-end deadline.
app.Use(async (context, next) =>
{
    if (context.Request.Path != "/v1/simplifications") { await next(context); return; }
    var clientAborted = context.RequestAborted;
    using var deadline = new CancellationTokenSource(TimeSpan.FromSeconds(9),
        context.RequestServices.GetRequiredService<TimeProvider>());
    using var linked = CancellationTokenSource.CreateLinkedTokenSource(clientAborted, deadline.Token);
    context.RequestAborted = linked.Token;
    try { await next(context); }
    catch (OperationCanceledException) when (deadline.IsCancellationRequested && !clientAborted.IsCancellationRequested && !context.Response.HasStarted)
    {
        context.RequestAborted = clientAborted;
        await Problem(context, 504, "simplification_timeout", "Upraszczanie trwało zbyt długo. Spróbuj ponownie.").ExecuteAsync(context);
    }
    finally { context.RequestAborted = clientAborted; }
});
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
        using var authentication = context.Request.Path == "/v1/simplifications"
            ? context.RequestServices.GetRequiredService<SimplificationTimings>().Measure(SimplificationStage.Authentication) : null;
        var authorization = context.Request.Headers.Authorization.ToString();
        if (!authorization.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase) ||
            await context.RequestServices.GetRequiredService<IGuestStore>()
                .AuthenticateAsync(authorization[7..], context.RequestAborted) is not SessionIdentity session)
        {
            await Problem(context, 401, "unauthorized", "Brak ważnej sesji.").ExecuteAsync(context);
            return;
        }
        context.Items["identity"] = session.IdentityId;
        context.Items["session"] = session;
    }
    await next(context);
});
app.MapGet("/prywatnosc", (HttpContext context) =>
{
    context.Response.Headers.CacheControl = "no-store";
    context.Response.Headers.ContentSecurityPolicy = "default-src 'none'; style-src 'unsafe-inline'; base-uri 'none'; frame-ancestors 'none'; form-action 'none'";
    return Results.Content(PrivacyPage.Html, "text/html; charset=utf-8");
});
app.MapGet("/usun-konto", (HttpContext context) =>
{
    context.Response.Headers.CacheControl = "no-store";
    context.Response.Headers.ContentSecurityPolicy = "default-src 'none'; style-src 'unsafe-inline'; base-uri 'none'; frame-ancestors 'none'; form-action 'none'";
    return Results.Content(DeletionPage.Render(deletionEmail), "text/html; charset=utf-8");
});
app.MapDelete("/v1/account", async (HttpContext context, AccountDeletionService deletion, CancellationToken ct) =>
{
    var session = (SessionIdentity)context.Items["session"]!;
    if (session.AccountId is null) return Problem(context, 403, "account_required", "Zaloguj się, aby usunąć konto.");
    await deletion.DeleteAsync(session, ct);
    return Results.NoContent();
});
app.MapGet("/v1/subscription", async (HttpContext context, SubscriptionService subscriptions, CancellationToken ct) =>
{
    var session = (SessionIdentity)context.Items["session"]!;
    if (session.AccountId is null) return Problem(context, 403, "account_required", "Zaloguj się, aby korzystać z subskrypcji.");
    if (!billingEnabled) return Problem(context, 503, "billing_unavailable", "Płatności są niedostępne.");
    return Results.Ok(await subscriptions.CurrentAsync(session.AccountId.Value, ct));
});
app.MapPost("/v1/subscription", async (PurchaseInput input, HttpContext context, SubscriptionService subscriptions, CancellationToken ct) =>
{
    var session = (SessionIdentity)context.Items["session"]!;
    if (session.AccountId is null) return Problem(context, 403, "account_required", "Zaloguj się, aby kupić subskrypcję.");
    if (!billingEnabled) return Problem(context, 503, "billing_unavailable", "Płatności są niedostępne.");
    if (string.IsNullOrWhiteSpace(input.PurchaseToken) || input.PurchaseToken.Length > 8192)
        return Problem(context, 400, "invalid_purchase", "Nieprawidłowy zakup.");
    return Results.Ok(await subscriptions.VerifyAsync(session.AccountId.Value, input.PurchaseToken, ct));
});
app.MapPost("/notifications/google-play", async (PubSubEnvelope envelope, HttpContext context,
    SubscriptionService subscriptions, CancellationToken ct) =>
{
    if (!billingEnabled) return Results.StatusCode(503);
    var header = context.Request.Headers.Authorization.ToString();
    if (!header.StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase) ||
        !await context.RequestServices.GetRequiredService<INotificationVerifier>().VerifyAsync(header[7..], ct))
        return Results.Unauthorized();
    if (envelope.Message is not { Data: { Length: > 0 }, MessageId: { Length: > 0 and <= 200 } } message)
        return Results.BadRequest();
    try
    {
        using var doc = JsonDocument.Parse(Convert.FromBase64String(message.Data));
        var p = doc.RootElement;
        if (p.GetProperty("packageName").GetString() != billingPackage) return Results.BadRequest();
        if (p.TryGetProperty("testNotification", out _)) return Results.NoContent();
        var revoked = p.TryGetProperty("voidedPurchaseNotification", out var notification);
        if (!revoked && !p.TryGetProperty("subscriptionNotification", out notification)) return Results.NoContent();
        var token = notification.GetProperty("purchaseToken").GetString();
        if (string.IsNullOrWhiteSpace(token) || token.Length > 8192) return Results.BadRequest();
        await subscriptions.NotifyAsync(message.MessageId, token, ct);
        return Results.NoContent();
    }
    catch (Exception ex) when (ex is JsonException or FormatException or KeyNotFoundException)
    { return Results.BadRequest(); }
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
    if (!await integrity.VerifyAsync(request.IntegrityToken,
        PlayIntegrityVerifier.RequestHash(request.InstallationId), context.RequestAborted))
        return Problem(context, 403, "integrity_failed", "Nie można potwierdzić instalacji.");
    return Results.Ok(await guests.CreateAsync(request.InstallationId, context.RequestAborted));
});
app.MapPost("/v1/auth/sessions", async (HttpContext context, IGuestStore guests, IIdentityTokenVerifier verifier) =>
{
    IdentityTokenInput? input;
    try { input = await context.Request.ReadFromJsonAsync<IdentityTokenInput>(cancellationToken: context.RequestAborted); }
    catch (JsonException) { return Problem(context, 400, "invalid_json", "Nieprawidłowe dane."); }
    if (input is null || string.IsNullOrWhiteSpace(input.IdToken) || input.IdToken.Length > 8192)
        return Problem(context, 400, "invalid_id_token", "Nieprawidłowy token tożsamości.");
    var verified = await verifier.VerifyAsync(input.IdToken, context.RequestAborted);
    if (verified is null) return Problem(context, 401, "invalid_id_token", "Nie można potwierdzić tożsamości.");
    var linked = await guests.LinkAsync((SessionIdentity)context.Items["session"]!, verified, context.RequestAborted);
    return linked is null ? Problem(context, 409, "account_conflict", "Nie można połączyć tego konta.") : Results.Ok(linked);
});
app.MapPost("/v1/auth/sign-out", async (HttpContext context, IGuestStore guests) =>
{
    await guests.SignOutAsync((SessionIdentity)context.Items["session"]!, context.RequestAborted);
    return Results.NoContent();
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
            "timeout" => Problem(context, 504, "simplification_timeout", "Upraszczanie trwało zbyt długo. Spróbuj ponownie."),
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
public sealed record IdentityTokenInput(string IdToken);
public partial class Program { }

public sealed record PurchaseInput(string PurchaseToken);
public sealed record PubSubMessage(string Data, string MessageId);
public sealed record PubSubEnvelope(PubSubMessage? Message);
