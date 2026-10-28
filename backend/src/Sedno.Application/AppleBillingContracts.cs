namespace Sedno.Application;

public sealed record AppleSubscription(string OriginalTransactionId, string TransactionId, string AccountToken,
    string State, DateTimeOffset? ExpiresAt, DateTimeOffset SignedAt, bool Revoked)
{
    public bool Entitled(DateTimeOffset now) => !Revoked && ExpiresAt > now && State is "active" or "grace_period";
}

public sealed record AppleNotification(string Id, string? OriginalTransactionId, DateTimeOffset SignedAt);

public interface IAppleBillingClient
{
    Task<AppleSubscription> GetAsync(string transactionId, CancellationToken ct);
    AppleNotification VerifyNotification(string signedPayload);
}
