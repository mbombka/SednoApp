namespace Sedno.Application;

public record PlaySubscription(string State, DateTimeOffset? ExpiresAt, bool Acknowledged,
    string? AccountBinding, string? LinkedToken = null)
{
    public bool Entitled(DateTimeOffset now) => ExpiresAt > now &&
        State is "SUBSCRIPTION_STATE_ACTIVE" or "SUBSCRIPTION_STATE_IN_GRACE_PERIOD" or "SUBSCRIPTION_STATE_CANCELED";
}
public record SubscriptionDto(string State, bool Active, DateTimeOffset? ExpiresAt, string AccountBinding, string Store = "google_play");
public interface IPlayBillingClient
{
    Task<PlaySubscription> GetAsync(string token, CancellationToken ct);
    Task AcknowledgeAsync(string token, CancellationToken ct);
}
public interface INotificationVerifier
{
    Task<bool> VerifyAsync(string token, CancellationToken ct);
}
