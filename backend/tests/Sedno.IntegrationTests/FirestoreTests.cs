using System.Net.Http.Json;
using Google.Api.Gax;
using Google.Cloud.Firestore;
using Microsoft.AspNetCore.Hosting;
using Microsoft.Extensions.DependencyInjection;
using Sedno.Application;
using Sedno.Domain;
using Sedno.FirestoreMigration;
using Sedno.Infrastructure;
using Xunit;

namespace Sedno.IntegrationTests;

[Collection("backend")]
public sealed class FirestoreTests(BackendFixture fixture)
{
    private FirestoreStore Isolated() => new(new FirestoreDbBuilder
    {
        ProjectId = "demo-migration-" + Guid.NewGuid().ToString("N")[..12],
        EmulatorDetection = EmulatorDetection.EmulatorOnly
    }.Build());

    [Fact]
    public async Task ConcurrentSessionsOnOneInstallationCannotOverspend()
    {
        var installation = Guid.NewGuid().ToString();
        var sessions = new List<GuestSessionDto>();
        for (var i = 0; i < 10; i++)
        {
            using var client = fixture.Factory.CreateClient();
            sessions.Add((await (await client.PostAsJsonAsync("/v1/guest-sessions", new { installationId = installation })).Content.ReadFromJsonAsync<GuestSessionDto>())!);
        }
        var outcomes = await Task.WhenAll(sessions.Select(async session =>
        {
            using var scope = fixture.Factory.Services.CreateScope();
            var replica = new FirestoreStore(scope.ServiceProvider.GetRequiredService<FirestoreDb>());
            return await new UsageStore(replica, new FreeEntitlementResolver(), fixture.Clock)
                .ReserveAsync(Guid.Parse(session.Account.Id), "parallel", "same", default);
        }));
        Assert.Equal(5, outcomes.Count(x => x.Kind == "reserved"));
        Assert.Equal(5, outcomes.Count(x => x.Kind == "quota_exceeded"));
    }

    [Fact]
    public async Task PollingRequestWhileCompletingUsesConsistentTransactionOrder()
    {
        var db = Isolated();
        var identity = new GuestIdentity { Id = Guid.NewGuid(), InstallationHash = "polling", CreatedAt = fixture.Clock.GetUtcNow() };
        await db.PutAsync(db.Identities.Document(FirestoreStore.Id(identity.Id)), identity);
        var usage = new UsageStore(db, new FreeEntitlementResolver(), fixture.Clock);
        using var timeout = new CancellationTokenSource(TimeSpan.FromSeconds(10));
        Assert.Equal("reserved", (await usage.ReserveAsync(identity.Id, "polling", "fingerprint", timeout.Token)).Kind);
        var polling = Enumerable.Range(0, 6).Select(_ => (Task)usage.GetStatusAsync(identity.Id, "polling", timeout.Token)).ToList();
        polling.Add(usage.CompleteAsync(identity.Id, "polling", timeout.Token));
        await Task.WhenAll(polling);
        var status = await usage.GetStatusAsync(identity.Id, "polling", timeout.Token);
        Assert.Equal("succeeded", status!.Status);
        Assert.Equal(1, status.Quota.Used);
        Assert.Equal(4, status.Quota.Remaining);
    }

    [Fact]
    public async Task CleanupRemovesExpiredMetadataAndKeepsActiveData()
    {
        var db = Isolated();
        var now = fixture.Clock.GetUtcNow();
        var oldIdentity = new GuestIdentity { Id = Guid.NewGuid(), InstallationHash = "old", CreatedAt = now.AddDays(-100) };
        var active = new GuestIdentity { Id = Guid.NewGuid(), InstallationHash = "active", CreatedAt = now.AddDays(-100) };
        foreach (var identity in new[] { oldIdentity, active }) await db.PutAsync(db.Identities.Document(FirestoreStore.Id(identity.Id)), identity);
        var expired = new GuestSession { Id = Guid.NewGuid(), IdentityId = oldIdentity.Id, CreatedAt = now.AddDays(-100), ExpiresAt = now };
        var valid = new GuestSession { Id = Guid.NewGuid(), IdentityId = active.Id, CreatedAt = now, ExpiresAt = now.AddDays(1) };
        foreach (var session in new[] { expired, valid }) await db.PutAsync(db.Sessions.Document(FirestoreStore.Id(session.Id)), session);
        await db.PutAsync(db.Request(oldIdentity.Id, "old"), new SimplificationRecord { IdentityId = oldIdentity.Id, RequestId = "old", CreatedAt = now.AddDays(-9) });
        var recent = new SimplificationRecord { IdentityId = active.Id, RequestId = "recent", CreatedAt = now.AddDays(-1) };
        await db.PutAsync(db.Request(active.Id, "recent"), recent);
        var oldDay = db.Day("old", QuotaPolicy.Day(now.AddDays(-9)));
        await db.PutAsync(oldDay, new DailyUsage { InstallationHash = "old", ExpiresAt = now });
        await db.PutAsync(db.Leases.Document("abandoned"), new { Owner = "gone", ExpiresAt = now.AddMinutes(-1) });
        var deletion = new AccountDeletionService(db, fixture.IdentityAccounts, fixture.Clock);
        var cleanup = new MetadataCleanup(db, fixture.Clock, deletion);
        await cleanup.RunAsync(default);
        await cleanup.RunAsync(default); // Idempotent reruns.
        Assert.Null(await db.GetAsync<GuestIdentity>(db.Identities.Document(FirestoreStore.Id(oldIdentity.Id))));
        Assert.NotNull(await db.GetAsync<GuestIdentity>(db.Identities.Document(FirestoreStore.Id(active.Id))));
        Assert.Null(await db.GetAsync<GuestSession>(db.Sessions.Document(FirestoreStore.Id(expired.Id))));
        Assert.NotNull(await db.GetAsync<GuestSession>(db.Sessions.Document(FirestoreStore.Id(valid.Id))));
        Assert.False((await oldDay.GetSnapshotAsync()).Exists);
        Assert.False((await db.Leases.Document("abandoned").GetSnapshotAsync()).Exists);
        Assert.NotNull(await db.GetAsync<SimplificationRecord>(db.Request(active.Id, "recent")));
    }

    [Fact]
    public async Task MigrationPreservesCredentialsAccountUsageReservationsAndPurchases()
    {
        var db = Isolated();
        var now = fixture.Clock.GetUtcNow();
        var first = new GuestIdentity { Id = Guid.NewGuid(), InstallationHash = "installation-a", CreatedAt = now };
        var second = new GuestIdentity { Id = Guid.NewGuid(), InstallationHash = "installation-b", CreatedAt = now };
        var account = new VerifiedAccount { Id = Guid.NewGuid(), FirebaseUid = "migration-user", PrimaryIdentityId = first.Id, CreatedAt = now };
        first.AccountId = second.AccountId = account.Id;
        var session = new GuestSession { Id = Guid.NewGuid(), IdentityId = first.Id, AccountId = account.Id, CredentialHash = new string('A', 64), ExpiresAt = now.AddDays(7), CreatedAt = now };
        var snapshot = new MigrationSnapshot
        {
            Identities = [first, second], Accounts = [account], Sessions = [session],
            Requests = [
                new() { IdentityId = first.Id, RequestId = "success", State = RequestState.Succeeded, ReservationDay = QuotaPolicy.Day(now), CreatedAt = now },
                new() { IdentityId = second.Id, RequestId = "pending", State = RequestState.Processing, ReservationDay = QuotaPolicy.Day(now), ReservationExpiresAt = now.AddMinutes(5), CreatedAt = now },
                new() { IdentityId = second.Id, RequestId = "expired", State = RequestState.Processing, ReservationDay = QuotaPolicy.Day(now), ReservationExpiresAt = now.AddMinutes(-1), CreatedAt = now }
            ],
            Purchases = [new() { TokenHash = "purchase-hash", ProtectedToken = "encrypted-preserved", AccountId = account.Id, State = "SUBSCRIPTION_STATE_ACTIVE", VerifiedAt = now, ExpiresAt = now.AddDays(30) }],
            Notifications = [new() { Id = "notification/id", ProcessedAt = now }]
        };
        var writer = new MigrationWriter(db);
        Assert.True(await db.ReadyAsync(default));
        Assert.False(await new FirestoreStore(db.Database, requireMigration: true).ReadyAsync(default));
        var count = await writer.ApplyAsync(snapshot, default);
        Assert.True(count > 10);
        Assert.True(await db.ReadyAsync(default));
        var quota = await new UsageStore(db, new FreeEntitlementResolver(), fixture.Clock).GetQuotaAsync(first.Id, default);
        Assert.Equal(1, quota.Used);
        Assert.Equal(3, quota.Remaining); // One success and one live reservation, no extra allowance on login.
        Assert.Equal(session.CredentialHash, (await db.GetAsync<GuestSession>(db.Sessions.Document(FirestoreStore.Id(session.Id))))!.CredentialHash);
        Assert.Equal("encrypted-preserved", (await db.GetAsync<PlayPurchase>(db.Purchases.Document("purchase-hash")))!.ProtectedToken);
        Assert.Equal(account.Id, (await db.GetAsync<AccountPointer>(db.Uids.Document(FirestoreStore.Hash(account.FirebaseUid))))!.AccountId);
        await Assert.ThrowsAsync<InvalidOperationException>(() => writer.ApplyAsync(snapshot, default)); // Never overwrite a live target.
        var marker = db.Database.Collection("system").Document("migration");
        await marker.UpdateAsync("InProgress", true); // Simulate an interrupted import with the same source.
        Assert.False(await db.ReadyAsync(default));
        await db.Request(first.Id, "success").DeleteAsync();
        Assert.Equal(count, await writer.ApplyAsync(snapshot, default));
        Assert.True(await db.ReadyAsync(default));
    }

    [Fact]
    public async Task MigrationRefusesNonemptyTarget()
    {
        var db = Isolated();
        await db.PutAsync(db.Identities.Document("existing"), new GuestIdentity { Id = Guid.NewGuid() });
        await Assert.ThrowsAsync<InvalidOperationException>(() => new MigrationWriter(db).ApplyAsync(new(), default));
        Assert.True((await db.Identities.Document("existing").GetSnapshotAsync()).Exists);
    }

    [Fact]
    public void ProductionRejectsEmulatorEvenWhenEnvironmentVariableIsSet()
    {
        using var factory = fixture.Factory.WithWebHostBuilder(web => web.UseEnvironment("Production"));
        var error = Assert.Throws<InvalidOperationException>(() => factory.CreateClient());
        Assert.Contains("Development-only", error.Message);
    }
}
