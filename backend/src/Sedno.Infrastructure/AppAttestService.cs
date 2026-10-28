using System.Security.Cryptography;
using System.Text;
using Google.Cloud.Firestore;

namespace Sedno.Infrastructure;

public sealed record AppAttestChallengeDto(string ChallengeId, string Challenge, DateTimeOffset ExpiresAt);
public sealed class AppAttestChallenge
{
    public string InstallationHash { get; set; } = "";
    public string KeyId { get; set; } = "";
    public string Purpose { get; set; } = "";
    public string Challenge { get; set; } = "";
    public DateTimeOffset ExpiresAt { get; set; }
}
public sealed class AppAttestKey
{
    public string InstallationHash { get; set; } = "";
    public string PublicKey { get; set; } = "";
    public string RegistrationId { get; set; } = "";
    public string AttestationHash { get; set; } = "";
    public string Environment { get; set; } = "";
    public uint Counter { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset ExpiresAt { get; set; }
}

// State is shared between Cloud Run replicas. Challenges and counters are consumed
// atomically; no local cache, unsigned fallback or raw installation identifiers.
public sealed class AppAttestService(FirestoreStore db, AppAttestVerifier verifier,
    AppAttestOptions options, TimeProvider clock, byte[] credentialKey)
{
    private CollectionReference Challenges => db.Database.Collection("apple_attest_challenges");
    private CollectionReference Keys => db.Database.Collection("apple_attest_keys");
    private string Installation(string installationId) => Convert.ToHexString(HMACSHA256.HashData(credentialKey, Encoding.UTF8.GetBytes(installationId)));
    private DocumentReference Key(string keyId) => Keys.Document(FirestoreStore.Hash(options.Environment + ":" + keyId));
    public static bool ValidInput(string? installationId, string? keyId) =>
        ValidInstallation(installationId) && ValidKeyId(keyId);
    private static bool ValidInstallation(string? id)
    {
        if (id is not { Length: > 0 and <= 200 }) return false;
        // Older mobile clients persisted padded base64url installation IDs. Keep
        // the exact identifier for HMAC/quota continuity; never trim it for hashing.
        var unpadded = id.TrimEnd('=');
        return unpadded.Length > 0 && id.Length - unpadded.Length <= 2 &&
            unpadded.All(c => char.IsAsciiLetterOrDigit(c) || c is '-' or '_');
    }
    private static bool ValidKeyId(string? keyId)
    {
        if (keyId is not { Length: 44 }) return false;
        try { var bytes = Convert.FromBase64String(keyId); return bytes.Length == 32 && Convert.ToBase64String(bytes) == keyId; }
        catch (FormatException) { return false; }
    }
    public static byte[] ClientDataHash(string purpose, string installationId, string keyId, string challengeId, string challenge) =>
        SHA256.HashData(Encoding.UTF8.GetBytes($"sedno:app-attest:v1:{purpose}:{installationId}:{keyId}:{challengeId}:{challenge}"));
    public async Task<AppAttestChallengeDto> CreateChallengeAsync(string installationId, string keyId, string purpose, CancellationToken ct)
    {
        if (!options.Enabled || !ValidInput(installationId, keyId) || purpose is not ("register" or "session")) throw new ArgumentException("Invalid App Attest challenge.");
        var id = Guid.NewGuid().ToString("N");
        var challenge = Convert.ToBase64String(RandomNumberGenerator.GetBytes(32));
        var expiresAt = clock.GetUtcNow().AddMinutes(5);
        await Challenges.Document(id).CreateAsync(FirestoreStore.Encode(new AppAttestChallenge
        { InstallationHash = Installation(installationId), KeyId = keyId, Purpose = purpose, Challenge = challenge, ExpiresAt = expiresAt }), ct);
        return new(id, challenge, expiresAt);
    }
    public async Task<bool> RegisterAsync(string installationId, string keyId, string challengeId, string attestation, CancellationToken ct)
    {
        if (!options.Enabled || !ValidInput(installationId, keyId) || !ValidChallengeId(challengeId) || attestation is not { Length: > 0 and <= 90000 }) return false;
        var reference = Challenges.Document(challengeId);
        var challenge = await db.GetAsync<AppAttestChallenge>(reference, ct);
        if (!Matches(challenge, installationId, keyId, "register"))
        {
            var registered = await db.GetAsync<AppAttestKey>(Key(keyId), ct);
            return registered is not null && registered.ExpiresAt > clock.GetUtcNow() &&
                registered.InstallationHash == Installation(installationId) && registered.Environment == options.Environment &&
                registered.RegistrationId == challengeId && attestation is { Length: > 0 and <= 90000 } &&
                registered.AttestationHash == FirestoreStore.Hash(attestation);
        }
        var publicKey = verifier.VerifyAttestation(attestation, keyId, ClientDataHash("register", installationId, keyId, challengeId, challenge!.Challenge));
        if (publicKey is null) return false;
        return await db.Database.RunTransactionAsync(async transaction =>
        {
            var fresh = await db.GetAsync<AppAttestChallenge>(transaction, reference, ct);
            var existing = await db.GetAsync<AppAttestKey>(transaction, Key(keyId), ct);
            if (existing is not null) return existing.InstallationHash == Installation(installationId) &&
                existing.Environment == options.Environment && existing.ExpiresAt > clock.GetUtcNow() &&
                existing.RegistrationId == challengeId && existing.AttestationHash == FirestoreStore.Hash(attestation);
            if (!Matches(fresh, installationId, keyId, "register") || fresh!.Challenge != challenge.Challenge) return false;
            db.Put(transaction, Key(keyId), new AppAttestKey
            {
                InstallationHash = Installation(installationId), PublicKey = Convert.ToBase64String(publicKey),
                Environment = options.Environment, RegistrationId = challengeId, AttestationHash = FirestoreStore.Hash(attestation), CreatedAt = clock.GetUtcNow(), ExpiresAt = clock.GetUtcNow().AddDays(90)
            });
            transaction.Delete(reference);
            return true;
        }, cancellationToken: ct);
    }
    // unknown_key is distinct so the client can rotate a stale key once after
    // reinstall, expiration or account deletion. Other failures never bypass trust.
    public async Task<string> AssertAsync(string installationId, string keyId, string challengeId, string assertion, CancellationToken ct)
    {
        if (!options.Enabled || !ValidInput(installationId, keyId) || !ValidChallengeId(challengeId) || assertion is not { Length: > 0 and <= 90000 }) return "invalid";
        return await db.Database.RunTransactionAsync(async transaction =>
        {
            var reference = Challenges.Document(challengeId);
            var challenge = await db.GetAsync<AppAttestChallenge>(transaction, reference, ct);
            var key = await db.GetAsync<AppAttestKey>(transaction, Key(keyId), ct);
            if (!Matches(challenge, installationId, keyId, "session")) return "invalid";
            if (key is null || key.ExpiresAt <= clock.GetUtcNow()) return "unknown_key";
            if (key.InstallationHash != Installation(installationId) || key.Environment != options.Environment) return "invalid";
            var counter = verifier.VerifyAssertion(assertion, Convert.FromBase64String(key.PublicKey),
                ClientDataHash("session", installationId, keyId, challengeId, challenge!.Challenge), key.Counter);
            if (counter is null) return "invalid";
            key.Counter = counter.Value;
            key.ExpiresAt = clock.GetUtcNow().AddDays(90);
            db.Put(transaction, Key(keyId), key);
            transaction.Delete(reference);
            return "verified";
        }, cancellationToken: ct);
    }
    private bool Matches(AppAttestChallenge? challenge, string installationId, string keyId, string purpose) =>
        challenge is not null && challenge.ExpiresAt > clock.GetUtcNow() && challenge.InstallationHash == Installation(installationId) && challenge.KeyId == keyId && challenge.Purpose == purpose;
    private static bool ValidChallengeId(string? id) => id is { Length: 32 } && id.All(char.IsAsciiHexDigit);
}
