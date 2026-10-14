using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Simplifier.Domain;

namespace Simplifier.Infrastructure.Migrations;

[DbContext(typeof(AppDbContext))]
public sealed class AppDbContextModelSnapshot : ModelSnapshot
{
    protected override void BuildModel(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<GuestIdentity>(e =>
        {
            e.ToTable("guest_identities");
            e.HasKey(x => x.Id);
            e.Property(x => x.InstallationHash).HasMaxLength(64);
            e.HasIndex(x => x.InstallationHash);
        });
        modelBuilder.Entity<GuestSession>(e =>
        {
            e.ToTable("guest_sessions");
            e.HasKey(x => x.Id);
            e.Property(x => x.CredentialHash).HasMaxLength(64);
            e.HasIndex(x => x.ExpiresAt);
            e.HasOne(x => x.Identity).WithMany().HasForeignKey(x => x.IdentityId).OnDelete(DeleteBehavior.Cascade);
        });
        modelBuilder.Entity<SimplificationRecord>(e =>
        {
            e.ToTable("simplification_requests");
            e.HasKey(x => new { x.IdentityId, x.RequestId });
            e.Property(x => x.RequestId).HasMaxLength(100);
            e.Property(x => x.Fingerprint).HasMaxLength(64);
            e.Property(x => x.State).HasConversion<string>().HasMaxLength(20);
            e.HasIndex(x => new { x.IdentityId, x.ReservationDay, x.State });
            e.HasIndex(x => x.CreatedAt);
            e.HasOne<GuestIdentity>().WithMany().HasForeignKey(x => x.IdentityId).OnDelete(DeleteBehavior.Cascade);
        });
    }
}
