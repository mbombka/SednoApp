using Simplifier.Application;

namespace Simplifier.Infrastructure;

public sealed class FreeEntitlementResolver : IEntitlementResolver
{
    public Task<bool> HasSubscriptionAsync(Guid identityId, CancellationToken cancellationToken) => Task.FromResult(false);
}

public sealed class DevelopmentMockProvider : IModelProvider
{
    public Task<string> SimplifyAsync(string text, CancellationToken cancellationToken) =>
        Task.FromResult("Wersja demonstracyjna: " + text.Trim());
}

public sealed class DisabledModelProvider : IModelProvider
{
    public Task<string> SimplifyAsync(string text, CancellationToken cancellationToken) =>
        throw new InvalidOperationException("Model provider is not configured.");
}
