using System.Buffers.Binary;
using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;
using System.Formats.Asn1;
using System.Text;
using Google.Api.Gax;
using Google.Cloud.Firestore;
using Sedno.Infrastructure;
using Xunit;

namespace Sedno.IntegrationTests;

[Collection("backend")]
public sealed class AppAttestStateTests(BackendFixture fixture)
{
    private static readonly AppAttestOptions Options = new(true, "ABCDE12345", "xyz.sedno.app");
    private static readonly byte[] CredentialKey = SHA256.HashData("synthetic-test-credential"u8);
    private FirestoreStore Isolated() => new(new FirestoreDbBuilder
    {
        ProjectId = "demo-attest-" + Guid.NewGuid().ToString("N")[..12],
        EmulatorDetection = EmulatorDetection.EmulatorOnly
    }.Build());
    private AppAttestService Service(FirestoreStore db) => new(db, new(Options, fixture.Clock), Options, fixture.Clock, CredentialKey);
    private async Task<string> SeedAsync(FirestoreStore db, ECDsa key, string installation)
    {
        var q = key.ExportParameters(false).Q;
        var keyId = Convert.ToBase64String(SHA256.HashData([4, .. q.X!, .. q.Y!]));
        await db.PutAsync(db.Database.Collection("apple_attest_keys").Document(FirestoreStore.Hash("production:" + keyId)), new AppAttestKey
        {
            InstallationHash = Convert.ToHexString(HMACSHA256.HashData(CredentialKey, Encoding.UTF8.GetBytes(installation))),
            PublicKey = Convert.ToBase64String(key.ExportSubjectPublicKeyInfo()), Environment = "production",
            CreatedAt = fixture.Clock.GetUtcNow(), ExpiresAt = fixture.Clock.GetUtcNow().AddDays(90)
        });
        return keyId;
    }
    [Fact]
    public async Task SameChallengeCannotCreateTwoSessionsAcrossReplicas()
    {
        var db = Isolated();
        using var key = ECDsa.Create(ECCurve.NamedCurves.nistP256);
        var keyId = await SeedAsync(db, key, "install");
        var challenge = await Service(db).CreateChallengeAsync("install", keyId, "session", default);
        var assertion = Assertion(key, AppAttestService.ClientDataHash("session", "install", keyId, challenge.ChallengeId, challenge.Challenge), 1);
        var attempts = await Task.WhenAll(Enumerable.Range(0, 10).Select(_ =>
            Service(new(db.Database)).AssertAsync("install", keyId, challenge.ChallengeId, assertion, default)));
        Assert.Single(attempts, x => x == "verified");
        Assert.Equal(9, attempts.Count(x => x == "invalid"));
    }
    [Fact]
    public async Task SameCounterCannotBeReusedWithFreshChallenge()
    {
        var db = Isolated();
        using var key = ECDsa.Create(ECCurve.NamedCurves.nistP256);
        var keyId = await SeedAsync(db, key, "install");
        var challenges = await Task.WhenAll(Enumerable.Range(0, 5).Select(_ => Service(db).CreateChallengeAsync("install", keyId, "session", default)));
        var attempts = await Task.WhenAll(challenges.Select(challenge => Service(new(db.Database)).AssertAsync("install", keyId,
            challenge.ChallengeId, Assertion(key, AppAttestService.ClientDataHash("session", "install", keyId, challenge.ChallengeId, challenge.Challenge), 1), default)));
        Assert.Single(attempts, x => x == "verified");
        var next = await Service(db).CreateChallengeAsync("install", keyId, "session", default);
        Assert.Equal("verified", await Service(db).AssertAsync("install", keyId, next.ChallengeId,
            Assertion(key, AppAttestService.ClientDataHash("session", "install", keyId, next.ChallengeId, next.Challenge), 2), default));
    }
    [Fact]
    public async Task ChallengesBindInstallationPurposeKeyAndExpiration()
    {
        var db = Isolated();
        using var key = ECDsa.Create(ECCurve.NamedCurves.nistP256);
        var keyId = await SeedAsync(db, key, "install");
        var challenge = await Service(db).CreateChallengeAsync("install", keyId, "register", default);
        Assert.Equal("invalid", await Service(db).AssertAsync("install", keyId, challenge.ChallengeId, "AA==", default));
        challenge = await Service(db).CreateChallengeAsync("other-install", keyId, "session", default);
        Assert.Equal("invalid", await Service(db).AssertAsync("other-install", keyId, challenge.ChallengeId,
            Assertion(key, AppAttestService.ClientDataHash("session", "other-install", keyId, challenge.ChallengeId, challenge.Challenge), 1), default));
        challenge = await Service(db).CreateChallengeAsync("install", keyId, "session", default);
        await db.Database.Collection("apple_attest_challenges").Document(challenge.ChallengeId)
            .UpdateAsync("ExpiresAt", FirestoreStore.Date(fixture.Clock.GetUtcNow().AddSeconds(-1)));
        Assert.Equal("invalid", await Service(db).AssertAsync("install", keyId, challenge.ChallengeId, "AA==", default));
        var unknown = Convert.ToBase64String(RandomNumberGenerator.GetBytes(32));
        challenge = await Service(db).CreateChallengeAsync("install", unknown, "session", default);
        Assert.Equal("unknown_key", await Service(db).AssertAsync("install", unknown, challenge.ChallengeId, "AA==", default));
    }
    [Fact]
    public async Task RegistrationIsIdempotentAndCannotResetCounterOrChangeInstallation()
    {
        var db = Isolated();
        using var key = ECDsa.Create(ECCurve.NamedCurves.nistP256);
        using var rootKey = ECDsa.Create(ECCurve.NamedCurves.nistP384);
        var request = new CertificateRequest("CN=Synthetic root", rootKey, HashAlgorithmName.SHA384);
        request.CertificateExtensions.Add(new X509BasicConstraintsExtension(true, false, 0, true));
        request.CertificateExtensions.Add(new X509KeyUsageExtension(X509KeyUsageFlags.KeyCertSign, true));
        var now = fixture.Clock.GetUtcNow();
        using var root = request.CreateSelfSigned(now.AddDays(-1), now.AddDays(2));
        AppAttestService Replica() => new(new(db.Database), new(Options, fixture.Clock, root.RawData), Options, fixture.Clock, CredentialKey);
        var q = key.ExportParameters(false).Q;
        var keyId = Convert.ToBase64String(SHA256.HashData([4, .. q.X!, .. q.Y!]));
        var challenge = await Replica().CreateChallengeAsync("install", keyId, "register", default);
        byte[] cose = Encode(new Dictionary<object, object> { [1L] = 2L, [3L] = -7L, [-1L] = 1L, [-2L] = q.X!, [-3L] = q.Y! });
        byte[] auth = [.. SHA256.HashData(Encoding.UTF8.GetBytes(Options.TeamId + "." + Options.BundleId)), 0x40, 0, 0, 0, 0,
            .. Encoding.ASCII.GetBytes("appattest\0\0\0\0\0\0\0"), 0, 32, .. Convert.FromBase64String(keyId), .. cose];
        var hash = AppAttestService.ClientDataHash("register", "install", keyId, challenge.ChallengeId, challenge.Challenge);
        var writer = new AsnWriter(AsnEncodingRules.DER);
        writer.PushSequence(); var tag = new Asn1Tag(TagClass.ContextSpecific, 1, true);
        writer.PushSequence(tag); writer.WriteOctetString(SHA256.HashData([.. auth, .. hash])); writer.PopSequence(tag); writer.PopSequence();
        request = new CertificateRequest("CN=Synthetic credential", key, HashAlgorithmName.SHA256);
        request.CertificateExtensions.Add(new X509Extension("1.2.840.113635.100.8.2", writer.Encode(), false));
        using var leaf = request.Create(root, now.AddHours(-1), now.AddDays(1), RandomNumberGenerator.GetBytes(16));
        var attestation = Convert.ToBase64String(Encode(new Dictionary<object, object>
        {
            ["fmt"] = "apple-appattest", ["authData"] = auth,
            ["attStmt"] = new Dictionary<object, object> { ["x5c"] = new object[] { leaf.RawData, root.RawData }, ["receipt"] = new byte[] { 1 } }
        }));
        var registrations = await Task.WhenAll(Enumerable.Range(0, 3).Select(_ => Replica().RegisterAsync("install", keyId, challenge.ChallengeId, attestation, default)));
        Assert.All(registrations, Assert.True);
        var sessionChallenge = await Replica().CreateChallengeAsync("install", keyId, "session", default);
        Assert.Equal("verified", await Replica().AssertAsync("install", keyId, sessionChallenge.ChallengeId,
            Assertion(key, AppAttestService.ClientDataHash("session", "install", keyId, sessionChallenge.ChallengeId, sessionChallenge.Challenge), 1), default));
        Assert.True(await Replica().RegisterAsync("install", keyId, challenge.ChallengeId, attestation, default));
        var stored = await db.GetAsync<AppAttestKey>(db.Database.Collection("apple_attest_keys").Document(FirestoreStore.Hash("production:" + keyId)));
        Assert.Equal(1u, stored!.Counter);
        Assert.False(await Replica().RegisterAsync("other-install", keyId, challenge.ChallengeId, attestation, default));
        Assert.False(await Replica().RegisterAsync("install", keyId, challenge.ChallengeId, attestation + "AA==", default));
    }
    [Fact]
    public async Task CleanupExpiresAppleMetadataAndPreservesCurrentKeys()
    {
        var db = Isolated();
        var now = fixture.Clock.GetUtcNow();
        foreach (var collection in new[] { "apple_attest_keys", "apple_attest_challenges" })
        {
            await db.PutAsync(db.Database.Collection(collection).Document("expired"), new { ExpiresAt = now });
            await db.PutAsync(db.Database.Collection(collection).Document("current"), new { ExpiresAt = now.AddDays(1) });
        }
        await db.PutAsync(db.Database.Collection("apple_notifications").Document("expired"), new { ProcessedAt = now.AddDays(-31) });
        await db.PutAsync(db.Database.Collection("apple_notifications").Document("current"), new { ProcessedAt = now });
        var cleanup = new MetadataCleanup(db, fixture.Clock, new AccountDeletionService(db, fixture.IdentityAccounts, fixture.Clock));
        await cleanup.RunAsync(default);
        foreach (var collection in new[] { "apple_attest_keys", "apple_attest_challenges", "apple_notifications" })
        {
            Assert.False((await db.Database.Collection(collection).Document("expired").GetSnapshotAsync()).Exists);
            Assert.True((await db.Database.Collection(collection).Document("current").GetSnapshotAsync()).Exists);
        }
    }
    [Fact]
    public async Task DisabledIosEndpointsArePublicButFailClosed()
    {
        using var client = fixture.Factory.CreateClient();
        foreach (var path in new[] { "/v1/ios/attestation/challenges", "/v1/ios/attestation/keys", "/v1/ios/guest-sessions" })
        {
            using var content = new StringContent("{}", Encoding.UTF8, "application/json");
            var response = await client.PostAsync(path, content);
            Assert.Equal(System.Net.HttpStatusCode.ServiceUnavailable, response.StatusCode);
        }
    }
    private static byte[] Encode(object value)
    {
        using var stream = new MemoryStream();
        void Head(int major, int n)
        {
            if (n < 24) stream.WriteByte((byte)(major * 32 + n));
            else if (n < 256) { stream.WriteByte((byte)(major * 32 + 24)); stream.WriteByte((byte)n); }
            else { stream.WriteByte((byte)(major * 32 + 25)); stream.WriteByte((byte)(n >> 8)); stream.WriteByte((byte)n); }
        }
        switch (value)
        {
            case string text: var textBytes = Encoding.UTF8.GetBytes(text); Head(3, textBytes.Length); stream.Write(textBytes); break;
            case byte[] bytes: Head(2, bytes.Length); stream.Write(bytes); break;
            case long n: Head(n < 0 ? 1 : 0, (int)(n < 0 ? -1 - n : n)); break;
            case object[] array: Head(4, array.Length); foreach (var item in array) stream.Write(Encode(item)); break;
            case Dictionary<object, object> map: Head(5, map.Count); foreach (var pair in map) { stream.Write(Encode(pair.Key)); stream.Write(Encode(pair.Value)); } break;
            default: throw new ArgumentException();
        }
        return stream.ToArray();
    }
    private static string Assertion(ECDsa key, byte[] hash, uint count)
    {
        var counter = new byte[4]; BinaryPrimitives.WriteUInt32BigEndian(counter, count);
        byte[] auth = [.. SHA256.HashData(Encoding.UTF8.GetBytes(Options.TeamId + "." + Options.BundleId)), 0, .. counter];
        var signature = key.SignData(SHA256.HashData([.. auth, .. hash]), HashAlgorithmName.SHA256, DSASignatureFormat.Rfc3279DerSequence);
        using var stream = new MemoryStream();
        stream.WriteByte(0xa2);
        void Text(string s) { var bytes = Encoding.UTF8.GetBytes(s); stream.WriteByte((byte)(0x60 + bytes.Length)); stream.Write(bytes); }
        void Bytes(byte[] bytes) { stream.WriteByte(0x58); stream.WriteByte((byte)bytes.Length); stream.Write(bytes); }
        Text("signature"); Bytes(signature); Text("authenticatorData"); Bytes(auth);
        return Convert.ToBase64String(stream.ToArray());
    }
}
