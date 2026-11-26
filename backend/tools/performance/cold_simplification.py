#!/usr/bin/env python3
"""Compare the first simplification in a fresh Docker container with two startup gates."""

import argparse
import asyncio
import base64
from contextlib import asynccontextmanager
import json
from pathlib import Path
import secrets
import subprocess
import tempfile
import time
from uuid import uuid4

from local import available_port, elapsed, guest, request, simplify, summary

EMULATOR = "gcr.io/google.com/cloudsdktool/google-cloud-cli:emulators"
HTTP_PROBE_PERIOD_SECONDS = 5


@asynccontextmanager
async def container(name, args):
    started = time.perf_counter()
    launch = await asyncio.create_subprocess_exec(
        "docker", "run", "--detach", "--rm", "--name", name, "--network", "host", *args,
        stdout=subprocess.DEVNULL,
    )
    try:
        if await launch.wait() != 0:
            raise RuntimeError(f"Docker could not start {name}")
        yield started
    finally:
        subprocess.run(["docker", "stop", "--time", "2", name],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=False)


def log_text(name):
    return subprocess.check_output(["docker", "logs", name], stderr=subprocess.STDOUT, text=True)


def api_args(image, settings, port):
    return ["--cpus", "1", "--env-file", str(settings),
            "-e", f"ASPNETCORE_URLS=http://127.0.0.1:{port}", image, "sedno"]


async def wait_for_gate(port, started, mode):
    attempt = 0
    while time.perf_counter() - started < 25:
        attempt += 1
        try:
            if mode == "tcp":
                _, writer = await asyncio.open_connection("127.0.0.1", port)
                writer.close()
                await writer.wait_closed()
                return attempt
            status, _, _, _ = await asyncio.wait_for(request(port, "/health/ready"), timeout=2)
            if status == 200:
                return attempt
        except (OSError, TimeoutError):
            pass
        interval = HTTP_PROBE_PERIOD_SECONDS if mode == "http5" else .01
        next_probe = started + attempt * interval
        await asyncio.sleep(max(0.001, next_probe - time.perf_counter()) if mode == "http5" else interval)
    raise TimeoutError("Startup gate did not pass")


async def measure(image, settings, name, mode, token):
    port = available_port()
    # Start the clock before Docker launches the fresh instance and the first probe.
    started = time.perf_counter()

    async def send_first_request():
        try:
            attempts = await wait_for_gate(port, started, mode)
        except TimeoutError:
            return {"status": "startup_gate_timeout", "total_ms": round(elapsed(started), 2)}
        gate_ms = elapsed(started)
        _, status, request_ms, _ = await simplify(port, token)
        return {"status": status, "gate_ms": round(gate_ms, 2),
                "request_ms": round(request_ms, 2) if request_ms is not None else None,
                "total_ms": round(elapsed(started), 2), "probe_attempts": attempts}

    pending = asyncio.create_task(send_first_request())
    try:
        async with container(name, api_args(image, settings, port)):
            return await pending
    finally:
        if not pending.done():
            pending.cancel()
            await asyncio.gather(pending, return_exceptions=True)


async def run(args):
    prefix = f"sedno-cold-request-{uuid4().hex[:8]}"
    emulator_port = available_port()
    with tempfile.TemporaryDirectory() as workdir:
        settings = Path(workdir) / "env"
        settings.touch(mode=0o600)
        env = {
            "ASPNETCORE_ENVIRONMENT": "Development", "DOTNET_ENVIRONMENT": "Development",
            "Firestore__ProjectId": "demo-sedno-cold-request", "Firestore__UseEmulator": "true",
            "Firestore__RequireMigration": "false", "FIRESTORE_EMULATOR_HOST": f"127.0.0.1:{emulator_port}",
            "Model__Provider": "mock", "PlayIntegrity__Provider": "mock", "Billing__Enabled": "false",
            "Security__CredentialKey": base64.b64encode(secrets.token_bytes(32)).decode(),
            "Security__FingerprintKey": base64.b64encode(secrets.token_bytes(32)).decode(),
        }
        settings.write_text("".join(f"{key}={value}\n" for key, value in env.items()))
        async with container(prefix + "-db", [EMULATOR, "gcloud", "emulators", "firestore", "start",
                                                f"--host-port=127.0.0.1:{emulator_port}", "--quiet"]):
            for _ in range(80):
                if "Dev App Server is now running" in log_text(prefix + "-db"):
                    break
                await asyncio.sleep(.25)
            else:
                raise TimeoutError("Firestore emulator did not start")
            port = available_port()
            async with container(prefix + "-seed", api_args(args.image, settings, port)) as started:
                await wait_for_gate(port, started, "tcp")
                token_count = args.trials * 2 + (2 if args.check_unavailable else 0)
                tokens = [await guest(port, index) for index in range(token_count)]
            samples = {"http5": [], "tcp": []}
            for index in range(args.trials):
                order = ("http5", "tcp") if index % 2 == 0 else ("tcp", "http5")
                for mode in order:
                    sample = await measure(args.image, settings, prefix + "-api", mode, tokens.pop())
                    samples[mode].append(sample)
                    print(f"{mode} {index + 1}/{args.trials}: {sample['status']} {sample['total_ms']:.0f} ms",
                          flush=True)
        results = {}
        for mode, rows in samples.items():
            successes = [row for row in rows if row["status"] == "200"]
            results[mode] = {
                "successful": len(successes),
                "samples": rows,
                "gate_ms": summary(row["gate_ms"] for row in successes),
                "request_ms": summary(row["request_ms"] for row in successes),
                "total_ms": summary(row["total_ms"] for row in successes),
            }
        if args.check_unavailable:
            results["firestore_unavailable"] = {}
            for mode in ("tcp", "http5"):
                results["firestore_unavailable"][mode] = await measure(
                    args.image, settings, prefix + "-api", mode, tokens.pop(),
                )
        args.output.write_text(json.dumps(results, indent=2) + "\n")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--image", required=True)
    parser.add_argument("--trials", type=int, default=30)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--check-unavailable", action="store_true",
                        help="Also compare both startup gates after stopping the test emulator.")
    args = parser.parse_args()
    if args.trials < 1:
        parser.error("--trials must be positive")
    asyncio.run(run(args))
