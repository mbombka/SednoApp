using Sedno.Application;
using Sedno.Domain;
using Xunit;

namespace Sedno.UnitTests;

public sealed class PolicyTests
{
    [Fact]
    public void LimitsAndUtcReset()
    {
        Assert.Equal(5, QuotaPolicy.Limit(false));
        Assert.Equal(400, QuotaPolicy.Limit(true));
        var now = new DateTimeOffset(2026, 10, 14, 23, 59, 59, TimeSpan.Zero);
        Assert.Equal(new DateOnly(2026, 10, 14), QuotaPolicy.Day(now));
        Assert.Equal(new DateTimeOffset(2026, 10, 15, 0, 0, 0, TimeSpan.Zero), QuotaPolicy.ResetAt(now));
    }

    [Theory]
    [InlineData("")]
    [InlineData(" \n\t")]
    public void RejectsBlank(string text) => Assert.Equal("empty_text",
        Assert.Throws<InputValidationException>(() => SimplificationService.Validate(new("request", text))).Code);

    [Fact]
    public void CountsPolishAndEmojiGraphemes()
    {
        SimplificationService.Validate(new("request", string.Concat(Enumerable.Repeat("👩‍💻", 4000))));
        SimplificationService.Validate(new("request", "Zażółć gęślą jaźń"));
        Assert.Equal("text_too_long", Assert.Throws<InputValidationException>(() =>
            SimplificationService.Validate(new("request", new string('ą', 4001)))).Code);
    }
}
