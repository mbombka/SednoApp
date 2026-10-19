#!/usr/bin/env bash
# Run from the generated directory, after reviewing all three manifests.
set -euo pipefail
for tool in gcloud firebase curl python3; do command -v "$tool" >/dev/null; done
read -r SEDNO_PROJECT SEDNO_REGION SEDNO_SITE < <(python3 - <<'PY'
import json
from pathlib import Path
service = json.loads(Path('service.json').read_text())
hosting = json.loads(Path('firebase.json').read_text())
env = service['spec']['template']['spec']['containers'][0]['env']
project = next(item['value'] for item in env if item['name'] == 'Firebase__ProjectId')
print(project, hosting['hosting']['rewrites'][0]['run']['region'], hosting['hosting']['site'])
PY
)
# Run schema changes before switching traffic. A failed job stops deployment.
gcloud run jobs replace migration.json --project "$SEDNO_PROJECT" --region "$SEDNO_REGION"
gcloud run jobs execute sedno-migrate --wait --project "$SEDNO_PROJECT" --region "$SEDNO_REGION"
gcloud run services replace service.json --project "$SEDNO_PROJECT" --region "$SEDNO_REGION"
# Sedno validates its own opaque bearers, Firebase tokens and RTDN identity.
gcloud run services add-iam-policy-binding sedno-api --member=allUsers --role=roles/run.invoker --project "$SEDNO_PROJECT" --region "$SEDNO_REGION" >/dev/null
# The readiness probe checks PostgreSQL before Cloud Run marks the revision ready.
# Check that control-plane result before publishing; verify HTTPS via the client URL below.
gcloud run services describe sedno-api --format='json(status.conditions)' --project "$SEDNO_PROJECT" --region "$SEDNO_REGION" | python3 -c 'import json,sys; conditions=json.load(sys.stdin)["status"]["conditions"]; ready=any(c.get("type")=="Ready" and c.get("status")=="True" for c in conditions); sys.exit(0 if ready else "Cloud Run nie osiągnął gotowości.")'
firebase deploy --only hosting --project "$SEDNO_PROJECT" --config firebase.json
curl --fail --silent --show-error --retry 3 "https://${SEDNO_SITE}.web.app/health/ready"
