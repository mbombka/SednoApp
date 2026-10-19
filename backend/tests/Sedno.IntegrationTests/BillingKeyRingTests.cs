using System.Security.Cryptography;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.AspNetCore.DataProtection.KeyManagement;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Sedno.IntegrationTests;

public sealed class BillingKeyRingTests
{
    private static ServiceProvider Services(string path)
    {
        var services = new ServiceCollection();
        services.AddLogging();
        services.AddDataProtection().SetApplicationName("Sedno")
            .PersistKeysToFileSystem(new DirectoryInfo(path)).DisableAutomaticKeyGeneration();
        return services.BuildServiceProvider();
    }

    [Fact]
    public void EmptyKeyRingFailsBeforeServingTraffic()
    {
        var path = Path.Combine(Path.GetTempPath(), "sedno-keyring-test-" + Guid.NewGuid());
        try
        {
            using var services = Services(path);
            Assert.Throws<CryptographicException>(() => CloudRunHosting.VerifyBillingKeyRing(services));
        }
        finally { if (Directory.Exists(path)) Directory.Delete(path, true); }
    }

    [Fact]
    public void IndependentInstancesDecryptExistingPurchasesWithoutGeneratingKeys()
    {
        var path = Path.Combine(Path.GetTempPath(), "sedno-keyring-test-" + Guid.NewGuid());
        try
        {
            using var first = Services(path);
            var now = DateTimeOffset.UtcNow;
            first.GetRequiredService<IKeyManager>().CreateNewKey(now.AddMinutes(-1), now.AddDays(30));
            CloudRunHosting.VerifyBillingKeyRing(first);
            var encrypted = first.GetRequiredService<IDataProtectionProvider>()
                .CreateProtector("Sedno.PlayPurchase.v1").Protect("synthetic-purchase-token");
            var before = Directory.GetFiles(path).ToDictionary(file => file, File.ReadAllText);
            using var second = Services(path);
            CloudRunHosting.VerifyBillingKeyRing(second);
            Assert.Equal("synthetic-purchase-token", second.GetRequiredService<IDataProtectionProvider>()
                .CreateProtector("Sedno.PlayPurchase.v1").Unprotect(encrypted));
            Assert.Equal(before.Count, Directory.GetFiles(path).Length);
            foreach (var (file, text) in before) Assert.Equal(text, File.ReadAllText(file));
        }
        finally { if (Directory.Exists(path)) Directory.Delete(path, true); }
    }
}
