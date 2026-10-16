using System.Buffers.Binary;
using System.Security.Cryptography;
using System.Text;
using Microsoft.EntityFrameworkCore;

namespace Sedno.Infrastructure;

internal static class IdentityCoordination
{
    // A stable, namespaced key shared by linking and deletion across API replicas.
    // Hash collisions only serialize extra operations; they cannot grant access.
    public static Task LockAsync(AppDbContext db, string uid, CancellationToken ct)
    {
        var key = BinaryPrimitives.ReadInt32BigEndian(SHA256.HashData(Encoding.UTF8.GetBytes(uid)));
        return db.Database.ExecuteSqlInterpolatedAsync($"SELECT pg_advisory_xact_lock(1748392204, {key})", ct);
    }
}
