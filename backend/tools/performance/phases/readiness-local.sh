#!/usr/bin/env bash
# Measure Sedno's first Firestore readiness read against a dedicated emulator.
set -euo pipefail

image=${1:?Pass the local startup-phases Docker image}
trials=${2:-30}
[[ "$trials" =~ ^[1-9][0-9]*$ ]]

network="sedno-phases-local-$$"
emulator="$network-db"
api="$network-api"
go_server="$network-go"
work=$(mktemp -d)
cleanup() {
  docker rm -f "$api" "$emulator" "$go_server" >/dev/null 2>&1 || true
  docker network rm "$network" >/dev/null 2>&1 || true
  rm -rf -- "$work"
}
trap cleanup EXIT

for key in CredentialKey FingerprintKey; do
  printf 'Security__%s=%s\n' "$key" "$(openssl rand -base64 32)" >> "$work/settings"
done

docker network create "$network" >/dev/null
docker run --rm -d --name "$emulator" --network "$network" \
  gcr.io/google.com/cloudsdktool/google-cloud-cli:emulators \
  gcloud emulators firestore start --host-port=0.0.0.0:8080 --quiet >/dev/null

emulator_ready() {
  docker logs "$emulator" 2>&1 | rg 'Dev App Server is now running' >/dev/null
}
wait_http() {
  local url=$1
  for _ in {1..70}; do
    if curl -fsS --max-time 5 "$url" 2>/dev/null; then
      return
    fi
    sleep .08
  done
  return 1
}

for _ in {1..60}; do
  if emulator_ready; then break; fi
  sleep .25
done
emulator_ready

docker run --rm -d --name "$go_server" -p 127.0.0.1::8080 "$image" go >/dev/null
go_host=$(docker port "$go_server" 8080/tcp)
test "$(wait_http "http://$go_host/health/live")" = OK
docker logs "$go_server" | rg 'sedno-phase (entrypoint|http_ready|probe_arrived)' > "$work/go"
test "$(wc -l < "$work/go")" = 3
docker stop "$go_server" >/dev/null

for ((trial=1; trial<=trials; trial++)); do
  docker run --rm -d --name "$api" --network "$network" --cpus=1 -p 127.0.0.1::8080 \
    --env-file "$work/settings" -e ASPNETCORE_ENVIRONMENT=Development \
    -e "FIRESTORE_EMULATOR_HOST=$emulator:8080" -e Firestore__UseEmulator=true \
    -e Firestore__ProjectId=demo-sedno-phases -e Model__Provider=mock "$image" sedno >/dev/null
  api_host=$(docker port "$api" 8080/tcp)
  wait_http "http://$api_host/health/ready" >/dev/null
  docker logs "$api" | rg '^sedno-phase firestore_read_us [0-9]+$' | awk 'NR == 1 {print $3}' >> "$work/samples"
  docker stop "$api" >/dev/null
done

python3 - "$work/samples" "$trials" <<'PY'
import json
import math
from pathlib import Path
import statistics
import sys

samples = [round(int(value) / 1000, 3) for value in Path(sys.argv[1]).read_text().splitlines()]
assert len(samples) == int(sys.argv[2])
print(json.dumps({
    "environment": "dedicated local Firestore emulator",
    "samples_ms": samples,
    "median_ms": round(statistics.median(samples), 3),
    "p95_ms": sorted(samples)[math.ceil(.95 * len(samples)) - 1],
}, indent=2))
PY
