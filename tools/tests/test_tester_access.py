import hashlib
import io
import json
from pathlib import Path
import sys
import unittest
from datetime import datetime, timedelta, timezone
from unittest.mock import patch
from urllib.error import HTTPError
from urllib.parse import parse_qs, urlparse

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from tester_access import AdminError, FIELD, GoogleApi, TesterAdmin, interactive, parse_expiry, show_status

NOW = datetime(2026, 10, 22, 12, tzinfo=timezone.utc)
EXPIRY = datetime(2026, 11, 15, 19, tzinfo=timezone.utc)
ACCOUNT = "12345678-1234-1234-1234-123456789abc"
NAME = "projects/sednoapp-79241/databases/(default)/documents/verified_accounts/" + ACCOUNT.replace("-", "")


def document(expiry=None):
    fields = {"FirebaseUid": {"stringValue": "firebase-user"}, "Deleting": {"booleanValue": False}}
    if expiry is not None:
        fields[FIELD] = {"timestampValue": expiry.isoformat()}
    return {"name": NAME, "updateTime": "2026-10-22T12:00:00.123456Z", "fields": fields}


class FakeApi:
    def __init__(self):
        self.calls = []
        self.user = {"localId": "firebase-user"}
        self.doc = document()
        self.pointer = {"fields": {"AccountId": {"stringValue": ACCOUNT}}}

    def request(self, method, url, body=None, **kwargs):
        self.calls.append((method, url, body))
        if "accounts:lookup" in url:
            return {"users": [self.user]}
        if "/firebase_uids/" in url:
            return self.pointer
        if method == "PATCH":
            self.doc["fields"].pop(FIELD, None)
            self.doc["fields"].update(body["fields"])
        return self.doc


class TesterAccessTests(unittest.TestCase):
    def test_expiry_uses_warsaw_and_rejects_past_and_dst_ambiguity(self):
        self.assertEqual(EXPIRY, parse_expiry("2026-11-15 20:00", NOW))
        for value in ["2026-10-22 14:00", "2026-02-30 12:00", "2026-10-25 02:30", "2027-03-28 02:30", "15.11.2026"]:
            with self.subTest(value=value), self.assertRaises(AdminError):
                parse_expiry(value, NOW)

    def test_email_lookup_uses_uid_hash_and_existing_account(self):
        api = FakeApi()
        result = TesterAdmin(api, "sednoapp-79241").lookup("tester@example.pl")
        self.assertEqual(NAME, result["name"])
        self.assertEqual({"email": ["tester@example.pl"]}, api.calls[0][2])
        self.assertTrue(api.calls[1][1].endswith(hashlib.sha256(b"firebase-user").hexdigest().upper()))
        self.assertEqual(3, len(api.calls))

    def test_date_only_expires_at_next_warsaw_midnight_including_dst_days(self):
        for value, expected in (
            ("2026-11-15", datetime(2026, 11, 15, 23, tzinfo=timezone.utc)),
            ("2026-10-22", datetime(2026, 10, 22, 22, tzinfo=timezone.utc)),
            ("2026-10-25", datetime(2026, 10, 25, 23, tzinfo=timezone.utc)),
            ("2027-03-28", datetime(2027, 3, 28, 22, tzinfo=timezone.utc)),
            ("2026-12-31", datetime(2026, 12, 31, 23, tzinfo=timezone.utc)),
        ):
            with self.subTest(value=value):
                self.assertEqual(expected, parse_expiry(value, NOW))
                self.assertEqual(expected, parse_expiry(value, expected - timedelta(seconds=1)))
                with self.assertRaises(AdminError):
                    parse_expiry(value, expected)
        for value in ("2026-10-21", "2026-02-30", "9999-12-31"):
            with self.subTest(value=value), self.assertRaises(AdminError):
                parse_expiry(value, NOW)

    def test_missing_disabled_deleting_or_mismatched_accounts_cannot_be_edited(self):
        for case in ("disabled", "missing", "deleting", "uid"):
            api = FakeApi()
            if case == "disabled":
                api.user["disabled"] = True
            elif case == "missing":
                api.pointer = None
            elif case == "deleting":
                api.doc["fields"]["Deleting"] = {"booleanValue": True}
            else:
                api.doc["fields"]["FirebaseUid"] = {"stringValue": "other"}
            with self.subTest(case=case), self.assertRaises(AdminError):
                TesterAdmin(api, "sednoapp-79241").lookup("tester@example.pl")
            self.assertFalse(any(c[0] == "PATCH" for c in api.calls))

    def test_grant_and_removal_patch_only_tester_field_with_version_precondition(self):
        for expiry in (EXPIRY, None):
            api = FakeApi()
            admin = TesterAdmin(api, "sednoapp-79241")
            admin.update(api.doc, expiry)
            method, url, body = api.calls[0]
            self.assertEqual("PATCH", method)
            query = parse_qs(urlparse(url).query)
            self.assertEqual([FIELD], query["updateMask.fieldPaths"])
            self.assertEqual([api.doc["updateTime"]], query["currentDocument.updateTime"])
            self.assertEqual({} if expiry is None else {FIELD: {"timestampValue": "2026-11-15T19:00:00Z"}}, body["fields"])
            self.assertEqual("firebase-user", api.doc["fields"]["FirebaseUid"]["stringValue"])

    def test_interactive_grant_remove_and_cancel(self):
        for answers, changed in [
            (["tester@example.pl", "1", "2026-11-15 20:00", "TAK"], True),
            (["tester@example.pl", "1", "2026-11-15", "TAK"], True),
            (["tester@example.pl", "2", "TAK"], True),
            (["tester@example.pl", "2", "nie"], False),
            (["tester@example.pl", ""], False),
            ([""], False),
        ]:
            api = FakeApi()
            responses = iter(answers)
            output = []
            interactive(TesterAdmin(api, "sednoapp-79241"), read=lambda _: next(responses), output=output.append, clock=lambda: NOW)
            self.assertEqual(changed, any(c[0] == "PATCH" for c in api.calls))
            if changed and answers[1] == "1" and answers[2] == "2026-11-15":
                self.assertEqual("2026-11-15T23:00:00Z", api.doc["fields"][FIELD]["timestampValue"])
                self.assertTrue(any("2026-11-16 00:00 CET" in line for line in output))
            if answers[0]:
                self.assertTrue(any("Status:" in line for line in output))

    def test_exact_expiry_is_expired_and_bad_type_fails(self):
        output = []
        show_status(document(NOW), NOW, output.append)
        self.assertIn("wygasły", output[0])
        doc = document()
        doc["fields"][FIELD] = {"stringValue": "2026-11-15"}
        with self.assertRaises(AdminError):
            show_status(doc, NOW)

    def test_http_conflict_is_not_retried_and_never_exposes_token_or_body(self):
        secret = "private-test-token"
        error = HTTPError("https://firestore.googleapis.com/", 412, "error", {}, io.BytesIO(b"private server response"))
        with patch("tester_access.urlopen", side_effect=error) as request:
            with self.assertRaises(AdminError) as captured:
                GoogleApi(secret, "sednoapp-79241").request("PATCH", "https://firestore.googleapis.com/", {})
        self.assertEqual(1, request.call_count)
        self.assertNotIn(secret, str(captured.exception))
        self.assertNotIn("private server", str(captured.exception))

    def test_google_requests_use_selected_project_for_api_quota(self):
        for project in ("sednoapp-79241", "another-project"):
            for method, url, body in (
                ("POST", "https://identitytoolkit.googleapis.com/", {"email": ["tester@example.pl"]}),
                ("GET", "https://firestore.googleapis.com/", None),
                ("PATCH", "https://firestore.googleapis.com/", {"fields": {}}),
            ):
                with self.subTest(project=project, method=method):
                    with patch("tester_access.urlopen") as request:
                        request.return_value.__enter__.return_value = io.BytesIO(b"{}")
                        GoogleApi("test-token", project).request(method, url, body)
                    headers = dict(request.call_args.args[0].header_items())
                    self.assertEqual(project, headers["X-goog-user-project"])


if __name__ == "__main__":
    unittest.main()
