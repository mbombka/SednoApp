#!/usr/bin/env python3
"""Measure the Sedno API using a dedicated localhost Firestore emulator."""

import argparse
import asyncio
import base64
from collections import Counter
from contextlib import contextmanager
import http.client
import io
import json
import math
import os
from pathlib import Path
import re
import secrets
import socket
import statistics
import subprocess
import tempfile
import time
from types import SimpleNamespace
from uuid import uuid4

LEVELS = (1, 10, 100, 1000)
ROUNDS = 10
STAGES = ("TotalMs", "AuthMs", "ReserveMs", "ModelMs", "CompleteMs", "QuotaMs", "QuotaLockMs")
LOG = re.compile(r"Trace=([a-f0-9]{32}) Status=(\d+) ((?:\w+Ms=-?[\d.]+ ?)+)")
FIXTURE = "Wniosek należy dostarczyć do urzędu w terminie czternastu dni od otrzymania decyzji."


def summary(values):
    values = sorted(values)
    if not values:
        return None
    return {
        "n": len(values),
        "mean": round(statistics.mean(values), 2),
        "median": round(statistics.median(values), 2),
        "p95": round(values[math.ceil(len(values) * .95) - 1], 2),
        "max": round(values[-1], 2),
    }


def elapsed(start):
    return (time.perf_counter() - start) * 1000


def available_port():
    with socket.socket() as listener:
        listener.bind(("127.0.0.1", 0))
        return listener.getsockname()[1]


@contextmanager
def server(dll, emulator_port, project, cpu, log):
    env = {
        **os.environ, "ASPNETCORE_ENVIRONMENT": "Development", "DOTNET_ENVIRONMENT": "Development",
        "Firestore__ProjectId": project, "Firestore__DatabaseId": "(default)",
        "Firestore__UseEmulator": "true", "Firestore__RequireMigration": "false",
        "FIRESTORE_EMULATOR_HOST": f"127.0.0.1:{emulator_port}", "Model__Provider": "mock",
        "Billing__Enabled": "false", "PlayIntegrity__Provider": "mock",
        "Google__CredentialProvider": "file", "RateLimiting__PermitLimit": "60",
        "Security__CredentialKey": base64.b64encode(secrets.token_bytes(32)).decode(),
        "Security__FingerprintKey": base64.b64encode(secrets.token_bytes(32)).decode(),
        "Logging__Console__FormatterName": "simple",
    }
    for key in ("K_SERVICE", "CLOUD_RUN_JOB", "ASPNETCORE_HTTP_PORTS", "COMPlus_ReadyToRun",
                "DOTNET_ReadyToRun"):
        env.pop(key, None)
    port = available_port()
    env["ASPNETCORE_URLS"] = f"http://127.0.0.1:{port}"
    started = time.perf_counter()
    process = subprocess.Popen(
        ["taskset", "-c", str(cpu), "dotnet", str(dll)], cwd=dll.parent,
        env=env, stdout=log, stderr=subprocess.STDOUT,
    )
    try:
        yield process, port, started
    finally:
        if process.poll() is None:
            process.terminate()
            try:
                process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait()


async def request(port, path, payload=None, token=None, trace=None, source=None, gate=None):
    body = b"" if payload is None else json.dumps(payload).encode()
    method = "GET" if payload is None else "POST"
    headers = [f"{method} {path} HTTP/1.1", f"Host: 127.0.0.1:{port}", "Connection: close"]
    if payload is not None:
        headers.extend(("Content-Type: application/json", f"Content-Length: {len(body)}"))
    if token:
        headers.append(f"Authorization: Bearer {token}")
    if trace:
        headers.append(f"traceparent: 00-{trace}-0123456789abcdef-01")
    request = ("\r\n".join(headers) + "\r\n\r\n").encode() + body
    writer = None
    try:
        reader, writer = await open_http(port, source, gate)
        if gate is not None:
            await gate[0].wait()
        sent = time.perf_counter()
        async with asyncio.timeout(35):
            writer.write(request)
            await writer.drain()
            raw = await reader.read()
        duration = elapsed(sent)
        response = http.client.HTTPResponse(SimpleNamespace(makefile=lambda *a, **k: io.BytesIO(raw)))
        response.begin()
        return response.status, response.read(), duration, sent
    finally:
        if writer is not None:
            writer.close()


async def open_http(port, source, gate):
    try:
        async with asyncio.timeout(15):
            return await asyncio.open_connection("127.0.0.1", port, local_addr=source)
    finally:
        if gate is not None:
            gate[1].put_nowait(None)


async def ready(process, port, started):
    while elapsed(started) < 20000 and process.poll() is None:
        try:
            status, _, _, _ = await request(port, "/health/ready")
            if status == 200:
                return elapsed(started)
        except OSError:
            pass
        await asyncio.sleep(.01)
    raise RuntimeError("API did not reach /health/ready")


async def guest(port, index):
    # Spread only session creation over loopback peers, keeping the normal limiter.
    source = (f"127.0.0.{2 + index % 40}", 0)
    status, body, _, _ = await request(
        port, "/v1/guest-sessions", {"installationId": uuid4().hex}, source=source,
    )
    if status != 200:
        raise RuntimeError(f"Guest preparation returned HTTP {status}")
    return json.loads(body)["accessToken"]


async def simplify(port, token, gate=None):
    trace = uuid4().hex
    try:
        status, body, duration, sent = await request(
            port, "/v1/simplifications", {"requestId": uuid4().hex, "text": FIXTURE},
            token=token, trace=trace, gate=gate,
        )
        valid = status == 200 and bool(json.loads(body)["result"]["text"])
        return trace, str(status) if status != 200 or valid else "invalid_200", duration, sent
    except (OSError, TimeoutError, ValueError, KeyError, http.client.HTTPException) as error:
        return trace, type(error).__name__, None, None


def read_timings(log):
    log.seek(0)
    timings = {}
    for line in log:
        match = LOG.search(line)
        if match:
            trace, status, fields = match.groups()
            timings[trace] = (status, {key: float(value) for key, value in
                                      (field.split("=") for field in fields.split())})
    return timings


async def load(port, log):
    count = math.ceil(sum(LEVELS) * ROUNDS / 5)
    tokens = []
    for start in range(0, count + 1, 20):
        tokens.extend(await asyncio.gather(*(guest(port, index)
                      for index in range(start, min(start + 20, count + 1)))))
    if (await simplify(port, tokens.pop()))[1] != "200":
        raise RuntimeError("Warm-up simplification failed")
    cursor = 0
    runs = []
    for size in LEVELS:
        for round_number in range(1, ROUNDS + 1):
            gate = (asyncio.Event(), asyncio.Queue())
            tasks = [asyncio.create_task(simplify(port, tokens[index % count], gate))
                     for index in range(cursor, cursor + size)]
            cursor += size
            for _ in tasks:
                await gate[1].get()
            release = time.perf_counter()
            gate[0].set()
            responses = await asyncio.gather(*tasks)
            runs.append((round_number, size, elapsed(release), release, responses))
            print(f"Round {round_number}, {size} users: {dict(Counter(row[1] for row in responses))}",
                  flush=True)
            await asyncio.sleep(5 if size == 1000 else .5)

    timings = read_timings(log)
    by_level = {size: [] for size in LEVELS}
    successes = {size: [] for size in LEVELS}
    all_responses = {size: [] for size in LEVELS}
    for round_number, size, wall_ms, release, responses in runs:
        entries = [(duration, timings.get(trace, (None, {}))[1]) for trace, status, duration, _ in responses
                   if status == "200"]
        successes[size].extend(entries)
        observed = [(duration, timings.get(trace, (None, {}))[1]) for trace, _, duration, _ in responses]
        all_responses[size].extend(observed)
        by_level[size].append({
            "round": round_number, "outcomes": dict(Counter(row[1] for row in responses)),
            "backend_statuses": dict(Counter(timings[trace][0] for trace, *_ in responses if trace in timings)),
            "backend_matches": sum(bool(stages) for _, stages in observed),
            "batch_ms": round(wall_ms, 2),
            "dispatch_ms": summary((sent - release) * 1000 for *_, sent in responses if sent is not None),
            "success": summarize_requests(entries),
            "all_outcomes": summarize_requests(observed),
        })
    return {size: {"rounds": by_level[size], "success": summarize_requests(successes[size]),
                   "all_outcomes": summarize_requests(all_responses[size])} for size in LEVELS}


def summarize_requests(entries):
    return {
        "client_ms": summary(duration for duration, _ in entries if duration is not None),
        "backend_ms": {stage: summary(timing[stage] for _, timing in entries if timing.get(stage, -1) >= 0)
                       for stage in STAGES},
    }


async def run(args):
    cpu = min(os.sched_getaffinity(0))
    project = f"demo-sedno-perf-{uuid4().hex[:8]}"
    if args.command == "load":
        with tempfile.TemporaryFile(mode="w+") as log:
            with server(args.dll, args.emulator_port, project, cpu, log) as (process, port, started):
                await ready(process, port, started)
                results = await load(port, log)
        return {"api_logical_cpus": 1, "rounds_per_level": ROUNDS, "levels": results}

    results = {"api_logical_cpus": 1, "trials_per_variant": args.trials, "variants": {}}
    for trial in range(args.trials):
        variants = (("il", args.dll), ("r2r", args.r2r))
        if trial % 2:
            variants = reversed(variants)
        for name, dll in variants:
            with tempfile.TemporaryFile(mode="w+") as log:
                with server(dll, args.emulator_port, project, cpu, log) as (process, port, started):
                    readiness = await ready(process, port, started)
                    token = await guest(port, 0)
                    trace, status, duration, _ = await simplify(port, token)
                    if status != "200":
                        raise RuntimeError(f"{name} returned {status} for first simplification")
                stages = read_timings(log).get(trace, (None, {}))[1]
                samples = results["variants"].setdefault(name, {"samples": []})["samples"]
                samples.append({"ready_ms": round(readiness, 2), "first_client_ms": round(duration, 2),
                                "first_backend_ms": stages.get("TotalMs")})
    for sample_set in results["variants"].values():
        for field in ("ready_ms", "first_client_ms", "first_backend_ms"):
            sample_set[field] = summary(sample[field] for sample in sample_set["samples"]
                                        if sample[field] is not None)
    return results


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("load", "cold"))
    parser.add_argument("--dll", type=lambda value: Path(value).resolve(), required=True)
    parser.add_argument("--r2r", type=lambda value: Path(value).resolve())
    parser.add_argument("--emulator-port", type=int, default=18781)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--trials", type=int, default=30)
    args = parser.parse_args()
    if args.command == "cold" and (args.r2r is None or args.trials < 1):
        parser.error("cold requires --r2r and at least one trial")
    args.output.write_text(json.dumps(asyncio.run(run(args)), indent=2) + "\n")


if __name__ == "__main__":
    main()
