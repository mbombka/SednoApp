using System.Data;
using System.Text.Json;
using System.Text.Json.Serialization;
using Google.Api.Gax;
using Google.Apis.Auth.OAuth2;
using Google.Cloud.Firestore;
using Npgsql;
using Sedno.Domain;
using Sedno.Infrastructure;

namespace Sedno.FirestoreMigration;

public static class MigrationCommand
{
    public static async Task<int> Main(string[] args)
    {
        try
        {
            if (args.Except(new[] { "--apply", "--source-stopped", "--emulator" }).Any())
                throw new InvalidOperationException("Opcje: --apply --source-stopped [--emulator]. Bez --apply wykonywana jest tylko analiza źródła.");
            var connection = Environment.GetEnvironmentVariable("SEDNO_MIGRATION_POSTGRES")
                ?? throw new InvalidOperationException("Ustaw SEDNO_MIGRATION_POSTGRES poza historią poleceń.");
            if (int.TryParse(Environment.GetEnvironmentVariable("SEDNO_MIGRATION_PROXY_PORT"), out var proxyPort))
            {
                var local = new NpgsqlConnectionStringBuilder(connection) { Host = "127.0.0.1", Port = proxyPort };
                connection = local.ConnectionString;
            }
            var snapshot = await ReadAsync(connection);
            Console.WriteLine($"Źródło: konta={snapshot.Accounts.Count}, instalacje={snapshot.Identities.Count}, sesje={snapshot.Sessions.Count}, żądania={snapshot.Requests.Count}, zakupy={snapshot.Purchases.Count}, powiadomienia={snapshot.Notifications.Count}.");
            if (!args.Contains("--apply")) { Console.WriteLine("Analiza zakończona. Nie zmieniono żadnej bazy."); return 0; }
            if (!args.Contains("--source-stopped")) throw new InvalidOperationException("Zatrzymaj API PostgreSQL i jego zadania przed użyciem --source-stopped.");
            var project = Environment.GetEnvironmentVariable("Firestore__ProjectId")
                ?? throw new InvalidOperationException("Ustaw Firestore__ProjectId.");
            if (!args.Contains("--emulator") && !string.IsNullOrEmpty(Environment.GetEnvironmentVariable("FIRESTORE_EMULATOR_HOST")))
                throw new InvalidOperationException("Emulator wymaga jawnego --emulator.");
            var database = new FirestoreDbBuilder
            {
                ProjectId = project, DatabaseId = "(default)",
                Credential = Environment.GetEnvironmentVariable("SEDNO_MIGRATION_ACCESS_TOKEN") is { Length: > 0 } token
                    ? GoogleCredential.FromAccessToken(token) : null,
                EmulatorDetection = args.Contains("--emulator") ? EmulatorDetection.EmulatorOnly : EmulatorDetection.None
            }.Build();
            var count = await new MigrationWriter(new FirestoreStore(database)).ApplyAsync(snapshot, default);
            Console.WriteLine($"Zapisano i zweryfikowano {count} dokumentów. Źródło PostgreSQL pozostaje bez zmian.");
            return 0;
        }
        catch (Exception error)
        {
            // Provider exceptions can contain connection information. Do not print them.
            Console.Error.WriteLine("Migracja nie została zakończona. Sprawdź konfigurację, uprawnienia, zatrzymanie źródła i zgodność bazy docelowej. Nie usuwaj PostgreSQL.");
            Console.Error.WriteLine("Typ błędu: " + error.GetType().Name);
            return 1;
        }
    }

    public static async Task<MigrationSnapshot> ReadAsync(string connectionString)
    {
        await using var connection = new NpgsqlConnection(connectionString);
        await connection.OpenAsync();
        await using var transaction = await connection.BeginTransactionAsync(IsolationLevel.RepeatableRead);
        await using (var readOnly = new NpgsqlCommand("SET TRANSACTION READ ONLY", connection, transaction)) await readOnly.ExecuteNonQueryAsync();
        var options = new JsonSerializerOptions();
        options.Converters.Add(new JsonStringEnumConverter());
        async Task<List<T>> Rows<T>(string table)
        {
            // Table names are fixed literals below, never CLI input.
            await using var command = new NpgsqlCommand($"SELECT row_to_json(t)::text FROM {table} t", connection, transaction);
            await using var reader = await command.ExecuteReaderAsync();
            var rows = new List<T>();
            while (await reader.ReadAsync()) rows.Add(JsonSerializer.Deserialize<T>(reader.GetString(0), options)!);
            return rows;
        }
        var snapshot = new MigrationSnapshot
        {
            Identities = await Rows<GuestIdentity>("guest_identities"), Sessions = await Rows<GuestSession>("guest_sessions"),
            Accounts = await Rows<VerifiedAccount>("verified_accounts"), Requests = await Rows<SimplificationRecord>("simplification_requests"),
            Purchases = await Rows<PlayPurchase>("play_purchases"), Notifications = await Rows<PlayNotification>("play_notifications")
        };
        await transaction.CommitAsync();
        return snapshot;
    }

}
