using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;

namespace Sedno.Infrastructure.Migrations;

[DbContext(typeof(AppDbContext))]
[Migration("202610140002_Authentication")]
public sealed class Authentication : Migration
{
    protected override void Up(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.AddColumn<Guid?>("AccountId", "guest_identities", type: "uuid", nullable: true);
        migrationBuilder.AddColumn<Guid?>("AccountId", "guest_sessions", type: "uuid", nullable: true);
        migrationBuilder.CreateTable("verified_accounts", table => new
        {
            Id = table.Column<Guid>(type: "uuid", nullable: false),
            FirebaseUid = table.Column<string>(type: "character varying(128)", maxLength: 128, nullable: false),
            Provider = table.Column<string>(type: "character varying(16)", maxLength: 16, nullable: false),
            PrimaryIdentityId = table.Column<Guid>(type: "uuid", nullable: false),
            CreatedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
        }, constraints: table => table.PrimaryKey("PK_verified_accounts", x => x.Id));
        migrationBuilder.CreateIndex("IX_guest_identities_AccountId", "guest_identities", "AccountId");
        migrationBuilder.CreateIndex("IX_guest_sessions_AccountId", "guest_sessions", "AccountId");
        migrationBuilder.CreateIndex("IX_verified_accounts_FirebaseUid", "verified_accounts", "FirebaseUid", unique: true);
    }

    protected override void Down(MigrationBuilder migrationBuilder)
    {
        migrationBuilder.DropTable("verified_accounts");
        migrationBuilder.DropIndex("IX_guest_identities_AccountId", "guest_identities");
        migrationBuilder.DropIndex("IX_guest_sessions_AccountId", "guest_sessions");
        migrationBuilder.DropColumn("AccountId", "guest_identities");
        migrationBuilder.DropColumn("AccountId", "guest_sessions");
    }
}
