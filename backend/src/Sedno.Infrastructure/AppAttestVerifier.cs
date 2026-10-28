using System.Buffers.Binary;
using System.Formats.Asn1;
using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;
using System.Text;

namespace Sedno.Infrastructure;

public sealed record AppAttestOptions(bool Enabled = false, string TeamId = "", string BundleId = "", string Environment = "production")
{
    public void Validate(bool development)
    {
        if (!Enabled) return;
        if (TeamId.Length != 10 || !TeamId.All(char.IsAsciiLetterOrDigit) ||
            BundleId.Length is < 3 or > 200 || !BundleId.All(c => char.IsAsciiLetterOrDigit(c) || c is '.' or '-') ||
            Environment is not ("production" or "development") || (!development && Environment != "production"))
            throw new InvalidOperationException("Valid Apple App Attest TeamId, BundleId and environment are required; development attestations are Development-only.");
    }
}

public sealed class AppAttestVerifier
{
    private readonly AppAttestOptions options;
    private readonly TimeProvider clock;
    private readonly byte[] rootCertificate;
    public AppAttestVerifier(AppAttestOptions options, TimeProvider clock)
    {
        this.options = options;
        this.clock = clock;
        using var stream = typeof(AppAttestVerifier).Assembly.GetManifestResourceStream("Sedno.Infrastructure.Certificates.Apple_App_Attestation_Root_CA.pem")!;
        using var reader = new StreamReader(stream);
        using var root = X509Certificate2.CreateFromPem(reader.ReadToEnd());
        rootCertificate = root.RawData;
        // Download source: https://www.apple.com/certificateauthority/Apple_App_Attestation_Root_CA.pem
        if (Convert.ToHexString(SHA256.HashData(rootCertificate)) != "1CB9823BA28BA6AD2D33A006941DE2AE4F513EF1D4E831B9F7E0FA7B6242C932")
            throw new InvalidOperationException("Unexpected Apple App Attest trust anchor.");
    }
    // Internal injection is only for synthetic cryptographic tests; no configurable production trust root.
    internal AppAttestVerifier(AppAttestOptions options, TimeProvider clock, byte[] rootCertificate)
    { this.options = options; this.clock = clock; this.rootCertificate = rootCertificate; }

    public byte[]? VerifyAttestation(string encoded, string keyId, byte[] clientDataHash)
    {
        try
        {
            var map = AppAttestCbor.Map(Decode(encoded));
            if ((string)map["fmt"] != "apple-appattest") return null;
            var auth = (byte[])map["authData"];
            var statement = (Dictionary<object, object>)map["attStmt"];
            var certificates = (object[])statement["x5c"];
            if (statement["receipt"] is not byte[] { Length: > 0 }) return null;
            if (certificates.Length is < 2 or > 3 || auth.Length < 55 || (auth[32] & 0x40) == 0 ||
                BinaryPrimitives.ReadUInt32BigEndian(auth.AsSpan(33, 4)) != 0 || !ValidRp(auth)) return null;
            var aaguid = options.Environment == "development" ? Encoding.ASCII.GetBytes("appattestdevelop") : Encoding.ASCII.GetBytes("appattest\0\0\0\0\0\0\0");
            if (!auth.AsSpan(37, 16).SequenceEqual(aaguid)) return null;
            var credentialLength = BinaryPrimitives.ReadUInt16BigEndian(auth.AsSpan(53, 2));
            var decodedKey = Convert.FromBase64String(keyId);
            if (credentialLength != 32 || auth.Length <= 55 + credentialLength || !auth.AsSpan(55, credentialLength).SequenceEqual(decodedKey)) return null;
            using var root = X509CertificateLoader.LoadCertificate(rootCertificate);
            using var leaf = X509CertificateLoader.LoadCertificate((byte[])certificates[0]);
            using var chain = new X509Chain();
            chain.ChainPolicy.TrustMode = X509ChainTrustMode.CustomRootTrust;
            chain.ChainPolicy.CustomTrustStore.Add(root);
            chain.ChainPolicy.RevocationMode = X509RevocationMode.NoCheck;
            chain.ChainPolicy.DisableCertificateDownloads = true;
            chain.ChainPolicy.VerificationTime = clock.GetUtcNow().UtcDateTime;
            var intermediates = certificates.Skip(1).Select(x => X509CertificateLoader.LoadCertificate((byte[])x)).ToArray();
            try
            {
                chain.ChainPolicy.ExtraStore.AddRange(intermediates);
                if (!chain.Build(leaf) || !chain.ChainElements[^1].Certificate.RawData.AsSpan().SequenceEqual(rootCertificate)) return null;
            }
            finally { foreach (var certificate in intermediates) certificate.Dispose(); }
            var extension = leaf.Extensions.SingleOrDefault(x => x.Oid?.Value == "1.2.840.113635.100.8.2");
            if (extension is null) return null;
            var der = new AsnReader(extension.RawData, AsnEncodingRules.DER);
            var sequence = der.ReadSequence();
            var context = sequence.ReadSequence(new Asn1Tag(TagClass.ContextSpecific, 1, true));
            var nonce = context.ReadOctetString();
            context.ThrowIfNotEmpty(); sequence.ThrowIfNotEmpty(); der.ThrowIfNotEmpty();
            if (!CryptographicOperations.FixedTimeEquals(nonce, SHA256.HashData([.. auth, .. clientDataHash]))) return null;
            using var key = leaf.GetECDsaPublicKey();
            if (key is null || key.KeySize != 256) return null;
            var parameters = key.ExportParameters(false);
            if (parameters.Curve.Oid.Value != ECCurve.NamedCurves.nistP256.Oid.Value) return null;
            byte[] point = [4, .. parameters.Q.X!, .. parameters.Q.Y!];
            if (!CryptographicOperations.FixedTimeEquals(SHA256.HashData(point), decodedKey)) return null;
            // The embedded COSE public key must be the same P-256 credential key.
            var cose = AppAttestCbor.Map(auth[(55 + credentialLength)..]);
            if ((long)cose[1L] != 2 || (long)cose[3L] != -7 || (long)cose[-1L] != 1 ||
                !((byte[])cose[-2L]).AsSpan().SequenceEqual(parameters.Q.X) ||
                !((byte[])cose[-3L]).AsSpan().SequenceEqual(parameters.Q.Y)) return null;
            return key.ExportSubjectPublicKeyInfo();
        }
        catch (Exception ex) when (Malformed(ex)) { return null; }
    }
    public uint? VerifyAssertion(string encoded, byte[] publicKey, byte[] clientDataHash, uint previousCounter)
    {
        try
        {
            var map = AppAttestCbor.Map(Decode(encoded));
            var auth = (byte[])map["authenticatorData"];
            var signature = (byte[])map["signature"];
            if (auth.Length != 37 || !ValidRp(auth)) return null;
            var counter = BinaryPrimitives.ReadUInt32BigEndian(auth.AsSpan(33, 4));
            if (counter <= previousCounter) return null;
            using var key = ECDsa.Create();
            key.ImportSubjectPublicKeyInfo(publicKey, out var read);
            if (read != publicKey.Length || key.KeySize != 256) return null;
            var nonce = SHA256.HashData([.. auth, .. clientDataHash]);
            // App Attest signs the nonce as an ECDSA message, so the signature
            // algorithm applies SHA256 once more; VerifyHash(nonce, ...) is wrong.
            return key.VerifyData(nonce, signature, HashAlgorithmName.SHA256, DSASignatureFormat.Rfc3279DerSequence) ? counter : null;
        }
        catch (Exception ex) when (Malformed(ex)) { return null; }
    }
    private bool ValidRp(byte[] auth) => CryptographicOperations.FixedTimeEquals(auth.AsSpan(0, 32), SHA256.HashData(Encoding.UTF8.GetBytes(options.TeamId + "." + options.BundleId)));
    private static byte[] Decode(string value) => value.Length is > 0 and <= 90000 ? Convert.FromBase64String(value) : throw new FormatException();
    private static bool Malformed(Exception ex) => ex is FormatException or CryptographicException or AsnContentException or KeyNotFoundException or InvalidCastException or ArgumentException or InvalidOperationException or IndexOutOfRangeException;
}
