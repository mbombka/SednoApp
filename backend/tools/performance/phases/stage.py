#!/usr/bin/env python3
"""Prepare a disposable build context with startup timing in the Sedno copy."""

import argparse
from pathlib import Path
import shutil


def replace_once(source, anchor, replacement):
    if source.count(anchor) != 1:
        raise ValueError(f"Expected one anchor in Program.cs: {anchor!r}")
    return source.replace(anchor, replacement, 1)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("context", type=Path)
    args = parser.parse_args()
    folder = Path(__file__).resolve().parent
    root = folder.parents[3]
    shutil.copytree(root / "backend/src", args.context / "backend/src",
                    ignore=shutil.ignore_patterns("bin", "obj", "bin\\*", "obj\\*"))
    for filename in ("Dockerfile", "main.go"):
        shutil.copy2(folder / filename, args.context / filename)
    privacy = "docs/public/prywatnosc/index.html"
    (args.context / privacy).parent.mkdir(parents=True)
    shutil.copy2(root / privacy, args.context / privacy)

    program = args.context / "backend/src/Sedno.Api/Program.cs"
    source = program.read_text()
    source = replace_once(source, "var builder = WebApplication.CreateBuilder(args);",
                          'StartupMark("managed_entry");\nvar builder = WebApplication.CreateBuilder(args);')
    source = replace_once(source, 'app.MapHealthChecks("/health/live"',
                          '''var firstStartupProbe = 0;
app.Use(async (context, next) =>
{
    if (context.Request.Path == "/health/live" && !context.Request.QueryString.HasValue
        && Interlocked.Exchange(ref firstStartupProbe, 1) == 0)
        StartupMark("probe_arrived");
    await next(context);
});
app.MapHealthChecks("/health/live"''')
    source = replace_once(source, '    await db.ReadyAsync(ct) ? Results.Ok(new { status = "ready" }) : Results.StatusCode(503));',
                          '''{
    var started = System.Diagnostics.Stopwatch.GetTimestamp();
    var ready = await db.ReadyAsync(ct);
    Console.WriteLine(FormattableString.Invariant(
        $"sedno-phase firestore_read_us {(long)System.Diagnostics.Stopwatch.GetElapsedTime(started).TotalMicroseconds}"));
    return ready ? Results.Ok(new { status = "ready" }) : Results.StatusCode(503);
});''')
    source = replace_once(source, "app.Run();",
                          '''app.Lifetime.ApplicationStarted.Register(() => StartupMark("http_ready"));
app.Run();

static void StartupMark(string phase)
{
    var elapsed = DateTimeOffset.UtcNow - DateTimeOffset.UnixEpoch;
    Console.WriteLine(FormattableString.Invariant($"sedno-phase {phase} {elapsed.Ticks / 10}"));
}''')
    program.write_text(source)


if __name__ == "__main__":
    main()
