using System.Buffers.Binary;
using System.Security.Cryptography;
using System.Text;
using Microsoft.EntityFrameworkCore;

namespace Sedno.Infrastructure;

internal static class BillingCoordination
{
    // Notification -> token -> account. Refresh/deletion only need the account lock.
    // No global lock is held during Google I/O for unrelated accounts.
    public static Task AccountAsync(AppDbContext db, Guid account, CancellationToken ct) =>
        LockAsync(db, 1748392205, account.ToString("N"), ct);
    public static Task TokenAsync(AppDbContext db, string token, CancellationToken ct) =>
        LockAsync(db, 1748392206, token, ct);
    public static Task NotificationAsync(AppDbContext db, string messageId, CancellationToken ct) =>
        LockAsync(db, 1748392207, messageId, ct);

    private static Task LockAsync(AppDbContext db, int scope, string value, CancellationToken ct)
    {
        var key = BinaryPrimitives.ReadInt32BigEndian(SHA256.HashData(Encoding.UTF8.GetBytes(value)));
        return db.Database.ExecuteSqlInterpolatedAsync($"SELECT pg_advisory_xact_lock({scope}, {key})", ct);
    }
}
