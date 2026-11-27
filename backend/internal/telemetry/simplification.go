// Package telemetry records simplification latency without request content.
package telemetry

import (
	"context"
	"log/slog"
	"time"
)

type stageKey struct{}

type Timing struct {
	start  time.Time
	stages []any
}

func Start(ctx context.Context) (context.Context, *Timing) {
	timing := &Timing{start: time.Now()}
	return context.WithValue(ctx, stageKey{}, timing), timing
}

func Measure(ctx context.Context, stage string) func() {
	start := time.Now()
	return func() { Record(ctx, stage, start) }
}

func Record(ctx context.Context, stage string, start time.Time) {
	if timing, ok := ctx.Value(stageKey{}).(*Timing); ok {
		timing.stages = append(timing.stages, stage+"_ms", float64(time.Since(start))/float64(time.Millisecond))
	}
}

func (t *Timing) Log(status int) {
	slog.Info("simplification request", append([]any{
		"status", status, "duration_ms", float64(time.Since(t.start)) / float64(time.Millisecond),
	}, t.stages...)...)
}
