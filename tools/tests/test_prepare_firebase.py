import importlib.util
from pathlib import Path
import unittest
import re

SPEC = importlib.util.spec_from_file_location("prepare_firebase", Path(__file__).resolve().parents[1] / "prepare_firebase.py")
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class FirebaseDeploymentTests(unittest.TestCase):
    def config(self, **overrides):
        args = dict(project="sedno-example", region="europe-west1", site="sedno-example-api",
                    image="europe-west1-docker.pkg.dev/sedno-example/backend/api@sha256:" + "a" * 64,
                    sql_instance="sedno-example:europe-west1:sedno", billing_product="monthly",
                    push_email="sedno-push@sedno-example.iam.gserviceaccount.com")
        args.update(overrides)
        return MODULE.manifests(**args)

    def test_rejects_unsafe_or_inconsistent_deployments(self):
        for args in (dict(project="$(echo bad)"), dict(region="us-central1"),
                     dict(image="image:latest"), dict(sql_instance="other:europe-west1:db"),
                     dict(site="../public"), dict(billing_product=""), dict(push_email="user@example.com")):
            with self.subTest(args=args), self.assertRaises(ValueError):
                self.config(**args)

    def test_production_preserves_security_and_background_retention(self):
        service = self.config()["service.json"]["spec"]["template"]
        self.assertEqual("false", service["metadata"]["annotations"]["run.googleapis.com/cpu-throttling"])
        self.assertEqual("1", service["metadata"]["annotations"]["autoscaling.knative.dev/minScale"])
        container = service["spec"]["containers"][0]
        env = {item["name"]: item for item in container["env"]}
        for key, value in {"ASPNETCORE_ENVIRONMENT": "Production", "Model__Provider": "openai",
                           "PlayIntegrity__Provider": "google", "Billing__Enabled": "true",
                           "Billing__ReadOnlyKeyRing": "true", "Billing__PackageName": "xyz.sedno.app"}.items():
            self.assertEqual(value, env[key]["value"])
        for key in ("OpenAI__ApiKey", "ConnectionStrings__Postgres", "Security__CredentialKey", "Security__FingerprintKey"):
            self.assertNotIn("value", env[key])
            self.assertEqual("1", env[key]["valueFrom"]["secretKeyRef"]["key"])
        self.assertEqual("/health/ready", container["startupProbe"]["httpGet"]["path"])

    def test_explicit_first_stage_without_play_product_has_no_purchase_secrets(self):
        config = self.config(billing_product="", push_email="", without_billing=True)
        spec = config["service.json"]["spec"]["template"]["spec"]
        env = {item["name"]: item for item in spec["containers"][0]["env"]}
        self.assertEqual("false", env["Billing__Enabled"]["value"])
        self.assertNotIn("Billing__ProductId", env)
        self.assertEqual({"integrity", "firebase"}, {volume["name"] for volume in spec["volumes"]})
        with self.assertRaises(ValueError):
            self.config(without_billing=True)

    def test_cloud_run_identity_does_not_mount_google_private_keys(self):
        for no_billing in (False, True):
            config = self.config(google_credentials="cloud-run", without_billing=no_billing,
                                 billing_product="" if no_billing else "monthly",
                                 push_email="" if no_billing else "sedno-push@sedno-example.iam.gserviceaccount.com")
            spec = config["service.json"]["spec"]["template"]["spec"]
            env = {item["name"]: item for item in spec["containers"][0]["env"]}
            self.assertEqual("cloud-run", env["Google__CredentialProvider"]["value"])
            self.assertFalse(any(name.endswith("ServiceAccountJsonPath") for name in env))
            self.assertEqual(set() if no_billing else {"keyring"}, {item["name"] for item in spec["volumes"]})

    def test_migration_has_only_database_secret_and_no_retry(self):
        template = self.config()["migration.json"]["spec"]["template"]
        self.assertEqual("sedno-example:europe-west1:sedno", template["metadata"]["annotations"]["run.googleapis.com/cloudsql-instances"])
        spec = template["spec"]
        self.assertNotIn("metadata", spec["template"])
        self.assertEqual(1, spec["taskCount"])
        task = spec["template"]["spec"]
        self.assertEqual(0, task["maxRetries"])
        self.assertEqual(["--migrate"], task["containers"][0]["args"])
        self.assertEqual(2, len(task["containers"][0]["env"]))
        self.assertEqual("sedno-postgres-migration", task["containers"][0]["env"][1]["valueFrom"]["secretKeyRef"]["name"])

    def test_api_site_does_not_replace_existing_homepage_and_pins_revision(self):
        hosting = self.config()["firebase.json"]["hosting"]
        self.assertEqual("empty", hosting["public"])
        self.assertEqual(1, len(hosting["rewrites"]))
        pattern = re.compile(hosting["rewrites"][0]["regex"])
        for path in ("/v1/guest-sessions", "/v1/simplifications", "/health/ready", "/notifications/google-play", "/prywatnosc", "/usun-konto/"):
            self.assertIsNotNone(pattern.fullmatch(path), path)
        for path in ("/", "/index.html", "/prywatnosc-extra", "/other"):
            self.assertIsNone(pattern.fullmatch(path), path)
        self.assertTrue(all(rule["run"]["pinTag"] for rule in hosting["rewrites"]))
        self.assertEqual("no-store", hosting["headers"][0]["headers"][0]["value"])


if __name__ == "__main__":
    unittest.main()
