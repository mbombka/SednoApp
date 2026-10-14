using System.Collections.Concurrent;
using Microsoft.AspNetCore.Hosting;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.AspNetCore.TestHost;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Microsoft.Extensions.Logging;
using Simplifier.Application;
using Simplifier.Infrastructure;
using Testcontainers.PostgreSql;
using Xunit;

namespace Simplifier.IntegrationTests;

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
            Func<TState, Exception?, string> formatter) => messages.Enqueue(formatter(state));
    }
    private sealed class NullScope : IDisposable
    {
        public static readonly NullScope Instance = new();
        public void Dispose() { }
    }
}

public sealed class BackendFixture : IAsyncLifetime
{
    private readonly PostgreSqlContainer _postgres = new PostgreSqlBuilder().WithImage("postgres:17-alpine").Build();
    public TestClock Clock { get; } = new();
    public TestModel Model { get; } = new();
    public TestEntitlements Entitlements { get; } = new();
    public CaptureLogs Logs { get; } = new();
    public WebApplicationFactory<Program> Factory { get; private set; } = null!;

    public async Task InitializeAsync()
    {
        await _postgres.StartAsync();
        Factory = new WebApplicationFactory<Program>().WithWebHostBuilder(web =>
        {
            web.UseEnvironment("Development");
            web.ConfigureAppConfiguration((_, config) => config.AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["ConnectionStrings:Postgres"] = _postgres.GetConnectionString(),
                ["Security:CredentialKey"] = Convert.ToBase64String(Enumerable.Repeat((byte)1, 32).ToArray()),
                ["Security:FingerprintKey"] = Convert.ToBase64String(Enumerable.Repeat((byte)2, 32).ToArray())
            }));
            web.ConfigureTestServices(services =>
            {
                services.RemoveAll<TimeProvider>(); services.AddSingleton<TimeProvider>(Clock);
                services.RemoveAll<IModelProvider>(); services.AddSingleton<IModelProvider>(Model);
                services.RemoveAll<IEntitlementResolver>(); services.AddSingleton<IEntitlementResolver>(Entitlements);
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
    }
}
