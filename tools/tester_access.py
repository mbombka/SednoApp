#!/usr/bin/env python3
"""Interactive tester administration. Uses existing gcloud credentials and HTTPS APIs."""
import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
import re
import subprocess
import sys
from urllib.error import HTTPError
from urllib.parse import quote, urlencode
from urllib.request import Request, urlopen
from zoneinfo import ZoneInfo

FIELD = "TesterAccessExpiresAt"
UTC = timezone.utc
WARSAW = ZoneInfo("Europe/Warsaw")


class AdminError(Exception):
    pass


def parse_expiry(value, now):
    """Accept Warsaw wall time, rejecting nonexistent/ambiguous DST times."""
    try:
        wall = datetime.strptime(value, "%Y-%m-%d %H:%M")
    except ValueError:
        raise AdminError("Podaj datę w formacie RRRR-MM-DD GG:MM.") from None
    candidates = {
        wall.replace(tzinfo=WARSAW, fold=fold).astimezone(UTC)
        for fold in (0, 1)
        if wall.replace(tzinfo=WARSAW, fold=fold).astimezone(UTC).astimezone(WARSAW).replace(tzinfo=None) == wall
    }
    if len(candidates) != 1:
        raise AdminError("Ta godzina nie istnieje lub jest niejednoznaczna po zmianie czasu. Wybierz inną godzinę.")
    expiry = candidates.pop()
    if expiry <= now:
        raise AdminError("Data wygaśnięcia musi być w przyszłości.")
    return expiry


def timestamp(value):
    return value.astimezone(UTC).isoformat().replace("+00:00", "Z")


def gcloud_token():
    try:
        result = subprocess.run(
            ["gcloud", "auth", "print-access-token"], capture_output=True, text=True, timeout=30,
        )
    except (OSError, subprocess.TimeoutExpired):
        raise AdminError("Nie można uruchomić gcloud. Zainstaluj Google Cloud CLI i skonfiguruj konto administratora.") from None
    if result.returncode or not result.stdout.strip():
        raise AdminError("Nie można uzyskać dostępu przez gcloud. Sprawdź skonfigurowane konto i jego uprawnienia.")
    return result.stdout.strip()


class GoogleApi:
    def __init__(self, token):
        self.token = token

    def request(self, method, url, body=None, *, missing_ok=False):
        payload = None if body is None else json.dumps(body).encode("utf-8")
        request = Request(url, data=payload, method=method, headers={
            "Authorization": "Bearer " + self.token, "Content-Type": "application/json",
        })
        try:
            with urlopen(request, timeout=30) as response:
                return json.load(response)
        except HTTPError as error:
            if error.code == 404 and missing_ok:
                return None
            if error.code in (409, 412):
                raise AdminError("Dane konta zmieniły się w trakcie operacji. Uruchom skrypt ponownie i sprawdź status.") from None
            # Do not print API bodies, requests or credentials.
            raise AdminError(f"Google odrzuciło operację (HTTP {error.code}). Sprawdź uprawnienia i spróbuj ponownie.") from None
        except (OSError, ValueError):
            raise AdminError("Nie udało się odczytać odpowiedzi Google. Sprawdź połączenie i ponownie sprawdź status konta.") from None


class TesterAdmin:
    def __init__(self, api, project):
        self.api = api
        self.project = project
        self.documents = f"https://firestore.googleapis.com/v1/projects/{project}/databases/(default)/documents"

    def lookup(self, email):
        result = self.api.request("POST", f"https://identitytoolkit.googleapis.com/v1/projects/{self.project}/accounts:lookup", {"email": [email]})
        users = result.get("users", [])
        if len(users) != 1:
            raise AdminError("Nie znaleziono jednoznacznego konta z tym adresem w Firebase Authentication.")
        user = users[0]
        if user.get("disabled"):
            raise AdminError("Konto Firebase jest wyłączone.")
        uid = user["localId"]
        digest = hashlib.sha256(uid.encode()).hexdigest().upper()
        pointer = self.api.request("GET", self.documents + "/firebase_uids/" + digest, missing_ok=True)
        if pointer is None:
            raise AdminError("Brak konta Sedno. Tester musi najpierw zalogować się w aplikacji.")
        account_id = pointer["fields"]["AccountId"]["stringValue"]
        compact_id = account_id.replace("-", "")
        if not re.fullmatch(r"[a-fA-F0-9]{32}", compact_id):
            raise AdminError("Nieprawidłowe powiązanie konta Sedno.")
        document = self.api.request("GET", self.documents + "/verified_accounts/" + compact_id.lower(), missing_ok=True)
        if document is None:
            raise AdminError("Nie znaleziono dokumentu konta Sedno.")
        fields = document["fields"]
        if fields.get("Deleting", {}).get("booleanValue"):
            raise AdminError("Konto jest w trakcie usuwania.")
        if fields.get("FirebaseUid", {}).get("stringValue") != uid:
            raise AdminError("Powiązanie konta Sedno nie zgadza się z Firebase Authentication.")
        return document

    def update(self, document, expiry):
        # A field mask plus updateTime is a compare-and-swap: no lost concurrent
        # grants/linking/deletion, no accidental creation, no changes to other fields.
        query = urlencode({"updateMask.fieldPaths": FIELD, "currentDocument.updateTime": document["updateTime"]})
        fields = {} if expiry is None else {FIELD: {"timestampValue": timestamp(expiry)}}
        account_id = document["name"].rsplit("/", 1)[1]
        return self.api.request("PATCH", self.documents + "/verified_accounts/" + quote(account_id, safe="") + "?" + query, {"fields": fields})


def show_status(document, now, output=print):
    raw = document.get("fields", {}).get(FIELD, {})
    value = raw.get("timestampValue")
    if value is None:
        if raw and "nullValue" not in raw:
            raise AdminError("Pole dostępu testerskiego ma nieprawidłowy typ. Oczekiwano Timestamp.")
        output("Status: brak dostępu testerskiego.")
        return
    expiry = datetime.fromisoformat(value.replace("Z", "+00:00"))
    state = "aktywny" if expiry > now else "wygasły"
    output(f"Status: dostęp testerski {state}.")
    output("Ważny do: " + expiry.astimezone(WARSAW).strftime("%Y-%m-%d %H:%M %Z") + " (" + timestamp(expiry) + ").")


def interactive(admin, *, read=input, output=print, clock=lambda: datetime.now(UTC)):
    email = read("E-mail konta testera (puste = zakończ): ").strip()
    if not email:
        return
    if len(email) > 255 or not re.fullmatch(r"[^\s@]+@[^\s@]+\.[^\s@]+", email):
        raise AdminError("Podaj poprawny adres e-mail.")
    document = admin.lookup(email)
    output("Konto Sedno: " + document["name"].rsplit("/", 1)[1])
    show_status(document, clock(), output)
    output("1 — nadaj lub zmień datę dostępu testerskiego")
    output("2 — usuń atrybut testera")
    output("Enter — zakończ bez zmian")
    action = read("Wybór: ").strip()
    if not action:
        return
    if action not in ("1", "2"):
        raise AdminError("Nieznana opcja. Nie zapisano zmian.")
    expiry = None
    if action == "1":
        expiry = parse_expiry(read("Ważny do (RRRR-MM-DD GG:MM, Europe/Warsaw): ").strip(), clock())
        output("Nowa data: " + timestamp(expiry) + " (UTC). Limit: 400 operacji dziennie łącznie.")
    else:
        output("Zostanie usunięte wyłącznie uprawnienie testerskie. Subskrypcja i liczniki pozostaną bez zmian.")
    if read(f"Zapisać zmianę dla {email}? Wpisz TAK: ").strip() != "TAK":
        output("Anulowano. Nie zapisano zmian.")
        return
    if expiry is not None and expiry <= clock():
        raise AdminError("Wybrana data już minęła. Nie zapisano zmian.")
    updated = admin.update(document, expiry)
    output("Zapisano zmianę.")
    show_status(updated, clock(), output)


def main():
    parser = argparse.ArgumentParser(description="Zarządzanie czasowym dostępem testerskim Sedno.", add_help=False)
    parser._optionals.title = "Opcje"
    parser.add_argument("-h", "--help", action="help", help="Pokaż tę pomoc i zakończ.")
    parser.add_argument("--project", metavar="PROJEKT", default="sednoapp-79241", help="Projekt Firebase (domyślnie sednoapp-79241).")
    args = parser.parse_args()
    if not re.fullmatch(r"[a-z][a-z0-9-]{4,28}[a-z0-9]", args.project):
        parser.error("Nieprawidłowy identyfikator projektu.")
    if os.environ.get("FIRESTORE_EMULATOR_HOST"):
        parser.error("To narzędzie administruje prawdziwą bazą. Usuń FIRESTORE_EMULATOR_HOST.")
    print(f"Projekt: {args.project}, baza: (default).")
    try:
        interactive(TesterAdmin(GoogleApi(gcloud_token()), args.project))
    except (EOFError, KeyboardInterrupt):
        print("\nPrzerwano. Jeśli przerwano zapis, uruchom skrypt ponownie, aby sprawdzić status.")
        return 130
    except (AdminError, KeyError, TypeError, ValueError) as error:
        print(str(error) if isinstance(error, AdminError) else "Nieprawidłowe dane konta w odpowiedzi Google.", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
