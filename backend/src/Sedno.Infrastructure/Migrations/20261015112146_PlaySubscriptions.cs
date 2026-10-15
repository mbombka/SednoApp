using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Sedno.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class PlaySubscriptions : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "play_notifications",
                columns: table => new
                {
                    Id = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    ProcessedAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_play_notifications", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "play_purchases",
                columns: table => new
                {
                    TokenHash = table.Column<string>(type: "character varying(64)", maxLength: 64, nullable: false),
                    ProtectedToken = table.Column<string>(type: "text", nullable: false),
                    AccountId = table.Column<Guid>(type: "uuid", nullable: false),
                    State = table.Column<string>(type: "character varying(80)", maxLength: 80, nullable: false),
                    ExpiresAt = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    Revoked = table.Column<bool>(type: "boolean", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_play_purchases", x => x.TokenHash);
                    table.ForeignKey(
                        name: "FK_play_purchases_verified_accounts_AccountId",
                        column: x => x.AccountId,
                        principalTable: "verified_accounts",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_play_purchases_AccountId",
                table: "play_purchases",
                column: "AccountId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "play_notifications");

            migrationBuilder.DropTable(
                name: "play_purchases");
        }
    }
}
