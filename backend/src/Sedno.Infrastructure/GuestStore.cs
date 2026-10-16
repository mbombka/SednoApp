using System.Security.Cryptography;
using System.Text;
using Microsoft.EntityFrameworkCore;
using Sedno.Application;
using Sedno.Domain;

namespace Sedno.Infrastructure;

public sealed class GuestStore(AppDbContext db, IUsageStore usage, TimeProvider clock, byte[] credentialKey, IIdentityAccountDeletion identityAccounts) : IGuestStore
{
    public async Task<GuestSessionDto> CreateAsync(string installationId, CancellationToken ct)
    {
        var now = clock.GetUtcNow();
        var identity = new GuestIdentity
        {
            Id = Guid.NewGuid(), CreatedAt = now,
            InstallationHash = Convert.ToHexString(HMACSHA256.HashData(credentialKey, Encoding.UTF8.GetBytes(installationId)))
        };
        var secret = Base64Url(RandomNumberGenerator.GetBytes(32));
        var session = new GuestSession
        {
            Id = Guid.NewGuid(), Identity = identity, CreatedAt = now, ExpiresAt = now.AddDays(90),
            CredentialHash = Hash(secret)
        };
        db.Sessions.Add(session);
        await db.SaveChangesAsync(ct);
        return new($"{session.Id:N}.{secret}", new(identity.Id.ToString(), "guest"),
            await usage.GetQuotaAsync(identity.Id, ct));
    }

    public async Task<SessionIdentity?> AuthenticateAsync(string credential, CancellationToken ct)
    {
        var parts = credential.Split('.', 2);
        if (parts.Length != 2 || !Guid.TryParseExact(parts[0], "N", out var sessionId) || parts[1].Length != 43)
            return null;
        var session = await db.Sessions.AsNoTracking().SingleOrDefaultAsync(x => x.Id == sessionId, ct);
        if (session is null || session.ExpiresAt <= clock.GetUtcNow()) return null;
        var given = Convert.FromHexString(Hash(parts[1]));
        var stored = Convert.FromHexString(session.CredentialHash);
        return CryptographicOperations.FixedTimeEquals(given, stored)
            ? new(session.AccountId is null ? session.IdentityId :
                await db.Accounts.AsNoTracking().Where(x => x.Id == session.AccountId)
                    .Select(x => x.PrimaryIdentityId).SingleAsync(ct), session.AccountId, session.Id)
            : null;
    }

    public async Task<AuthenticatedSessionDto?> LinkAsync(SessionIdentity guest, VerifiedIdentity verified, CancellationToken ct)
    {
        if (guest.AccountId is not null || verified.Uid.Length is < 1 or > 128 ||
            verified.Provider is not ("google" or "email")) return null;
        await using var transaction = await db.Database.BeginTransactionAsync(ct);
        // Serialize Firebase lookup/deletion only for this UID. Network latency must
        // not hold the exclusive quota-topology lock for unrelated users.
        await IdentityCoordination.LockAsync(db, verified.Uid, ct);
        if (!await identityAccounts.ExistsAsync(verified.Uid, ct)) return null;
        await db.Database.ExecuteSqlRawAsync("SELECT pg_advisory_xact_lock(1748392201)", ct);
        var identity = await db.Identities.SingleOrDefaultAsync(x => x.Id == guest.IdentityId, ct);
        if (identity is null) return null;
        var account = await db.Accounts.SingleOrDefaultAsync(x => x.FirebaseUid == verified.Uid, ct);
        if (identity.AccountId is not null && identity.AccountId != account?.Id) return null;
        if (account is null)
        {
            account = new VerifiedAccount
            {
                Id = Guid.NewGuid(), FirebaseUid = verified.Uid, Provider = verified.Provider,
                PrimaryIdentityId = identity.Id, CreatedAt = clock.GetUtcNow()
            };
            db.Accounts.Add(account);
        }
        else account.Provider = verified.Provider;
        identity.AccountId = account.Id;
        // A guest bearer must not become an account bearer after linking.
        await db.Sessions.Where(x => x.IdentityId == identity.Id && x.AccountId == null).ExecuteDeleteAsync(ct);
        var secret = Base64Url(RandomNumberGenerator.GetBytes(32));
        var now = clock.GetUtcNow();
        var session = new GuestSession
        {
            Id = Guid.NewGuid(), IdentityId = account.PrimaryIdentityId, AccountId = account.Id,
            CredentialHash = Hash(secret), CreatedAt = now, ExpiresAt = now.AddDays(7)
        };
        db.Sessions.Add(session);
        await db.SaveChangesAsync(ct);
        await transaction.CommitAsync(ct);
        return new($"{session.Id:N}.{secret}", new(account.Id.ToString(), account.Provider),
            await usage.GetQuotaAsync(account.PrimaryIdentityId, ct));
    }

    public Task SignOutAsync(SessionIdentity session, CancellationToken ct) =>
        db.Sessions.Where(x => x.Id == session.SessionId).ExecuteDeleteAsync(ct);

    private string Hash(string value) => Convert.ToHexString(HMACSHA256.HashData(credentialKey, Encoding.UTF8.GetBytes(value)));
    private static string Base64Url(byte[] value) => Convert.ToBase64String(value).TrimEnd('=').Replace('+', '-').Replace('/', '_');
}
