using System.Collections.Concurrent;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.AspNetCore.TestHost;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Microsoft.Extensions.Logging;
using Sedno.Application;
using Sedno.Infrastructure;
using Testcontainers.PostgreSql;
using Xunit;

namespace Sedno.IntegrationTests;

[CollectionDefinition("backend", DisableParallelization = true)]
public sealed class BackendCollection : ICollectionFixture<BackendFixture> { }

public sealed class TestClock : TimeProvider
{
    private DateTimeOffset _now = new(2026, 10, 14, 12, 0, 0, TimeSpan.Zero);
    public override DateTimeOffset GetUtcNow() => _now;
    public void Set(DateTimeOffset now) => _now = now;
}

public sealed class TestModel : IModelProvider
{
    public int Calls;
    public bool Fail;
    public TaskCompletionSource<bool>? Gate;
    public async Task<string> SimplifyAsync(string text, CancellationToken cancellationToken)
    {
        Interlocked.Increment(ref Calls);
        if (Gate is not null) await Gate.Task.WaitAsync(cancellationToken);
        if (Fail) throw new InvalidOperationException("provider unavailable");
        return "Wersja demonstracyjna: " + text;
    }
    public void Reset() { Calls = 0; Fail = false; Gate = null; }
}

public sealed class TestEntitlements : IEntitlementResolver
{
    public HashSet<Guid> Paid { get; } = [];
    public Task<bool> HasSubscriptionAsync(Guid id, CancellationToken ct) => Task.FromResult(Paid.Contains(id));
}

public sealed class TestIdentityVerifier : IIdentityTokenVerifier
{
    public Task<VerifiedIdentity?> VerifyAsync(string token, CancellationToken ct) =>
        Task.FromResult<VerifiedIdentity?>(token switch
        {
            "google-user-1" => new("user-1", "google"),
            "email-user-1" => new("user-1", "email"),
            "google-user-2" => new("user-2", "google"),
            _ => null
        });
}

public sealed class TestIntegrityVerifier : IIntegrityVerifier
{
    public bool Allow { get; set; } = true;
    public Task<bool> VerifyAsync(string? token, string requestHash, CancellationToken ct) =>
        Task.FromResult(Allow);
}

public sealed class CaptureLogs : ILoggerProvider
{
    public ConcurrentQueue<string> Messages { get; } = new();
    public ILogger CreateLogger(string categoryName) => new Sink(Messages);
    public void Dispose() { }
    private sealed class Sink(ConcurrentQueue<string> messages) : ILogger
    {
        public IDisposable BeginScope<TState>(TState state) where TState : notnull => NullScope.Instance;
        public bool IsEnabled(LogLevel logLevel) => true;
        public void Log<TState>(LogLevel level, EventId id, TState state, Exception? exception,
            Func<TState, Exception?, string> formatter) => messages.Enqueue(formatter(state, exception));
    }
    private sealed class NullScope : IDisposable
    {
        public static readonly NullScope Instance = new();
        public void Dispose() { }
    }
}

public sealed class BackendFixture : IAsyncLifetime
{
    private readonly PostgreSqlContainer _postgres = new PostgreSqlBuilder("postgres:17-alpine").Build();
    private readonly Dictionary<string, string?> _originalEnvironment = new();
    public TestClock Clock { get; } = new();
    public TestModel Model { get; } = new();
    public TestEntitlements Entitlements { get; } = new();
    public TestIdentityVerifier Identities { get; } = new();
    public TestIntegrityVerifier Integrity { get; } = new();
    public CaptureLogs Logs { get; } = new();
    public WebApplicationFactory<Program> Factory { get; private set; } = null!;

    public async Task InitializeAsync()
    {
        await _postgres.StartAsync();
        SetEnvironment("ASPNETCORE_ENVIRONMENT", "Development");
        SetEnvironment("ConnectionStrings__Postgres", _postgres.GetConnectionString());
        SetEnvironment("Security__CredentialKey", Convert.ToBase64String(Enumerable.Repeat((byte)1, 32).ToArray()));
        SetEnvironment("Security__FingerprintKey", Convert.ToBase64String(Enumerable.Repeat((byte)2, 32).ToArray()));
        SetEnvironment("RateLimiting__PermitLimit", "1000");
        Factory = new WebApplicationFactory<Program>().WithWebHostBuilder(web =>
        {
            web.UseEnvironment("Development");
            web.ConfigureTestServices(services =>
            {
                services.RemoveAll<TimeProvider>(); services.AddSingleton<TimeProvider>(Clock);
                services.RemoveAll<IModelProvider>(); services.AddSingleton<IModelProvider>(Model);
                services.RemoveAll<IEntitlementResolver>(); services.AddSingleton<IEntitlementResolver>(Entitlements);
                services.RemoveAll<IIdentityTokenVerifier>(); services.AddSingleton<IIdentityTokenVerifier>(Identities);
                services.RemoveAll<IIntegrityVerifier>(); services.AddSingleton<IIntegrityVerifier>(Integrity);
                services.AddLogging(logging => logging.AddProvider(Logs));
            });
        });
        _ = Factory.CreateClient();
        using var scope = Factory.Services.CreateScope();
        await scope.ServiceProvider.GetRequiredService<AppDbContext>().Database.MigrateAsync();
    }

    public async Task DisposeAsync()
    {
        await Factory.DisposeAsync();
        await _postgres.DisposeAsync();
        foreach (var (name, value) in _originalEnvironment)
            Environment.SetEnvironmentVariable(name, value);
    }

    private void SetEnvironment(string name, string value)
    {
        _originalEnvironment[name] = Environment.GetEnvironmentVariable(name);
        Environment.SetEnvironmentVariable(name, value);
    }
}
