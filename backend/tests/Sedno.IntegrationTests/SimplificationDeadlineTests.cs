using System.Net;
using System.Net.Http.Json;
using Microsoft.AspNetCore.TestHost;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.DependencyInjection.Extensions;
using Sedno.Application;
using Sedno.Infrastructure;
using Xunit;

namespace Sedno.IntegrationTests;

[Collection("backend")]
public sealed class SimplificationDeadlineTests(BackendFixture fixture)
{
    private sealed class DeadlineClock(DateTimeOffset now) : TimeProvider
    {
        public Action? Expire;
        public override DateTimeOffset GetUtcNow() => now;
        public override ITimer CreateTimer(TimerCallback callback, object? state, TimeSpan due, TimeSpan period)
        {
            if (due == TimeSpan.FromSeconds(9)) Expire = () => callback(state);
            return new Stub();
        }
        private sealed class Stub : ITimer
        {
            public bool Change(TimeSpan dueTime, TimeSpan period) => true;
            public void Dispose() { }
            public ValueTask DisposeAsync() => ValueTask.CompletedTask;
        }
    }
    private sealed class Model(bool hangs) : IModelProvider
    {
        public TaskCompletionSource Entered { get; } = new(TaskCreationOptions.RunContinuationsAsynchronously);
        public async Task<string> SimplifyAsync(string text, CancellationToken ct)
        {
            Entered.TrySetResult();
            if (hangs) await Task.Delay(Timeout.InfiniteTimeSpan, ct);
            throw new SimplificationTimeoutException();
        }
    }
    [Theory]
    [InlineData(false)]
    [InlineData(true)]
    public async Task ProviderTimeoutAndOverallDeadlineReturnExplicit504(bool overall)
    {
        var clock = new DeadlineClock(fixture.Clock.GetUtcNow());
        var model = new Model(overall);
        await using var factory = fixture.Factory.WithWebHostBuilder(web => web.ConfigureTestServices(services =>
        {
            services.RemoveAll<TimeProvider>(); services.AddSingleton<TimeProvider>(clock);
            services.RemoveAll<IModelProvider>(); services.AddSingleton<IModelProvider>(model);
        }));
        using var client = factory.CreateClient();
        var guest = await (await client.PostAsJsonAsync("/v1/guest-sessions", new { installationId = Guid.NewGuid().ToString() }))
            .Content.ReadFromJsonAsync<GuestSessionDto>();
        client.DefaultRequestHeaders.Authorization = new("Bearer", guest!.AccessToken);
        var request = client.PostAsJsonAsync("/v1/simplifications", new { requestId = "deadline", text = "Tekst" });
        await model.Entered.Task.WaitAsync(TimeSpan.FromSeconds(5));
        if (overall) clock.Expire!();
        using var response = await request.WaitAsync(TimeSpan.FromSeconds(5));
        Assert.Equal(HttpStatusCode.GatewayTimeout, response.StatusCode);
        Assert.Contains("simplification_timeout", await response.Content.ReadAsStringAsync());
        if (!overall)
        {
            var quota = await client.GetFromJsonAsync<QuotaDto>("/v1/quota");
            Assert.Equal(5, quota!.Remaining);
        }
    }
    private sealed class CancelledFirestoreUsage(IUsageStore inner, TaskCompletionSource entered) : IUsageStore
    {
        public Task<QuotaDto> GetQuotaAsync(Guid id, CancellationToken ct) => inner.GetQuotaAsync(id, ct);
        public async Task<ReservationOutcome> ReserveAsync(Guid id, string request, string fingerprint, CancellationToken ct)
        {
            entered.TrySetResult();
            try { await Task.Delay(Timeout.InfiniteTimeSpan, ct); }
            catch (OperationCanceledException) { throw new Grpc.Core.RpcException(new(Grpc.Core.StatusCode.Cancelled, "synthetic cancellation")); }
            throw new InvalidOperationException();
        }
        public Task<bool> CompleteAsync(Guid id, string request, CancellationToken ct) => inner.CompleteAsync(id, request, ct);
        public Task FailAsync(Guid id, string request, CancellationToken ct) => inner.FailAsync(id, request, ct);
        public Task<RequestStatusDto?> GetStatusAsync(Guid id, string request, CancellationToken ct) => inner.GetStatusAsync(id, request, ct);
    }

    [Fact]
    public async Task FirestoreCancellationAtOverallDeadlineReturns504()
    {
        var clock = new DeadlineClock(fixture.Clock.GetUtcNow());
        var entered = new TaskCompletionSource(TaskCreationOptions.RunContinuationsAsynchronously);
        await using var factory = fixture.Factory.WithWebHostBuilder(web => web.ConfigureTestServices(services =>
        {
            services.RemoveAll<TimeProvider>(); services.AddSingleton<TimeProvider>(clock);
            services.RemoveAll<IUsageStore>();
            services.AddScoped<IUsageStore>(sp => new CancelledFirestoreUsage(
                new UsageStore(sp.GetRequiredService<FirestoreStore>(), fixture.Entitlements, clock), entered));
        }));
        using var client = factory.CreateClient();
        var guest = await (await client.PostAsJsonAsync("/v1/guest-sessions", new { installationId = Guid.NewGuid().ToString() }))
            .Content.ReadFromJsonAsync<GuestSessionDto>();
        client.DefaultRequestHeaders.Authorization = new("Bearer", guest!.AccessToken);
        var request = client.PostAsJsonAsync("/v1/simplifications", new { requestId = "database-deadline", text = "Tekst" });
        await entered.Task.WaitAsync(TimeSpan.FromSeconds(5));
        clock.Expire!();
        using var response = await request.WaitAsync(TimeSpan.FromSeconds(5));
        Assert.Equal(HttpStatusCode.GatewayTimeout, response.StatusCode);
        Assert.Contains("simplification_timeout", await response.Content.ReadAsStringAsync());
    }

}
