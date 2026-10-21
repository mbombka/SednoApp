using Sedno.Infrastructure;
using Xunit;

namespace Sedno.UnitTests;

public sealed class FirebaseAccountAccessTests
{
    private sealed class Clock : TimeProvider
    {
        public DateTimeOffset Now = new(2026, 10, 20, 12, 0, 0, TimeSpan.Zero);
        public override DateTimeOffset GetUtcNow() => Now;
    }
    private sealed class Accounts : IIdentityAccountDeletion
    {
        public int Calls;
        public IdentityAccountStatus Status = new(true, 0);
        public bool Fail;
        public TaskCompletionSource? Gate;
        public async Task<IdentityAccountStatus> GetStatusAsync(string uid, CancellationToken ct)
        {
            Interlocked.Increment(ref Calls);
            if (Gate is not null) await Gate.Task;
            if (Fail) throw new HttpRequestException();
            return Status;
        }
        public Task DeleteAsync(string uid, CancellationToken ct) => Task.CompletedTask;
    }

    [Fact]
    public async Task CacheHasAnAbsoluteFiveMinuteBoundaryAndNeverServesStaleOnFailure()
    {
        var clock = new Clock();
        var accounts = new Accounts();
        using var access = new FirebaseAccountAccess(accounts, clock);
        Assert.True((await access.GetAsync("user", default)).Allows(1));
        clock.Now += TimeSpan.FromMinutes(4);
        Assert.True((await access.GetAsync("user", default)).Allows(1));
        clock.Now += TimeSpan.FromSeconds(59.999);
        Assert.True((await access.GetAsync("user", default)).Allows(1));
        Assert.Equal(1, accounts.Calls);
        accounts.Fail = true;
        clock.Now += TimeSpan.FromMilliseconds(1);
        await Assert.ThrowsAsync<HttpRequestException>(() => access.GetAsync("user", default));
        await Assert.ThrowsAsync<HttpRequestException>(() => access.GetAsync("user", default));
        Assert.Equal(3, accounts.Calls);
        accounts.Fail = false;
        accounts.Status = new(false, 0);
        Assert.False((await access.GetAsync("user", default)).Allows(1));
        Assert.Equal(4, accounts.Calls);
    }

    [Fact]
    public async Task ConcurrentChecksAreJoinedAndCancellationDoesNotCancelOtherCallers()
    {
        var accounts = new Accounts { Gate = new(TaskCreationOptions.RunContinuationsAsynchronously) };
        using var access = new FirebaseAccountAccess(accounts, new Clock());
        using var cancellation = new CancellationTokenSource();
        var first = access.GetAsync("user", cancellation.Token);
        var others = Enumerable.Range(0, 20).Select(_ => access.GetAsync("user", default)).ToArray();
        Assert.Equal(1, accounts.Calls);
        cancellation.Cancel();
        await Assert.ThrowsAnyAsync<OperationCanceledException>(() => first);
        accounts.Gate.SetResult();
        Assert.All(await Task.WhenAll(others), status => Assert.True(status.Enabled));
        Assert.Equal(1, accounts.Calls);
        await access.GetFreshAsync("user", default);
        Assert.Equal(2, accounts.Calls);
        // A different account is checked independently, and inactivity does no work.
        await access.GetAsync("other", default);
        Assert.Equal(3, accounts.Calls);
    }

    [Theory]
    [InlineData(true, 100, 99, false)] // Reset password / revoke refresh tokens.
    [InlineData(true, 100, 100, true)]
    [InlineData(false, 0, 100, false)] // Disabled / deleted.
    [InlineData(true, 0, 0, false)] // Legacy session without auth_time.
    public void StatusChecksOriginalAuthenticationTime(bool enabled, long validSince, long authTime, bool allowed) =>
        Assert.Equal(allowed, new IdentityAccountStatus(enabled, validSince).Allows(authTime));
}
