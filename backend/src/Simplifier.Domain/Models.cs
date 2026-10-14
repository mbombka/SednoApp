namespace Simplifier.Domain;

public sealed class GuestIdentity
{
    public Guid Id { get; set; }
    public string InstallationHash { get; set; } = "";
    public DateTimeOffset CreatedAt { get; set; }
    public Guid? AccountId { get; set; }
}

public sealed class VerifiedAccount
{
    public Guid Id { get; set; }
    public string FirebaseUid { get; set; } = "";
    public string Provider { get; set; } = "email";
    public Guid PrimaryIdentityId { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
}

public sealed class GuestSession
{
    public Guid Id { get; set; }
    public Guid IdentityId { get; set; }
    public GuestIdentity Identity { get; set; } = null!;
    public string CredentialHash { get; set; } = "";
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset ExpiresAt { get; set; }
    public Guid? AccountId { get; set; }
}

public enum RequestState { Processing, Succeeded, Failed, Expired }

public sealed class SimplificationRecord
{
    public Guid IdentityId { get; set; }
    public string RequestId { get; set; } = "";
    public string Fingerprint { get; set; } = "";
    public RequestState State { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateOnly ReservationDay { get; set; }
    public DateTimeOffset ReservationExpiresAt { get; set; }
    public DateTimeOffset? FinishedAt { get; set; }
}

public static class QuotaPolicy
{
    public static int Limit(bool subscription) => subscription ? 400 : 2;
    public static DateOnly Day(DateTimeOffset now) => DateOnly.FromDateTime(now.UtcDateTime);
    public static DateTimeOffset ResetAt(DateTimeOffset now) => new(now.UtcDateTime.Date.AddDays(1), TimeSpan.Zero);
}
