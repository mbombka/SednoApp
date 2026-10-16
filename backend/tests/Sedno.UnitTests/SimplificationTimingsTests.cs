using Sedno.Application;
using Xunit;

namespace Sedno.UnitTests;

public sealed class SimplificationTimingsTests
{
    private sealed class Clock : TimeProvider
    {
        public long Timestamp;
        public override long TimestampFrequency => 1000;
        public override long GetTimestamp() => Timestamp;
    }
    [Fact]
    public void MeasuresAccumulatedStagesAndFirstMilestonesWithInjectedTime()
    {
        var clock = new Clock();
        var timings = new SimplificationTimings(clock);
        Assert.Equal(-1, timings[SimplificationStage.Model]);
        var measurement = timings.Measure(SimplificationStage.QuotaLock);
        clock.Timestamp = 12;
        measurement.Dispose(); measurement.Dispose();
        using (timings.Measure(SimplificationStage.QuotaLock)) clock.Timestamp += 8;
        Assert.Equal(20, timings[SimplificationStage.QuotaLock]);
        timings.Milestone(SimplificationStage.AgentFirstOutput, 0);
        clock.Timestamp += 100;
        timings.Milestone(SimplificationStage.AgentFirstOutput, 0);
        Assert.Equal(20, timings[SimplificationStage.AgentFirstOutput]);
    }
}
