using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.EntityFrameworkCore;
using Sedno.Application;

namespace Sedno.Infrastructure;

public interface IIdentityAccountDeletion
{
    Task DeleteAsync(string uid, CancellationToken ct);
    Task<bool> ExistsAsync(string uid, CancellationToken ct);
}

public sealed class FirebaseAccountDeletion(HttpClient client, IPlayAccessTokenSource tokens, string project) : IIdentityAccountDeletion
{
    public async Task<bool> ExistsAsync(string uid, CancellationToken ct)
    {
        using var request = new HttpRequestMessage(HttpMethod.Post,
            $"https://identitytoolkit.googleapis.com/v1/projects/{Uri.EscapeDataString(project)}/accounts:lookup");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", await tokens.GetAsync(ct));
        request.Content = JsonContent.Create(new { localId = new[] { uid } });
        using var response = await client.SendAsync(request, ct);
        response.EnsureSuccessStatusCode();
        using var body = JsonDocument.Parse(await response.Content.ReadAsStringAsync(ct));
        return body.RootElement.TryGetProperty("users", out var users) &&
            users.EnumerateArray().Any(user => user.GetProperty("localId").GetString() == uid &&
                (!user.TryGetProperty("disabled", out var disabled) || !disabled.GetBoolean()));
    }

    public async Task DeleteAsync(string uid, CancellationToken ct)
    {
        using var request = new HttpRequestMessage(HttpMethod.Post,
            $"https://identitytoolkit.googleapis.com/v1/projects/{Uri.EscapeDataString(project)}/accounts:delete");
        request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", await tokens.GetAsync(ct));
        request.Content = JsonContent.Create(new { localId = uid });
        using var response = await client.SendAsync(request, ct);
        if (response.IsSuccessStatusCode) return;
        // A retry after Firebase succeeded but the database commit failed is safe.
        if (response.StatusCode == System.Net.HttpStatusCode.BadRequest)
        {
            using var body = JsonDocument.Parse(await response.Content.ReadAsStringAsync(ct));
            if (body.RootElement.TryGetProperty("error", out var error) &&
                error.TryGetProperty("message", out var message) && message.GetString() == "USER_NOT_FOUND") return;
        }
        throw new InvalidOperationException("Identity deletion failed.");
    }
}

public sealed class UnavailableAccountDeletion : IIdentityAccountDeletion
{
    public Task<bool> ExistsAsync(string uid, CancellationToken ct) => Task.FromResult(false);
    public Task DeleteAsync(string uid, CancellationToken ct) =>
        throw new InvalidOperationException("Identity deletion is not configured.");
}

public sealed class AccountDeletionService(AppDbContext db, IIdentityAccountDeletion identity)
{
    public async Task DeleteAsync(SessionIdentity session, CancellationToken ct)
    {
        if (session.AccountId is not Guid accountId) throw new InvalidOperationException("Account required.");
        await using var transaction = await db.Database.BeginTransactionAsync(ct);
        // Same locks and ordering as linking/quota and billing, so deletion cannot leave linked rows behind.
        await db.Database.ExecuteSqlRawAsync("SELECT pg_advisory_xact_lock(1748392201)", ct);
        await db.Database.ExecuteSqlRawAsync("SELECT pg_advisory_xact_lock(1748392202)", ct);
        var account = await db.Accounts.SingleOrDefaultAsync(x => x.Id == accountId, ct);
        if (account is null) return;
        await identity.DeleteAsync(account.FirebaseUid, ct);
        await db.Sessions.Where(x => x.AccountId == accountId).ExecuteDeleteAsync(ct);
        // Requests and all sessions on linked identities cascade. Purchases cascade from account.
        await db.Identities.Where(x => x.AccountId == accountId).ExecuteDeleteAsync(ct);
        await db.Accounts.Where(x => x.Id == accountId).ExecuteDeleteAsync(ct);
        await transaction.CommitAsync(ct);
    }
}
