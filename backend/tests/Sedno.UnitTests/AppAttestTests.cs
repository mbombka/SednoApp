using System.Buffers.Binary;
using System.Formats.Asn1;
using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;
using System.Text;
using Sedno.Infrastructure;
using Xunit;

namespace Sedno.UnitTests;

public sealed class AppAttestTests
{
    private static readonly AppAttestOptions Options = new(true, "ABCDE12345", "xyz.sedno.app", "production");
    [Fact]
    public void PinnedAppleRootLoadsAndSettingsRejectDevelopmentOutsideDevelopment()
    {
        _ = new AppAttestVerifier(Options, TimeProvider.System);
        Assert.Throws<InvalidOperationException>(() => (Options with { Environment = "development" }).Validate(false));
        Assert.Throws<InvalidOperationException>(() => (Options with { TeamId = "" }).Validate(false));
        Options.Validate(false);
        (Options with { Environment = "development" }).Validate(true);
    }
    [Fact]
    public void ClientDataBindsEveryFieldAndRejectsNoncanonicalIdentifiers()
    {
        var key = Convert.ToBase64String(new byte[32]);
        Assert.True(AppAttestService.ValidInput("installation-1", key));
        Assert.True(AppAttestService.ValidInput(Convert.ToBase64String(new byte[32]).Replace('+', '-').Replace('/', '_'), key));
        Assert.True(AppAttestService.ValidInput("legacy==", key));
        Assert.False(AppAttestService.ValidInput("=", key));
        Assert.False(AppAttestService.ValidInput("legacy===", key));
        Assert.False(AppAttestService.ValidInput("a=b", key));
        Assert.False(AppAttestService.ValidInput("installation:1", key));
        Assert.False(AppAttestService.ValidInput("installation", key.TrimEnd('=')));
        var original = AppAttestService.ClientDataHash("session", "install", key, "id", "challenge");
        foreach (var changed in new[] {
            AppAttestService.ClientDataHash("register", "install", key, "id", "challenge"),
            AppAttestService.ClientDataHash("session", "different", key, "id", "challenge"),
            AppAttestService.ClientDataHash("session", "install", key, "other", "challenge"),
            AppAttestService.ClientDataHash("session", "install", key, "id", "other") })
            Assert.False(original.SequenceEqual(changed));
    }
    [Fact]
    public void AttestationChecksCertificateTrustNonceCredentialApplicationAndEnvironment()
    {
        using var fixture = new SyntheticAttestation();
        var verifier = fixture.Verifier;
        var hash = SHA256.HashData("challenge"u8);
        var attestation = fixture.Attest(hash);
        Assert.NotNull(verifier.VerifyAttestation(attestation, fixture.KeyId, hash));
        Assert.Null(verifier.VerifyAttestation(attestation, fixture.KeyId, SHA256.HashData("other"u8)));
        Assert.Null(verifier.VerifyAttestation(attestation, Convert.ToBase64String(new byte[32]), hash));
        Assert.Null(new AppAttestVerifier(Options, TimeProvider.System).VerifyAttestation(attestation, fixture.KeyId, hash));
        Assert.Null(fixture.CreateVerifier(Options with { BundleId = "xyz.other.app" }).VerifyAttestation(attestation, fixture.KeyId, hash));
        Assert.Null(fixture.CreateVerifier(Options with { Environment = "development" }).VerifyAttestation(attestation, fixture.KeyId, hash));
        Assert.Null(verifier.VerifyAttestation(fixture.Attest(hash, counter: 1), fixture.KeyId, hash));
        Assert.Null(verifier.VerifyAttestation(fixture.Attest(hash, invalidCose: true), fixture.KeyId, hash));
    }
    [Fact]
    public void AssertionsRejectReplayTamperingWrongRpAndWrongSignatureKey()
    {
        using var fixture = new SyntheticAttestation();
        var hash = SHA256.HashData("challenge"u8);
        var assertion = fixture.Assert(hash, 2);
        Assert.Equal(2u, fixture.Verifier.VerifyAssertion(assertion, fixture.PublicKey, hash, 1));
        Assert.Null(fixture.Verifier.VerifyAssertion(assertion, fixture.PublicKey, hash, 2));
        Assert.Null(fixture.Verifier.VerifyAssertion(assertion, fixture.PublicKey, SHA256.HashData("changed"u8), 0));
        Assert.Null(fixture.CreateVerifier(Options with { BundleId = "different" }).VerifyAssertion(assertion, fixture.PublicKey, hash, 0));
        using var otherKey = ECDsa.Create(ECCurve.NamedCurves.nistP256);
        Assert.Null(fixture.Verifier.VerifyAssertion(assertion, otherKey.ExportSubjectPublicKeyInfo(), hash, 0));
        Assert.Null(fixture.Verifier.VerifyAssertion(fixture.Assert(hash, 0), fixture.PublicKey, hash, 0));
    }
    [Theory]
    [InlineData("")]
    [InlineData("!!!")]
    [InlineData("oA==")]
    [InlineData("//8=")]
    [InlineData("omNmbXQBY2ZtdAI=")]
    public void MalformedCborAndBase64FailClosed(string value)
    {
        using var fixture = new SyntheticAttestation();
        Assert.Null(fixture.Verifier.VerifyAttestation(value, fixture.KeyId, new byte[32]));
        Assert.Null(fixture.Verifier.VerifyAssertion(value, fixture.PublicKey, new byte[32], 0));
    }

    private sealed class SyntheticAttestation : IDisposable
    {
        private readonly ECDsa rootKey = ECDsa.Create(ECCurve.NamedCurves.nistP384);
        private readonly ECDsa key = ECDsa.Create(ECCurve.NamedCurves.nistP256);
        private readonly X509Certificate2 root;
        public string KeyId { get; }
        public byte[] PublicKey => key.ExportSubjectPublicKeyInfo();
        public AppAttestVerifier Verifier => CreateVerifier(Options);
        public AppAttestVerifier CreateVerifier(AppAttestOptions options) => new(options, TimeProvider.System, root.RawData);
        public SyntheticAttestation()
        {
            var request = new CertificateRequest("CN=Synthetic test root", rootKey, HashAlgorithmName.SHA384);
            request.CertificateExtensions.Add(new X509BasicConstraintsExtension(true, false, 0, true));
            request.CertificateExtensions.Add(new X509KeyUsageExtension(X509KeyUsageFlags.KeyCertSign, true));
            root = request.CreateSelfSigned(DateTimeOffset.UtcNow.AddDays(-1), DateTimeOffset.UtcNow.AddDays(2));
            var q = key.ExportParameters(false).Q;
            KeyId = Convert.ToBase64String(SHA256.HashData([4, .. q.X!, .. q.Y!]));
        }
        public string Attest(byte[] hash, uint counter = 0, bool invalidCose = false)
        {
            var q = key.ExportParameters(false).Q;
            var cose = Cbor(new Dictionary<object, object> { [1L] = 2L, [3L] = -7L, [-1L] = 1L, [-2L] = invalidCose ? new byte[32] : q.X!, [-3L] = q.Y! });
            byte[] auth = [.. Rp(), 0x40, .. Counter(counter), .. Encoding.ASCII.GetBytes("appattest\0\0\0\0\0\0\0"), 0, 32, .. Convert.FromBase64String(KeyId), .. cose];
            var writer = new AsnWriter(AsnEncodingRules.DER);
            writer.PushSequence();
            var tag = new Asn1Tag(TagClass.ContextSpecific, 1, true);
            writer.PushSequence(tag); writer.WriteOctetString(SHA256.HashData([.. auth, .. hash])); writer.PopSequence(tag); writer.PopSequence();
            var request = new CertificateRequest("CN=Synthetic credential", key, HashAlgorithmName.SHA256);
            request.CertificateExtensions.Add(new X509Extension("1.2.840.113635.100.8.2", writer.Encode(), false));
            using var leaf = request.Create(root, DateTimeOffset.UtcNow.AddHours(-1), DateTimeOffset.UtcNow.AddDays(1), RandomNumberGenerator.GetBytes(16));
            return Convert.ToBase64String(Cbor(new Dictionary<object, object>
            {
                ["fmt"] = "apple-appattest", ["authData"] = auth,
                ["attStmt"] = new Dictionary<object, object> { ["x5c"] = new object[] { leaf.RawData, root.RawData }, ["receipt"] = new byte[] { 1 } }
            }));
        }
        public string Assert(byte[] hash, uint counter)
        {
            byte[] auth = [.. Rp(), 0, .. Counter(counter)];
            var signature = key.SignData(SHA256.HashData([.. auth, .. hash]), HashAlgorithmName.SHA256, DSASignatureFormat.Rfc3279DerSequence);
            return Convert.ToBase64String(Cbor(new Dictionary<object, object> { ["signature"] = signature, ["authenticatorData"] = auth }));
        }
        private static byte[] Rp() => SHA256.HashData(Encoding.UTF8.GetBytes(Options.TeamId + "." + Options.BundleId));
        private static byte[] Counter(uint n) { var bytes = new byte[4]; BinaryPrimitives.WriteUInt32BigEndian(bytes, n); return bytes; }
        public void Dispose() { root.Dispose(); rootKey.Dispose(); key.Dispose(); }
    }
    private static byte[] Cbor(object value)
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
            case object[] array: Head(4, array.Length); foreach (var item in array) stream.Write(Cbor(item)); break;
            case Dictionary<object, object> map: Head(5, map.Count); foreach (var pair in map) { stream.Write(Cbor(pair.Key)); stream.Write(Cbor(pair.Value)); } break;
            default: throw new ArgumentException();
        }
        return stream.ToArray();
    }
}
