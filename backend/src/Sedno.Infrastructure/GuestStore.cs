using System.Security.Cryptography;
using System.Text;
using Sedno.Application;
using Sedno.Domain;

namespace Sedno.Infrastructure;

public sealed class GuestStore(FirestoreStore db, IUsageStore usage, TimeProvider clock, byte[] credentialKey, IIdentityAccountDeletion identityAccounts) : IGuestStore
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
            Id = Guid.NewGuid(), IdentityId = identity.Id, CreatedAt = now,
            ExpiresAt = now.AddDays(90), CredentialHash = Hash(secret)
        };
        var batch = db.Database.StartBatch();
        batch.Create(db.Identities.Document(FirestoreStore.Id(identity.Id)), FirestoreStore.Encode(identity));
        batch.Create(db.Sessions.Document(FirestoreStore.Id(session.Id)), FirestoreStore.Encode(session));
        await batch.CommitAsync(ct);
        return new($"{session.Id:N}.{secret}", new(identity.Id.ToString(), "guest"), await usage.GetQuotaAsync(identity.Id, ct));
    }

    public async Task<SessionIdentity?> AuthenticateAsync(string credential, CancellationToken ct)
    {
        var parts = credential.Split('.', 2);
        if (parts.Length != 2 || !Guid.TryParseExact(parts[0], "N", out var sessionId) || parts[1].Length != 43) return null;
        var session = await db.GetAsync<GuestSession>(db.Sessions.Document(FirestoreStore.Id(sessionId)), ct);
        if (session is null || session.ExpiresAt <= clock.GetUtcNow()) return null;
        if (!CryptographicOperations.FixedTimeEquals(Convert.FromHexString(Hash(parts[1])), Convert.FromHexString(session.CredentialHash))) return null;
        var identity = await db.GetAsync<GuestIdentity>(db.Identities.Document(FirestoreStore.Id(session.IdentityId)), ct);
        if (identity is null) return null;
        // Previously issued guest credentials never acquire account privileges.
        if (session.AccountId is null) return identity.AccountId is null ? new(identity.Id, null, session.Id) : null;
        // Check the session, not the mutable account provider. Older servers could
        // issue account credentials without verifying an email identity.
        if (!session.AccountAccessVerified) return null;
        var account = await db.GetAsync<VerifiedAccount>(db.Accounts.Document(FirestoreStore.Id(session.AccountId.Value)), ct);
        return account is null ? null : new(account.PrimaryIdentityId, account.Id, session.Id);
    }

    public async Task<AuthenticatedSessionDto?> LinkAsync(SessionIdentity guest, VerifiedIdentity verified, CancellationToken ct)
    {
        if ((verified.Provider == "email" && !verified.EmailVerified) || guest.AccountId is not null || verified.Uid.Length is < 1 or > 128 || verified.Provider is not ("google" or "email")) return null;
        await using var lease = await FirestoreLease.AcquireAsync(db, "uid:" + verified.Uid, clock, ct);
        if (!await identityAccounts.ExistsAsync(verified.Uid, ct)) return null;
        var secret = Base64Url(RandomNumberGenerator.GetBytes(32));
        var accountId = Guid.NewGuid();
        var sessionId = Guid.NewGuid();
        var result = await db.Database.RunTransactionAsync(async transaction =>
        {
            await lease.CheckAsync(transaction, ct);
            var identityReference = db.Identities.Document(FirestoreStore.Id(guest.IdentityId));
            var identity = await db.GetAsync<GuestIdentity>(transaction, identityReference, ct);
            var guestSession = await db.GetAsync<GuestSession>(transaction, db.Sessions.Document(FirestoreStore.Id(guest.SessionId)), ct);
            if (identity is null || guestSession is null || guestSession.IdentityId != guest.IdentityId || guestSession.AccountId is not null || guestSession.ExpiresAt <= clock.GetUtcNow()) return null;
            var uidReference = db.Uids.Document(FirestoreStore.Hash(verified.Uid));
            var pointer = await db.GetAsync<AccountPointer>(transaction, uidReference, ct);
            var accountReference = db.Accounts.Document(FirestoreStore.Id(pointer?.AccountId ?? accountId));
            var account = await db.GetAsync<VerifiedAccount>(transaction, accountReference, ct);
            if (pointer is not null && account is null) return null;
            if (account?.Deleting == true || (identity.AccountId is not null && identity.AccountId != account?.Id)) return null;
            account ??= new VerifiedAccount { Id = accountId, FirebaseUid = verified.Uid, PrimaryIdentityId = identity.Id, CreatedAt = clock.GetUtcNow() };
            var oldSessions = await transaction.GetSnapshotAsync(db.Sessions.WhereEqualTo("IdentityId", identity.Id.ToString()).WhereEqualTo("AccountId", null), ct);
            account.Provider = verified.Provider;
            if (!account.InstallationHashes.Contains(identity.InstallationHash)) account.InstallationHashes.Add(identity.InstallationHash);
            identity.AccountId = account.Id;
            var now = clock.GetUtcNow();
            var session = new GuestSession { Id = sessionId, IdentityId = account.PrimaryIdentityId, AccountId = account.Id,
                CredentialHash = Hash(secret), CreatedAt = now, ExpiresAt = now.AddDays(7), AccountAccessVerified = true };
            db.Put(transaction, identityReference, identity);
            db.Put(transaction, accountReference, account);
            db.Put(transaction, uidReference, new AccountPointer { AccountId = account.Id });
            db.Put(transaction, db.Bindings.Document(SubscriptionService.Binding(account.Id)), new AccountPointer { AccountId = account.Id });
            foreach (var old in oldSessions.Documents) transaction.Delete(old.Reference);
            db.Put(transaction, db.Sessions.Document(FirestoreStore.Id(sessionId)), session);
            return account;
        }, cancellationToken: ct);
        return result is null ? null : new($"{sessionId:N}.{secret}", new(result.Id.ToString(), result.Provider), await usage.GetQuotaAsync(result.PrimaryIdentityId, ct));
    }

    public Task SignOutAsync(SessionIdentity session, CancellationToken ct) => db.Sessions.Document(FirestoreStore.Id(session.SessionId)).DeleteAsync(cancellationToken: ct);
    private string Hash(string value) => Convert.ToHexString(HMACSHA256.HashData(credentialKey, Encoding.UTF8.GetBytes(value)));
    private static string Base64Url(byte[] value) => Convert.ToBase64String(value).TrimEnd('=').Replace('+', '-').Replace('/', '_');
}
