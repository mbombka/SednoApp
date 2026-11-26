#!/usr/bin/env python3
"""Run the startup experiment on dedicated, private Cloud Run services."""

import argparse
import base64
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
import http.client
import json
from pathlib import Path
import re
import secrets
import subprocess
import tempfile
import time
from urllib.parse import urlsplit

from local import summary

VARIANTS = (("il", False), ("r2r", True))


def variants(args):
    return (("sedno", False), ("go", False)) if args.phase_timing_image else VARIANTS


def gcloud(*args):
    run = subprocess.run(["gcloud", *args, "--quiet"], text=True, stdout=subprocess.PIPE,
                         stderr=subprocess.PIPE, check=False)
    if run.returncode:
        # gcloud errors for deployment can include configuration. Do not echo them.
        raise RuntimeError(f"gcloud {' '.join(args[:3])} exited with status {run.returncode}")
    return run.stdout.strip()


def example_key():
    return base64.b64encode(secrets.token_bytes(32)).decode()


def service_name(args, variant):
    suffix = "" if args.probe_period == 5 else f"-p{args.probe_period}"
    return f"sedno-perf-{args.run_id}-{variant}{suffix}"


def deploy(args, variant, boosted, trial, env_file):
    service = service_name(args, variant)
    tag = f"trial-{trial:02}" if args.tagged_trials and trial != 1 else None
    route_flags = ("--no-traffic", f"--tag={tag}") if tag else ()
    probe = ("--startup-probe=httpGet.path=/health/live,httpGet.port=8080,"
             f"periodSeconds={args.probe_period},timeoutSeconds={min(2, args.probe_period)},"
             f"failureThreshold={120 // args.probe_period}")
    registry = f"{args.region}-docker.pkg.dev/{args.project}/{args.repository}"
    image = args.phase_timing_image or f"{registry}/sedno-perf-{args.run_id}:{variant}"
    command = (f"--args={variant}",) if args.phase_timing_image else ()
    gcloud("run", "deploy", service, f"--image={image}", *command,
           f"--project={args.project}", f"--region={args.region}",
           f"--service-account=sedno-perf-{args.run_id}@{args.project}.iam.gserviceaccount.com",
           f"--revision-suffix=t{trial:02}", f"--env-vars-file={env_file}",
           "--min=0", "--min-instances=0", "--max=1", "--max-instances=1",
           "--cpu=1", "--memory=512Mi", "--cpu-throttling", "--concurrency=80",
           "--timeout=30s", "--no-deploy-health-check", "--no-allow-unauthenticated",
           "--invoker-iam-check", probe, *route_flags,
           "--cpu-boost" if boosted else "--no-cpu-boost", "--format=none")
    route = json.loads(gcloud("run", "services", "describe", service, f"--project={args.project}",
                             f"--region={args.region}", "--format=json(status.url,status.traffic)"))["status"]
    revision = f"{service}-t{trial:02}"
    for target in route["traffic"]:
        if target.get("revisionName") != revision:
            continue
        if tag and target.get("tag") == tag:
            return service, revision, target["url"]
        if not tag and target.get("percent") == 100:
            return service, revision, route["url"]
    raise RuntimeError(f"{revision} does not have its expected route")


def hit(url, token, trial, phase):
    host = urlsplit(url).hostname
    connection = http.client.HTTPSConnection(host, timeout=35)
    try:
        connection.connect()
        started_at = datetime.now(timezone.utc).isoformat()
        begin = time.perf_counter()
        connection.request("GET", f"/health/live?trial={trial}&phase={phase}",
                           headers={"X-Serverless-Authorization": f"Bearer {token}"})
        response = connection.getresponse()
        response.read()
        return {"status": response.status, "ms": round((time.perf_counter() - begin) * 1000, 2),
                "started_at": started_at}
    finally:
        connection.close()


def measure(args, variant, boosted, trial, token, env_file):
    service, revision, url = deploy(args, variant, boosted, trial, env_file)
    cold = hit(url, token, trial, "cold")
    warm = hit(url, token, trial, "warm")
    if (cold["status"], warm["status"]) != (200, 200):
        raise RuntimeError(f"{revision} HTTP statuses: {cold['status']}, {warm['status']}")
    return trial, {"service": service, "revision": revision, "cold": cold, "warm": warm}


def read_startup_logs(args, variant):
    service = service_name(args, variant)
    logs = 'log_id("run.googleapis.com/requests") OR log_id("run.googleapis.com/varlog/system")'
    if args.phase_timing_image:
        logs += ' OR (log_id("run.googleapis.com/stdout") AND textPayload:"sedno-phase ")'
    filters = [
        'resource.type="cloud_run_revision"', f'resource.labels.service_name="{service}"',
        f"({logs})",
    ]
    return json.loads(gcloud("logging", "read", " AND ".join(filters),
                            f"--project={args.project}", "--freshness=4h", "--limit=3000",
                            "--format=json(timestamp,textPayload,labels.instanceId,resource.labels.revision_name,"
                            "httpRequest.requestUrl,httpRequest.status,httpRequest.latency)"))


def log_timestamp(entry):
    return datetime.fromisoformat(entry["timestamp"].replace("Z", "+00:00"))


def read_phases(entries, instance, start, probe):
    marks = {}
    for entry in entries:
        if entry.get("labels", {}).get("instanceId") != instance:
            continue
        match = re.fullmatch(r"sedno-phase ([a-z_]+) (\d+)", entry.get("textPayload", "").strip())
        if match:
            phase, value = match.groups()
            marks[phase] = int(value) / 1000

    if not {"entrypoint", "http_ready", "probe_arrived"} <= marks.keys():
        return {}
    started = log_timestamp(start).timestamp() * 1000
    confirmed = log_timestamp(probe).timestamp() * 1000
    durations = {
        "platform_to_entry_ms": marks["entrypoint"] - started,
        "entry_to_http_ms": marks["http_ready"] - marks["entrypoint"],
        "http_to_probe_arrival_ms": marks["probe_arrived"] - marks["http_ready"],
        "probe_arrival_to_confirmation_ms": confirmed - marks["probe_arrived"],
        "http_to_probe_confirmed_ms": confirmed - marks["http_ready"],
    }
    if {"dotnet_exec", "managed_entry"} <= marks.keys():
        durations.update({
            "launcher_ms": marks["dotnet_exec"] - marks["entrypoint"],
            "dotnet_to_managed_ms": marks["managed_entry"] - marks["dotnet_exec"],
            "managed_to_http_ms": marks["http_ready"] - marks["managed_entry"],
        })
    return {phase: round(value, 2) for phase, value in durations.items()}


def verify(args, samples):
    for variant, _ in variants(args):
        entries = read_startup_logs(args, variant)
        for item in samples[variant].values():
            instances = {}
            for phase in ("cold", "warm"):
                matches = [entry for entry in entries
                           if entry.get("resource", {}).get("labels", {}).get("revision_name") == item["revision"]
                           and entry.get("httpRequest", {}).get("requestUrl", "").endswith(
                               f"trial={item['trial']}&phase={phase}")]
                if len(matches) != 1:
                    continue
                request = matches[0]
                instance = request.get("labels", {}).get("instanceId")
                if not instance or request["httpRequest"].get("status") != 200:
                    continue
                instances[phase] = instance
                duration = request["httpRequest"].get("latency", "").removesuffix("s")
                if duration:
                    item[phase]["cloud_request_ms"] = round(float(duration) * 1000, 2)
                starts = [entry for entry in entries if entry.get("labels", {}).get("instanceId") == instance
                          and entry.get("textPayload", "").startswith("Starting new instance.")]
                if phase == "cold" and len(starts) == 1:
                    start = starts[0]
                    item["start_reason"] = start["textPayload"].split("Reason: ")[-1].split(" - ")[0]
                    item["verified_cold"] = item["start_reason"] == "AUTOSCALING"
                    delta = log_timestamp(start) - log_timestamp(request)
                    item["instance_start_minus_request_ms"] = round(delta.total_seconds() * 1000, 2)
                    item["requested_start"] = item["verified_cold"] and delta.total_seconds() >= -.25
                    probes = [entry for entry in entries if entry.get("labels", {}).get("instanceId") == instance
                              and "STARTUP HTTP probe succeeded" in entry.get("textPayload", "")]
                    if len(probes) == 1:
                        probe = probes[0]
                        item["start_to_probe_ms"] = round(
                            (log_timestamp(probe) - log_timestamp(start)).total_seconds() * 1000, 2)
                        attempts = re.search(r"succeeded after (\d+) attempts?", probe["textPayload"])
                        if attempts:
                            item["probe_attempts"] = int(attempts.group(1))
                        if args.phase_timing_image:
                            item["phases_ms"] = read_phases(entries, instance, start, probe)
            item["warm_same_instance"] = bool(instances.get("cold") and instances.get("cold") == instances.get("warm"))


def output(args, samples):
    results = {}
    for variant, _ in variants(args):
        rows = list(samples[variant].values())
        cold = [row for row in rows if row.get("verified_cold")]
        requested = [row for row in cold if row.get("requested_start")]
        results[variant] = {
            "requested_start_count": len(requested),
            "requested_start_client_ms": summary(row["cold"]["ms"] for row in requested),
            "verified_cold": len(cold),
            "first_client_ms": summary(row["cold"]["ms"] for row in cold),
            "first_cloud_request_ms": summary(row["cold"]["cloud_request_ms"] for row in cold
                                             if "cloud_request_ms" in row["cold"]),
            "start_to_probe_ms": summary(row["start_to_probe_ms"] for row in cold if "start_to_probe_ms" in row),
            "warm_client_ms": summary(row["warm"]["ms"] for row in cold if row.get("warm_same_instance")),
            "samples": rows,
        }
        if args.phase_timing_image:
            phases = [row["phases_ms"] for row in requested if row.get("phases_ms")]
            results[variant]["phases_ms"] = {
                phase: summary(row[phase] for row in phases if phase in row)
                for phase in sorted({key for row in phases for key in row})
            }
    args.output.write_text(json.dumps(results, indent=2) + "\n")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", required=True)
    parser.add_argument("--region", default="europe-central2")
    parser.add_argument("--repository", default="backend")
    parser.add_argument("--run-id", required=True)
    parser.add_argument("--trials", type=int, default=30, choices=range(1, 100), metavar="1..99")
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--first-trial", type=int, default=1, choices=range(1, 100), metavar="1..99")
    parser.add_argument("--verify-only", action="store_true")
    parser.add_argument("--probe-period", type=int, choices=(1, 5), default=5)
    parser.add_argument("--phase-timing-image",
                        help="Common image digest for the instrumented Sedno and Go startup experiment.")
    parser.add_argument("--tagged-trials", action="store_true",
                        help="Route trials after the first through a dedicated, zero-traffic revision tag.")
    args = parser.parse_args()
    if not re.fullmatch("[a-z][a-z0-9]{2,11}", args.run_id):
        parser.error("--run-id must have 3–12 lowercase alphanumeric characters and start with a letter")
    if args.phase_timing_image:
        prefix = (f"{args.region}-docker.pkg.dev/{args.project}/{args.repository}"
                  f"/sedno-perf-{args.run_id}@sha256:")
        if not re.fullmatch(re.escape(prefix) + r"[a-f0-9]{64}", args.phase_timing_image):
            parser.error("--phase-timing-image must be the digest of this benchmark's image package")
    if args.first_trial > args.trials:
        parser.error("--first-trial must be no greater than --trials")
    if args.verify_only and not args.output.exists():
        parser.error("--verify-only requires an existing results file")
    samples = {variant: {} for variant, _ in variants(args)}
    if args.output.exists():
        samples = {variant: {row["trial"]: row for row in data["samples"]}
                   for variant, data in json.loads(args.output.read_text()).items()}
        if any(row["service"] != service_name(args, variant)
               for variant, rows in samples.items() for row in rows.values()):
            parser.error("existing results belong to a different run or probe period")
    if args.verify_only:
        verify(args, samples)
        output(args, samples)
        return

    env = {
        "ASPNETCORE_ENVIRONMENT": "Production", "Google__CredentialProvider": "cloud-run",
        "Model__Provider": "disabled", "Billing__Enabled": "false", "Firestore__UseEmulator": "false",
        "Firestore__ProjectId": "demo-sedno-perf", "Firebase__ProjectId": "demo-sedno-perf",
        "Security__CredentialKey": example_key(), "Security__FingerprintKey": example_key(),
    }
    with tempfile.NamedTemporaryFile(mode="w", suffix=".json") as config, ThreadPoolExecutor(2) as pool:
        json.dump(env, config)
        config.flush()
        for trial in range(args.first_trial, args.trials + 1):
            token = gcloud("auth", "print-identity-token")
            tasks = {variant: pool.submit(measure, args, variant, boosted, trial, token, config.name)
                     for variant, boosted in variants(args) if trial not in samples[variant]}
            for variant, task in tasks.items():
                trial_number, data = task.result()
                samples[variant][trial_number] = {"trial": trial_number, **data}
                output(args, samples)
                print(f"{variant} trial {trial_number}: {data['cold']['ms']} ms", flush=True)
    verify(args, samples)
    output(args, samples)


if __name__ == "__main__":
    main()
