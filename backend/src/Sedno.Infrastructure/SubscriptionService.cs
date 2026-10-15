using System.Security.Cryptography;
using System.Text;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.EntityFrameworkCore;
using Sedno.Application;
using Sedno.Domain;

namespace Sedno.Infrastructure;

public sealed class SubscriptionService(AppDbContext db, IPlayBillingClient play,
    IDataProtectionProvider protection, TimeProvider clock) : IEntitlementResolver
{
    private readonly IDataProtector _protector = protection.CreateProtector("Sedno.PlayPurchase.v1");
    public static string Binding(Guid accountId) => Hash("sedno-account:" + accountId.ToString("N"));
    private static string Hash(string token) => Convert.ToHexString(SHA256.HashData(Encoding.UTF8.GetBytes(token)));

    public async Task<SubscriptionDto> CurrentAsync(Guid accountId, CancellationToken ct)
    {
        var rows = await db.Purchases.AsNoTracking().Where(x => x.AccountId == accountId).ToListAsync(ct);
        PlaySubscription? best = null;
        foreach (var row in rows.Where(x => !x.Revoked))
        {
            var status = await play.GetAsync(_protector.Unprotect(row.ProtectedToken), ct);
            if (status.AccountBinding != Binding(accountId)) continue;
            if (status.Entitled(clock.GetUtcNow()) && !status.Acknowledged)
                await play.AcknowledgeAsync(_protector.Unprotect(row.ProtectedToken), ct);
            if (best is null || (!best.Entitled(clock.GetUtcNow()) && status.Entitled(clock.GetUtcNow())) ||
                (status.Entitled(clock.GetUtcNow()) == best.Entitled(clock.GetUtcNow()) && status.ExpiresAt > best.ExpiresAt)) best = status;
        }
        return new(best?.State ?? "none", best?.Entitled(clock.GetUtcNow()) == true, best?.ExpiresAt, Binding(accountId));
    }
    public async Task<bool> HasSubscriptionAsync(Guid identityId, CancellationToken ct)
    {
        var accountId = await db.Identities.Where(x => x.Id == identityId).Select(x => x.AccountId).SingleAsync(ct);
        if (accountId is null) return false;
        // Refresh against Google on every quota decision: missed RTDN cannot prolong refunded access.
        return (await CurrentAsync(accountId.Value, ct)).Active;
    }
    public async Task<SubscriptionDto> VerifyAsync(Guid accountId, string token, CancellationToken ct)
    {
        await using var transaction = await db.Database.BeginTransactionAsync(ct);
        await LockAsync(ct);
        var status = await UpdateAsync(accountId, token, ct);
        await db.SaveChangesAsync(ct);
        await transaction.CommitAsync(ct);
        return status;
    }
    public async Task NotifyAsync(string messageId, string token, CancellationToken ct)
    {
        await using var transaction = await db.Database.BeginTransactionAsync(ct);
        await LockAsync(ct);
        if (await db.PlayNotifications.AnyAsync(x => x.Id == messageId, ct)) return;
        var hash = Hash(token);
        var row = await db.Purchases.SingleOrDefaultAsync(x => x.TokenHash == hash, ct);
        var verified = await play.GetAsync(token, ct);
        var account = row is null
            ? await db.Accounts.AsNoTracking().ToListAsync(ct)
            : [];
        var accountId = row?.AccountId ?? account.SingleOrDefault(x => Binding(x.Id) == verified.AccountBinding)?.Id;
        // Do not acknowledge unknown ownership: retry until client/account association is available.
        if (accountId is null) throw new InvalidOperationException("Unknown purchase owner.");
        await UpdateAsync(accountId.Value, token, ct);
        db.PlayNotifications.Add(new() { Id = messageId, ProcessedAt = clock.GetUtcNow() });
        await db.SaveChangesAsync(ct);
        await transaction.CommitAsync(ct);
    }
    private async Task<SubscriptionDto> UpdateAsync(Guid accountId, string token, CancellationToken ct)
    {
        var status = await play.GetAsync(token, ct);
        var hash = Hash(token);
        var row = await db.Purchases.SingleOrDefaultAsync(x => x.TokenHash == hash, ct);
        if (status.AccountBinding != Binding(accountId) &&
            !(row?.AccountId == accountId && status.AccountBinding is null && status.State == "SUBSCRIPTION_STATE_EXPIRED"))
            throw new InvalidOperationException("Purchase owner mismatch.");
        if (row is not null && row.AccountId != accountId) throw new InvalidOperationException("Purchase already owned.");
        if (row is null)
        {
            row = new() { TokenHash = hash, ProtectedToken = _protector.Protect(token), AccountId = accountId };
            db.Purchases.Add(row);
        }
        row.State = status.State;
        row.ExpiresAt = status.ExpiresAt;
        if (!row.Revoked && status.Entitled(clock.GetUtcNow()) && !status.Acknowledged)
            await play.AcknowledgeAsync(token, ct);
        if (status.LinkedToken is not null && status.Entitled(clock.GetUtcNow()))
        {
            var oldHash = Hash(status.LinkedToken);
            var old = await db.Purchases.SingleOrDefaultAsync(x => x.TokenHash == oldHash, ct);
            if (old is not null)
            {
                if (old.AccountId != accountId) throw new InvalidOperationException("Linked owner mismatch.");
                old.Revoked = true;
            }
        }
        return new(row.Revoked ? "revoked" : status.State,
            !row.Revoked && status.Entitled(clock.GetUtcNow()), status.ExpiresAt, Binding(accountId));
    }
    private Task LockAsync(CancellationToken ct) => db.Database.ExecuteSqlRawAsync("SELECT pg_advisory_xact_lock(1748392202)", ct);
}
