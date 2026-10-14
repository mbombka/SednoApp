using Microsoft.EntityFrameworkCore;
using Simplifier.Domain;

namespace Simplifier.Infrastructure;

public sealed class AppDbContext(DbContextOptions<AppDbContext> options) : DbContext(options)
{
    public DbSet<GuestIdentity> Identities => Set<GuestIdentity>();
    public DbSet<GuestSession> Sessions => Set<GuestSession>();
    public DbSet<SimplificationRecord> Requests => Set<SimplificationRecord>();

    protected override void OnModelCreating(ModelBuilder model)
    {
        model.Entity<GuestIdentity>(e =>
        {
            e.ToTable("guest_identities"); e.HasKey(x => x.Id);
            e.Property(x => x.InstallationHash).HasMaxLength(64);
            e.HasIndex(x => x.InstallationHash);
        });
        model.Entity<GuestSession>(e =>
        {
            e.ToTable("guest_sessions"); e.HasKey(x => x.Id);
            e.Property(x => x.CredentialHash).HasMaxLength(64);
            e.HasOne(x => x.Identity).WithMany().HasForeignKey(x => x.IdentityId).OnDelete(DeleteBehavior.Cascade);
            e.HasIndex(x => x.ExpiresAt);
        });
        model.Entity<SimplificationRecord>(e =>
        {
            e.ToTable("simplification_requests"); e.HasKey(x => new { x.IdentityId, x.RequestId });
            e.Property(x => x.RequestId).HasMaxLength(100);
            e.Property(x => x.Fingerprint).HasMaxLength(64);
            e.Property(x => x.State).HasConversion<string>().HasMaxLength(20);
            e.HasOne<GuestIdentity>().WithMany().HasForeignKey(x => x.IdentityId).OnDelete(DeleteBehavior.Cascade);
            e.HasIndex(x => new { x.IdentityId, x.ReservationDay, x.State });
            e.HasIndex(x => x.CreatedAt);
        });
    }
}
