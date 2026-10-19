#!/usr/bin/env bash
# Run from the generated directory, after preparing Firestore and migrating data.
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
# Indexes/rules precede traffic. Wait for composite indexes to become READY before
# running this script; Firebase index submission itself does not wait for builds.
firebase deploy --only firestore:rules,firestore:indexes --project "$SEDNO_PROJECT" --config firebase.json
gcloud run jobs replace cleanup.json --project "$SEDNO_PROJECT" --region "$SEDNO_REGION"
gcloud run jobs execute sedno-cleanup --wait --project "$SEDNO_PROJECT" --region "$SEDNO_REGION"
# Hourly cleanup continues even when API instances scale to zero.
SEDNO_SCHEDULE_ARGS=(--project "$SEDNO_PROJECT" --location "$SEDNO_REGION"
  --schedule '0 * * * *' --time-zone UTC
  --uri "https://run.googleapis.com/v2/projects/${SEDNO_PROJECT}/locations/${SEDNO_REGION}/jobs/sedno-cleanup:run"
  --http-method POST --oauth-service-account-email "sedno-scheduler@${SEDNO_PROJECT}.iam.gserviceaccount.com"
  --oauth-token-scope https://www.googleapis.com/auth/cloud-platform --message-body '{}')
if gcloud scheduler jobs describe sedno-cleanup --project "$SEDNO_PROJECT" --location "$SEDNO_REGION" >/dev/null 2>&1; then
  gcloud scheduler jobs update http sedno-cleanup "${SEDNO_SCHEDULE_ARGS[@]}" --update-headers Content-Type=application/json
else
  gcloud scheduler jobs create http sedno-cleanup "${SEDNO_SCHEDULE_ARGS[@]}" --headers Content-Type=application/json
fi
gcloud run services replace service.json --project "$SEDNO_PROJECT" --region "$SEDNO_REGION"
gcloud run services add-iam-policy-binding sedno-api --member=allUsers --role=roles/run.invoker --project "$SEDNO_PROJECT" --region "$SEDNO_REGION" >/dev/null
gcloud run services describe sedno-api --format='json(status.conditions)' --project "$SEDNO_PROJECT" --region "$SEDNO_REGION" | python3 -c 'import json,sys; conditions=json.load(sys.stdin)["status"]["conditions"]; ready=any(c.get("type")=="Ready" and c.get("status")=="True" for c in conditions); sys.exit(0 if ready else "Cloud Run nie osiągnął gotowości.")'
firebase deploy --only hosting --project "$SEDNO_PROJECT" --config firebase.json
curl --fail --silent --show-error --retry 3 "https://${SEDNO_SITE}.web.app/health/ready"
