"""Prepare reviewable Cloud Run/Firebase manifests; never contacts Google or reads secrets."""
import argparse
import json
from pathlib import Path
import re
import shutil

ROOT = Path(__file__).resolve().parents[1]
# Firebase Hosting supports these European Cloud Run rewrite regions.
REGIONS = ("europe-central2", "europe-west1", "europe-west4")


def manifests(project, region, site, image, sql_instance, billing_product, push_email, *, without_billing=False, google_credentials="file"):
    if not re.fullmatch(r"[a-z][a-z0-9-]{4,28}[a-z0-9]", project):
        raise ValueError("Nieprawidłowy identyfikator projektu Google Cloud.")
    if region not in REGIONS:
        raise ValueError("Wybierz europe-central2, europe-west1 lub europe-west4 obsługiwany przez Firebase Hosting.")
    if not re.fullmatch(r"[a-z0-9][a-z0-9-]{2,61}[a-z0-9]", site):
        raise ValueError("Nieprawidłowy identyfikator witryny Firebase Hosting.")
    if not re.fullmatch(re.escape(project) + ":" + re.escape(region) + r":[a-z][a-z0-9-]*", sql_instance):
        raise ValueError("Cloud SQL musi należeć do tego projektu i regionu.")
    if not re.fullmatch(re.escape(region) + r"-docker\.pkg\.dev/" + re.escape(project) + r"/[^\s]+@sha256:[a-f0-9]{64}", image):
        raise ValueError("Podaj obraz Artifact Registry z niezmiennym digestem sha256.")
    if google_credentials not in ("file", "cloud-run"):
        raise ValueError("Nieobsługiwany dostawca poświadczeń Google.")
    if without_billing and (billing_product or push_email):
        raise ValueError("Tryb bez płatności nie przyjmuje produktu ani konta Pub/Sub.")
    if not without_billing and not re.fullmatch(r"[a-zA-Z0-9._-]+", billing_product):
        raise ValueError("Podaj identyfikator subskrypcji Google Play.")
    if not without_billing and not re.fullmatch(r"[a-zA-Z0-9._-]+@" + re.escape(project) + r"\.iam\.gserviceaccount\.com", push_email):
        raise ValueError("Podaj konto serwisowe Pub/Sub z tego projektu.")

    def secret_env(name, secret):
        # Pin versions: rotate by preparing/reviewing a new deployment.
        return {"name": name, "valueFrom": {"secretKeyRef": {"name": secret, "key": "1"}}}

    env = [{"name": key, "value": value} for key, value in {
        "ASPNETCORE_ENVIRONMENT": "Production",
        "Firebase__ProjectId": project,
        "Model__Provider": "openai",
        "PlayIntegrity__Provider": "google",
        "PlayIntegrity__PackageName": "xyz.sedno.app",
        "PlayIntegrity__ServiceAccountJsonPath": "/secrets/integrity/account.json",
        "Firebase__DeletionServiceAccountJsonPath": "/secrets/firebase/account.json",
        "Billing__Enabled": "true",
        "Billing__PackageName": "xyz.sedno.app",
        "Billing__ProductId": billing_product,
        "Billing__ServiceAccountJsonPath": "/secrets/billing/account.json",
        "Billing__DataProtectionKeyPath": "/secrets/keyring",
        "Billing__ReadOnlyKeyRing": "true",
        "Billing__NotificationAudience": f"https://{site}.web.app/notifications/google-play",
        "Billing__PushServiceAccountEmail": push_email,
    }.items()]
    if without_billing:
        env = [item for item in env if not item['name'].startswith('Billing__')]
        env.append({'name': 'Billing__Enabled', 'value': 'false'})
    if google_credentials == "cloud-run":
        env = [item for item in env if not item["name"].endswith("ServiceAccountJsonPath")]
        env.append({"name": "Google__CredentialProvider", "value": "cloud-run"})
    env += [secret_env(name, secret) for name, secret in {
        "ConnectionStrings__Postgres": "sedno-postgres",
        "Security__CredentialKey": "sedno-credential-key",
        "Security__FingerprintKey": "sedno-fingerprint-key",
        "OpenAI__ApiKey": "sedno-openai-key",
    }.items()]
    volumes = []
    mounts = []
    for name, secret, filename in (
        ("integrity", "sedno-integrity-account", "account.json"),
        ("firebase", "sedno-firebase-account", "account.json"),
        ("billing", "sedno-billing-account", "account.json"),
        ("keyring", "sedno-billing-keyring", "key.xml"),
    ):
        if google_credentials == "cloud-run" and name in ("integrity", "firebase", "billing"):
            continue
        if without_billing and name in ('billing', 'keyring'):
            continue
        volumes.append({"name": name, "secret": {"secretName": secret, "items": [{"key": "1", "path": filename}]}})
        mounts.append({"name": name, "mountPath": f"/secrets/{name}"})
    service = {
        "apiVersion": "serving.knative.dev/v1", "kind": "Service",
        "metadata": {"name": "sedno-api", "annotations": {"run.googleapis.com/ingress": "all"}},
        "spec": {"template": {
            "metadata": {"annotations": {
                "autoscaling.knative.dev/minScale": "1", "autoscaling.knative.dev/maxScale": "3",
                "run.googleapis.com/cpu-throttling": "false",
                "run.googleapis.com/cloudsql-instances": sql_instance,
            }},
            "spec": {"serviceAccountName": f"sedno-api@{project}.iam.gserviceaccount.com",
                     "containerConcurrency": 20, "timeoutSeconds": 30,
                     "containers": [{"image": image, "ports": [{"containerPort": 8080}], "env": env,
                                     "resources": {"limits": {"cpu": "1", "memory": "512Mi"}},
                                     "volumeMounts": mounts,
                                     "startupProbe": {"httpGet": {"path": "/health/ready", "port": 8080},
                                                      "periodSeconds": 5, "timeoutSeconds": 2, "failureThreshold": 24},
                                     "livenessProbe": {"httpGet": {"path": "/health/live", "port": 8080},
                                                       "periodSeconds": 30, "timeoutSeconds": 2}}],
                     "volumes": volumes}}}}
    migration = {
        "apiVersion": "run.googleapis.com/v1", "kind": "Job", "metadata": {"name": "sedno-migrate"},
        "spec": {"template": {"metadata": {"annotations": {"run.googleapis.com/cloudsql-instances": sql_instance}},
            "spec": {"taskCount": 1, "template": {
            "spec": {"serviceAccountName": f"sedno-migrate@{project}.iam.gserviceaccount.com",
                     "maxRetries": 0, "timeoutSeconds": "600",
                     "containers": [{"image": image, "args": ["--migrate"],
                                     "env": [{"name": "ASPNETCORE_ENVIRONMENT", "value": "Production"},
                                             secret_env("ConnectionStrings__Postgres", "sedno-postgres-migration")],
                                     "resources": {"limits": {"cpu": "1", "memory": "512Mi"}}}]}}}}}}
    hosting = {"hosting": {"site": site, "public": "empty", "ignore": ["**/.*"],
                           # A single pinned rule prevents concurrent updates of one Cloud Run service.
                           "rewrites": [{"regex": "^/(v1(/.*)?|health(/.*)?|notifications/google-play|prywatnosc/?|usun-konto/?)$",
                                         "run": {"serviceId": "sedno-api", "region": region, "pinTag": True}}],
                           "headers": [{"source": "**", "headers": [{"key": "Cache-Control", "value": "no-store"}]}]}}
    return {"service.json": service, "migration.json": migration, "firebase.json": hosting}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ("project", "site", "image", "sql-instance", "output"):
        parser.add_argument(f"--{name}", required=True)
    parser.add_argument("--billing-product", default="")
    parser.add_argument("--push-email", default="")
    parser.add_argument("--google-credentials", choices=("file", "cloud-run"), default="file")
    parser.add_argument("--without-billing", action="store_true", help="Jawny pierwszy etap bez zakupów Google Play.")
    parser.add_argument("--region", choices=REGIONS, default="europe-central2")
    args = parser.parse_args()
    try:
        result = manifests(args.project, args.region, args.site, args.image, args.sql_instance, args.billing_product, args.push_email, without_billing=args.without_billing, google_credentials=args.google_credentials)
    except ValueError as error:
        parser.error(str(error))
    output = Path(args.output)
    output.mkdir(parents=True, exist_ok=True)
    (output / "empty").mkdir(exist_ok=True)
    for name, content in result.items():
        (output / name).write_text(json.dumps(content, indent=2) + "\n", encoding="utf-8")
    shutil.copyfile(ROOT / "backend/deploy/firebase/deploy.sh", output / "deploy.sh")
    print(f"Przygotowano pliki w {output}. Nie wdrożono zasobów.")


if __name__ == "__main__":
    main()
