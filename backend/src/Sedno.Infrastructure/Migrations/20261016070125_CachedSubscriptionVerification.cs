using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Sedno.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class CachedSubscriptionVerification : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "VerifiedAt",
                table: "play_purchases",
                type: "timestamp with time zone",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "VerifiedAt",
                table: "play_purchases");
        }
    }
}
