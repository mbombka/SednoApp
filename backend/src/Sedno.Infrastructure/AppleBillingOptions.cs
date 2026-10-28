namespace Sedno.Infrastructure;

// Credentials are server-only. Local StoreKit/Xcode transactions are deliberately unsupported.
public sealed class AppleBillingOptions
{
    public bool Enabled { get; set; }
    public string BundleId { get; set; } = "xyz.sedno.app";
    public string ProductId { get; set; } = "";
    public long AppAppleId { get; set; }
    public string Environment { get; set; } = "Production";
    public string IssuerId { get; set; } = "";
    public string KeyId { get; set; } = "";
    public string PrivateKeyPath { get; set; } = "";
    public string[] RootCertificatePaths { get; set; } = [];

    public void Validate()
    {
        if (!Enabled) return;
        if (Environment is not ("Production" or "Sandbox") ||
            new[] { BundleId, ProductId, IssuerId, KeyId, PrivateKeyPath }.Any(string.IsNullOrWhiteSpace) ||
            RootCertificatePaths.Length == 0 || (Environment == "Production" && AppAppleId <= 0))
            throw new InvalidOperationException("Complete AppleBilling configuration and trusted Apple root certificates are required.");
    }
}
