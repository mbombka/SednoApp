using DotNet.Testcontainers.Builders;
using Npgsql;
using Sedno.Domain;
using Sedno.FirestoreMigration;
using Xunit;

namespace Sedno.IntegrationTests;

// PostgreSQL is used only to verify the one-off legacy importer, never by the API fixture.
[Collection("backend")]
public sealed class MigrationSourceTests
{
    [Fact]
    public async Task ReadsLegacySqlWithoutChangingSourceAndPreservesEnumAndUtcDates()
    {
        await using var postgres = new ContainerBuilder("postgres:17-alpine")
            .WithEnvironment("POSTGRES_DB", "sedno").WithEnvironment("POSTGRES_USER", "sedno")
            .WithEnvironment("POSTGRES_PASSWORD", "synthetic-migration-test")
            .WithPortBinding(5432, true)
            .WithWaitStrategy(Wait.ForUnixContainer().UntilCommandIsCompleted("pg_isready", "-h", "127.0.0.1", "-U", "sedno"))
            .Build();
        await postgres.StartAsync();
        var connectionString = new NpgsqlConnectionStringBuilder
        {
            Host = postgres.Hostname, Port = postgres.GetMappedPublicPort(5432), Database = "sedno",
            Username = "sedno", Password = "synthetic-migration-test"
        }.ConnectionString;
        await using var connection = new NpgsqlConnection(connectionString);
        await connection.OpenAsync();
        await using var seed = new NpgsqlCommand("""
            CREATE TABLE guest_identities ("Id" uuid, "InstallationHash" text, "CreatedAt" timestamptz, "AccountId" uuid);
            CREATE TABLE verified_accounts ("Id" uuid, "FirebaseUid" text, "Provider" text, "PrimaryIdentityId" uuid, "CreatedAt" timestamptz);
            CREATE TABLE guest_sessions ("Id" uuid, "IdentityId" uuid, "CredentialHash" text, "CreatedAt" timestamptz, "ExpiresAt" timestamptz, "AccountId" uuid);
            CREATE TABLE simplification_requests ("IdentityId" uuid, "RequestId" text, "Fingerprint" text, "State" text, "CreatedAt" timestamptz, "ReservationDay" date, "ReservationExpiresAt" timestamptz, "FinishedAt" timestamptz);
            CREATE TABLE play_purchases ("TokenHash" text, "ProtectedToken" text, "AccountId" uuid, "State" text, "ExpiresAt" timestamptz, "Revoked" bool, "VerifiedAt" timestamptz);
            CREATE TABLE play_notifications ("Id" text, "ProcessedAt" timestamptz);
            INSERT INTO guest_identities VALUES ('11111111-1111-1111-1111-111111111111', 'installation-hmac', '2026-10-19T12:34:56.123456Z', null);
            INSERT INTO guest_sessions VALUES ('22222222-2222-2222-2222-222222222222', '11111111-1111-1111-1111-111111111111', 'credential-hmac', '2026-10-19T12:34:56Z', '2026-10-26T12:34:56Z', null);
            INSERT INTO simplification_requests VALUES ('11111111-1111-1111-1111-111111111111', 'request', 'fingerprint', 'Succeeded', '2026-10-19T12:34:56Z', '2026-10-19', '2026-10-19T12:39:56Z', '2026-10-19T12:34:58Z');
            INSERT INTO play_notifications VALUES ('notification', '2026-10-19T12:34:56Z');
            """, connection);
        await seed.ExecuteNonQueryAsync();
        var first = await MigrationCommand.ReadAsync(connectionString);
        var second = await MigrationCommand.ReadAsync(connectionString);
        Assert.Single(first.Identities);
        Assert.Single(second.Identities);
        Assert.Single(first.Sessions);
        var record = Assert.Single(first.Requests);
        Assert.Equal(RequestState.Succeeded, record.State);
        Assert.Equal(new DateOnly(2026, 10, 19), record.ReservationDay);
        Assert.Equal(TimeSpan.Zero, first.Identities[0].CreatedAt.Offset);
        Assert.Equal(1234560, first.Identities[0].CreatedAt.Ticks % TimeSpan.TicksPerSecond);
        Assert.Equal("credential-hmac", first.Sessions[0].CredentialHash);
        Assert.Single(first.Notifications);
        Assert.Empty(first.Accounts);
        Assert.Empty(first.Purchases);
    }
}
