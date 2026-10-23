using Sedno.Application;

namespace Sedno.Infrastructure;

public sealed class FreeEntitlementResolver : IEntitlementResolver
{
    public Task<bool> HasSubscriptionAsync(Guid identityId, CancellationToken cancellationToken) => Task.FromResult(false);
}

public sealed class DevelopmentMockProvider : IModelProvider
{
    public Task<string> SimplifyAsync(string text, string language, CancellationToken cancellationToken) =>
        language == "pl" ? SimplifyAsync(text, cancellationToken) : Task.FromResult("Demo simplification: " + text.Trim());
    public Task<string> CorrectAsync(string text, string language, CancellationToken cancellationToken) =>
        language == "pl" ? CorrectAsync(text, cancellationToken) : Task.FromResult("Demo correction: " + text.Trim());
    public Task<string> CorrectAsync(string text, CancellationToken cancellationToken) =>
        Task.FromResult("Demonstracja poprawiania: " + text.Trim());
    public Task<string> SimplifyAsync(string text, CancellationToken cancellationToken) =>
        Task.FromResult("Wersja demonstracyjna: " + text.Trim());
}

public sealed class DisabledModelProvider : IModelProvider
{
    public Task<string> SimplifyAsync(string text, CancellationToken cancellationToken) =>
        throw new InvalidOperationException("Model provider is not configured.");
}
