using Google.Cloud.Firestore;
using Sedno.Domain;
using Sedno.Infrastructure;
using Xunit;

namespace Sedno.UnitTests;

public sealed class TesterAccessSerializationTests
{
    [Fact]
    public void GrantUsesTimestampAndPreservesOffsetAsInstant()
    {
        var expiry = new DateTimeOffset(2026, 11, 15, 20, 0, 0, TimeSpan.FromHours(1));
        var fields = FirestoreStore.Encode(new VerifiedAccount { TesterAccessExpiresAt = expiry });
        Assert.Equal(expiry.ToUniversalTime(), Assert.IsType<Timestamp>(fields["TesterAccessExpiresAt"]).ToDateTimeOffset());
    }
}
