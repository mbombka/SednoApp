using Simplifier.Domain;

namespace Simplifier.Application;

public record QuotaDto(string Tier, int Limit, int Used, int Remaining, DateTimeOffset ServerTime, DateTimeOffset ResetAt);
public record GuestSessionDto(string AccessToken, AccountDto Account, QuotaDto Quota);
public record AccountDto(string Id, string Provider);
public record SimplificationResultDto(string Id, string Text, DateTimeOffset CreatedAt);
public record SimplificationResponseDto(SimplificationResultDto Result, QuotaDto Quota);
public record RequestStatusDto(string RequestId, string Status, DateTimeOffset ReservationDay, DateTimeOffset? FinishedAt, QuotaDto Quota);
public record SimplificationInput(string RequestId, string Text);
public record ReservationOutcome(string Kind, QuotaDto Quota);

public interface IModelProvider
{
    Task<string> SimplifyAsync(string text, CancellationToken cancellationToken);
}

public interface IEntitlementResolver
{
    Task<bool> HasSubscriptionAsync(Guid identityId, CancellationToken cancellationToken);
}

public interface IIntegrityVerifier
{
    Task<bool> VerifyAsync(string? token, CancellationToken cancellationToken);
}

public interface IGuestStore
{
    Task<GuestSessionDto> CreateAsync(string installationId, CancellationToken cancellationToken);
    Task<Guid?> AuthenticateAsync(string credential, CancellationToken cancellationToken);
}

public interface IUsageStore
{
    Task<QuotaDto> GetQuotaAsync(Guid identityId, CancellationToken cancellationToken);
    Task<ReservationOutcome> ReserveAsync(Guid identityId, string requestId, string fingerprint, CancellationToken cancellationToken);
    Task<bool> CompleteAsync(Guid identityId, string requestId, CancellationToken cancellationToken);
    Task FailAsync(Guid identityId, string requestId, CancellationToken cancellationToken);
    Task<RequestStatusDto?> GetStatusAsync(Guid identityId, string requestId, CancellationToken cancellationToken);
}
