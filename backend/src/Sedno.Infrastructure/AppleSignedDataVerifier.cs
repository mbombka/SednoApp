using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;
using System.Text;
using System.Text.Json;

namespace Sedno.Infrastructure;

public interface IAppleSignedDataVerifier
{
    JsonElement Verify(string signedData);
}

// Apple's App Store Server Library certificate policy: pinned roots, Apple signing
// leaf/intermediate OIDs, ES256 signature, certificate validity and online revocation.
// A trust/network failure never grants entitlement. No unsigned/Xcode bypass exists.
public sealed class AppleSignedDataVerifier : IAppleSignedDataVerifier, IDisposable
{
    private readonly X509Certificate2Collection _roots = [];
    private readonly TimeProvider _clock;
    public AppleSignedDataVerifier(AppleBillingOptions options, TimeProvider clock)
    {
        options.Validate();
        _clock = clock;
        foreach (var path in options.RootCertificatePaths)
            _roots.Add(X509CertificateLoader.LoadCertificateFromFile(path));
        if (_roots.Count == 0) throw new InvalidOperationException("Apple trust roots are required.");
    }

    public JsonElement Verify(string signedData)
    {
        if (string.IsNullOrWhiteSpace(signedData) || signedData.Length > 131072)
            throw new InvalidOperationException("Invalid Apple signed data.");
        var parts = signedData.Split('.');
        if (parts.Length != 3) throw new InvalidOperationException("Invalid Apple signed data.");
        using var header = JsonDocument.Parse(Decode(parts[0]));
        var h = header.RootElement;
        if (h.GetProperty("alg").GetString() != "ES256" || h.TryGetProperty("crit", out _))
            throw new InvalidOperationException("Unsupported Apple signature.");
        var certificates = h.GetProperty("x5c");
        if (certificates.GetArrayLength() != 3) throw new InvalidOperationException("Invalid Apple certificate chain.");
        using var leaf = X509CertificateLoader.LoadCertificate(Convert.FromBase64String(certificates[0].GetString()!));
        using var intermediate = X509CertificateLoader.LoadCertificate(Convert.FromBase64String(certificates[1].GetString()!));
        if (!leaf.Extensions.Any(x => x.Oid?.Value == "1.2.840.113635.100.6.11.1") ||
            !intermediate.Extensions.Any(x => x.Oid?.Value == "1.2.840.113635.100.6.2.1"))
            throw new InvalidOperationException("Invalid Apple signing certificate.");
        using var chain = new X509Chain();
        chain.ChainPolicy.TrustMode = X509ChainTrustMode.CustomRootTrust;
        chain.ChainPolicy.CustomTrustStore.AddRange(_roots);
        chain.ChainPolicy.ExtraStore.Add(intermediate);
        chain.ChainPolicy.DisableCertificateDownloads = true;
        chain.ChainPolicy.RevocationMode = X509RevocationMode.Online;
        chain.ChainPolicy.RevocationFlag = X509RevocationFlag.ExcludeRoot;
        chain.ChainPolicy.VerificationTime = _clock.GetUtcNow().UtcDateTime;
        chain.ChainPolicy.UrlRetrievalTimeout = TimeSpan.FromSeconds(5);
        if (!chain.Build(leaf) || chain.ChainElements.Count != 3 ||
            !chain.ChainElements[1].Certificate.RawData.AsSpan().SequenceEqual(intermediate.RawData))
            throw new InvalidOperationException("Untrusted Apple certificate chain.");
        using var key = leaf.GetECDsaPublicKey();
        if (key is null || key.KeySize != 256 || !key.VerifyData(Encoding.ASCII.GetBytes(parts[0] + "." + parts[1]),
            Decode(parts[2]), HashAlgorithmName.SHA256, DSASignatureFormat.IeeeP1363FixedFieldConcatenation))
            throw new InvalidOperationException("Invalid Apple signature.");
        using var document = JsonDocument.Parse(Decode(parts[1]));
        var payload = document.RootElement;
        var signedAt = DateTimeOffset.FromUnixTimeMilliseconds(payload.GetProperty("signedDate").GetInt64());
        if (signedAt > _clock.GetUtcNow().AddMinutes(1)) throw new InvalidOperationException("Future Apple signature.");
        return payload.Clone();
    }

    internal static byte[] Decode(string value) => Convert.FromBase64String(value.Replace('-', '+').Replace('_', '/') +
        new string('=', (4 - value.Length % 4) % 4));
    internal static string Encode(byte[] value) => Convert.ToBase64String(value).TrimEnd('=').Replace('+', '-').Replace('/', '_');
    public void Dispose() { foreach (var root in _roots) root.Dispose(); }
}
