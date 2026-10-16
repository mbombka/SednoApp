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
        // This endpoint is refreshed in the background by the app, never by quota checks.
        await using var transaction = await db.Database.BeginTransactionAsync(ct);
        await BillingCoordination.AccountAsync(db, accountId, ct);
        var rows = await db.Purchases.AsNoTracking().Where(x => x.AccountId == accountId && !x.Revoked).ToListAsync(ct);
        SubscriptionDto? best = null;
        foreach (var row in rows)
        {
            var status = await UpdateAsync(accountId, _protector.Unprotect(row.ProtectedToken), ct);
            if (best is null || (!best.Active && status.Active) ||
                (status.Active == best.Active && status.ExpiresAt > best.ExpiresAt)) best = status;
        }
        await db.SaveChangesAsync(ct);
        await transaction.CommitAsync(ct);
        return best ?? new("none", false, null, Binding(accountId));
    }

    // Bounds stale access if an RTDN notification is missed. Refresh never extends
    // the Google expiry time; a stale/missing verification falls back to the free tier.
    public static readonly TimeSpan VerificationLifetime = TimeSpan.FromMinutes(15);

    public async Task<bool> HasSubscriptionAsync(Guid identityId, CancellationToken ct)
    {
        var accountId = await db.Identities.Where(x => x.Id == identityId).Select(x => x.AccountId).SingleAsync(ct);
        if (accountId is null) return false;
        var now = clock.GetUtcNow();
        var oldest = now - VerificationLifetime;
        return await db.Purchases.AsNoTracking().AnyAsync(x => x.AccountId == accountId && !x.Revoked &&
            x.VerifiedAt > oldest && x.VerifiedAt <= now && x.ExpiresAt > now &&
            (x.State == "SUBSCRIPTION_STATE_ACTIVE" || x.State == "SUBSCRIPTION_STATE_IN_GRACE_PERIOD" ||
             x.State == "SUBSCRIPTION_STATE_CANCELED"), ct);
    }
    public async Task<SubscriptionDto> VerifyAsync(Guid accountId, string token, CancellationToken ct)
    {
        await using var transaction = await db.Database.BeginTransactionAsync(ct);
        await BillingCoordination.TokenAsync(db, token, ct);
        await BillingCoordination.AccountAsync(db, accountId, ct);
        var status = await UpdateAsync(accountId, token, ct);
        await db.SaveChangesAsync(ct);
        await transaction.CommitAsync(ct);
        return status;
    }
    public async Task NotifyAsync(string messageId, string token, CancellationToken ct)
    {
        await using var transaction = await db.Database.BeginTransactionAsync(ct);
        await BillingCoordination.NotificationAsync(db, messageId, ct);
        if (await db.PlayNotifications.AnyAsync(x => x.Id == messageId, ct)) return;
        await BillingCoordination.TokenAsync(db, token, ct);
        var hash = Hash(token);
        var row = await db.Purchases.AsNoTracking().SingleOrDefaultAsync(x => x.TokenHash == hash, ct);
        var verified = await play.GetAsync(token, ct);
        var account = row is null
            ? await db.Accounts.AsNoTracking().ToListAsync(ct)
            : [];
        var accountId = row?.AccountId ?? account.SingleOrDefault(x => Binding(x.Id) == verified.AccountBinding)?.Id;
        // Do not acknowledge unknown ownership: retry until client/account association is available.
        if (accountId is null) throw new InvalidOperationException("Unknown purchase owner.");
        await BillingCoordination.AccountAsync(db, accountId.Value, ct);
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
        row.VerifiedAt = clock.GetUtcNow();
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
}
