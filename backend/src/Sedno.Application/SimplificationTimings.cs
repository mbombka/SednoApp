namespace Sedno.Application;

public enum SimplificationStage
{
    Authentication, Reservation, Model, Completion, QuotaRead, QuotaLock,
    AgentHeaders, AgentSession, AgentFirstOutput, AgentFinalAnswer, AgentTurnComplete
}

// Per-request durations only. Never accepts content, credentials or session IDs.
public sealed class SimplificationTimings(TimeProvider clock)
{
    private readonly Dictionary<SimplificationStage, double> _milliseconds = [];
    public double this[SimplificationStage stage] => _milliseconds.GetValueOrDefault(stage, -1);
    public IDisposable Measure(SimplificationStage stage) => new Measurement(this, stage, clock.GetTimestamp());
    public void Milestone(SimplificationStage stage, long started)
    {
        _milliseconds.TryAdd(stage, clock.GetElapsedTime(started).TotalMilliseconds);
    }
    private sealed class Measurement(SimplificationTimings owner, SimplificationStage stage, long started) : IDisposable
    {
        private bool _disposed;
        public void Dispose()
        {
            if (_disposed) return;
            _disposed = true;
            var elapsed = owner.ElapsedMilliseconds(started);
            owner._milliseconds[stage] = Math.Max(0, owner[stage]) + elapsed;
        }
    }
    private double ElapsedMilliseconds(long started) => clock.GetElapsedTime(started).TotalMilliseconds;
}
