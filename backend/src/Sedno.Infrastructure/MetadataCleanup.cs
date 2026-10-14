using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;

namespace Sedno.Infrastructure;

public sealed class MetadataCleanup(IServiceScopeFactory scopes, TimeProvider clock) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            await Task.Delay(TimeSpan.FromHours(1), clock, stoppingToken);
            using (var scope = scopes.CreateScope())
            {
                var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
                var now = clock.GetUtcNow();
                await db.Requests.Where(x => x.CreatedAt < now.AddDays(-8)).ExecuteDeleteAsync(stoppingToken);
                await db.Sessions.Where(x => x.ExpiresAt < now).ExecuteDeleteAsync(stoppingToken);
                await db.Identities.Where(x => x.CreatedAt < now.AddDays(-90) &&
                    !db.Sessions.Any(s => s.IdentityId == x.Id) &&
                    !db.Requests.Any(r => r.IdentityId == x.Id) &&
                    !db.Accounts.Any(a => a.PrimaryIdentityId == x.Id) && x.AccountId == null)
                    .ExecuteDeleteAsync(stoppingToken);
            }
        }
    }
}
