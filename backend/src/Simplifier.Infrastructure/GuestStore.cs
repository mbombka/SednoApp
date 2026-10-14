using System.Security.Cryptography;
using System.Text;
using Microsoft.EntityFrameworkCore;
using Simplifier.Application;
using Simplifier.Domain;

namespace Simplifier.Infrastructure;

public sealed class GuestStore(AppDbContext db, IUsageStore usage, TimeProvider clock, byte[] credentialKey) : IGuestStore
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

    public async Task<Guid?> AuthenticateAsync(string credential, CancellationToken ct)
    {
        var parts = credential.Split('.', 2);
        if (parts.Length != 2 || !Guid.TryParseExact(parts[0], "N", out var sessionId) || parts[1].Length != 43)
            return null;
        var session = await db.Sessions.AsNoTracking().SingleOrDefaultAsync(x => x.Id == sessionId, ct);
        if (session is null || session.ExpiresAt <= clock.GetUtcNow()) return null;
        var given = Convert.FromHexString(Hash(parts[1]));
        var stored = Convert.FromHexString(session.CredentialHash);
        return CryptographicOperations.FixedTimeEquals(given, stored) ? session.IdentityId : null;
    }

    private string Hash(string value) => Convert.ToHexString(HMACSHA256.HashData(credentialKey, Encoding.UTF8.GetBytes(value)));
    private static string Base64Url(byte[] value) => Convert.ToBase64String(value).TrimEnd('=').Replace('+', '-').Replace('/', '_');
}
