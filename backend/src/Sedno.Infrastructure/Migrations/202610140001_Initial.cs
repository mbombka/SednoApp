using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

namespace Sedno.Infrastructure.Migrations;

[DbContext(typeof(AppDbContext))]
[Migration("202610140001_Initial")]
public sealed class Initial : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.CreateTable("guest_identities", table => new
        {
            Id = table.Column<Guid>(type: "uuid", nullable: false),
            InstallationHash = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
            CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
        }, constraints: table => table.PrimaryKey("PK_guest_identities", x => x.Id));
        migrationBuilder.CreateTable("guest_sessions", table => new
        {
            Id = table.Column<Guid>(type: "uuid", nullable: false),
            IdentityId = table.Column<Guid>(type: "uuid", nullable: false),
            CredentialHash = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
            CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
            ExpiresAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
        }, constraints: table =>
        {
            table.PrimaryKey("PK_guest_sessions", x => x.Id);
            table.ForeignKey("FK_guest_sessions_guest_identities_IdentityId", x => x.IdentityId, "guest_identities", "Id", onDelete: ReferentialAction.Cascade);
        });
        migrationBuilder.CreateTable("simplification_requests", table => new
        {
            IdentityId = table.Column<Guid>(type: "uuid", nullable: false),
            RequestId = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
            Fingerprint = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
            State = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
            CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
            ReservationDay = table.Column<DateOnly>(type: "date", nullable: false),
            ReservationExpiresAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
            FinishedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true)
        }, constraints: table =>
        {
            table.PrimaryKey("PK_simplification_requests", x => new { x.IdentityId, x.RequestId });
            table.ForeignKey("FK_simplification_requests_guest_identities_IdentityId", x => x.IdentityId, "guest_identities", "Id", onDelete: ReferentialAction.Cascade);
        });
        migrationBuilder.CreateIndex("IX_guest_identities_InstallationHash", "guest_identities", "InstallationHash");
        migrationBuilder.CreateIndex("IX_guest_sessions_ExpiresAt", "guest_sessions", "ExpiresAt");
        migrationBuilder.CreateIndex("IX_guest_sessions_IdentityId", "guest_sessions", "IdentityId");
        migrationBuilder.CreateIndex("IX_simplification_requests_CreatedAt", "simplification_requests", "CreatedAt");
        migrationBuilder.CreateIndex("IX_simplification_requests_IdentityId_ReservationDay_State", "simplification_requests", new[] { "IdentityId", "ReservationDay", "State" });
    }

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropTable("simplification_requests");
        migrationBuilder.DropTable("guest_sessions");
        migrationBuilder.DropTable("guest_identities");
    }
}
