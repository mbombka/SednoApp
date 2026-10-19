# Serwer w Firebase i Google Cloud

API: **https://sednoapp-79241-api.web.app**. Wdrożone 19.10.2026, bez płatności
Google Play. Strona [sedno.xyz](https://sedno.xyz) jest utrzymywana oddzielnie.
Uruchomienie lokalne: [backend](../../README.md); aplikacja: [Android](../../../mobile/README.md).

## Gdzie działa serwer

| Element | Konfiguracja |
| --- | --- |
| Projekt Firebase / Google Cloud | `sednoapp-79241`, numer `1003558402460` |
| Region serwera i bazy | `europe-central2` — Warszawa |
| Firebase Hosting API | `sednoapp-79241-api`; przekazuje HTTPS do Cloud Run |
| Cloud Run | `sedno-api`, 1 CPU, 512 MiB, 1–3 instancje, współbieżność 20 |
| Cloud SQL | `sedno-postgres`, baza `sedno`, PostgreSQL 17, db-f1-micro, 10 GiB |
| Migracje bazy | Zadanie `sedno-migrate`, osobne konto bazy |
| Obrazy serwera | Artifact Registry, repozytorium `backend` |

Minimum jedna instancja i stale dostępny CPU podtrzymują godzinowe usuwanie
starych metadanych. **Serwer i baza kosztują także wtedy, gdy nikt ich nie używa.**
Pełny rachunek chmurowy i wydajność pod obciążeniem pozostają do zmierzenia.

Kopie bazy: codziennie o 02:00 UTC, 7 kopii, odtwarzanie do punktu w czasie
z logów z 1 dnia. Logi Cloud Logging `_Default`: 30 dni.
Próba odtworzenia bazy pozostaje do wykonania.

## Kolejne wdrożenie

Potrzebujesz uprawnionego konta, `gcloud`, Firebase CLI i Pythona 3.
Polecenia uruchom z katalogu głównego projektu. Zastąp `NOWY_TAG` nazwą wydania,
a `DIGEST_OBRAZU` skrótem obrazu zwróconym po budowie.

```sh
gcloud auth login
firebase login
gcloud builds submit --project sednoapp-79241 --billing-project sednoapp-79241 \
  --region europe-central2 \
  --service-account projects/sednoapp-79241/serviceAccounts/sedno-build@sednoapp-79241.iam.gserviceaccount.com \
  --config backend/deploy/firebase/cloudbuild.yaml \
  --substitutions _IMAGE=europe-central2-docker.pkg.dev/sednoapp-79241/backend/api:NOWY_TAG .
python3 tools/prepare_firebase.py \
  --project sednoapp-79241 --region europe-central2 --site sednoapp-79241-api \
  --image europe-central2-docker.pkg.dev/sednoapp-79241/backend/api@sha256:DIGEST_OBRAZU \
  --sql-instance sednoapp-79241:europe-central2:sedno-postgres \
  --google-credentials cloud-run --without-billing \
  --output backend/deploy/generated
cd backend/deploy/generated
bash deploy.sh
```

Generator przygotowuje pliki lokalnie. Przed `deploy.sh` przejrzyj je i sprawdź
zgodność migracji z działającą wersją. Skrypt wykonuje migracje, wdraża serwer,
publikuje przekierowanie Hosting i sprawdza `/health/ready` przez publiczne HTTPS.
Lokalnie pobrane narzędzia mogą znajdować się w `backend/.local-tools/`.

Zachowaj poprzedni obraz i wydanie Hosting. Przywrócenie wydania Hosting przywraca
przypiętą wersję serwera; bezpośredni adres Cloud Run wymaga osobnego przełączenia
ruchu. Wycofanie kodu nie cofa migracji bazy. Nie usuwaj bazy przy wycofaniu aplikacji.

## Sekrety i uprawnienia

Hasła i klucze są w Secret Manager: `sedno-postgres`, `sedno-postgres-migration`,
`sedno-credential-key`, `sedno-fingerprint-key`, `sedno-openai-key`.
Manifesty odwołują się do wersji sekretów; nie zawierają ich wartości.
Konto `sedno-api` ma dostęp do swoich sekretów i danych bazy; `sedno-migrate`
ma odrębne połączenie i uprawnienia zmiany schematu.

`Google__CredentialProvider=cloud-run` korzysta z konta usługi bez plików kluczy
prywatnych. Konto API potrzebuje Cloud SQL Client, Service Usage Consumer
oraz `firebaseauth.users.get/delete`. Integracje Google używają osobnych zakresów OAuth.
Nie inicjalizuj ponownie istniejącej bazy ani nie wymieniaj samoczynnie kluczy
bezpieczeństwa — ich utrata narusza istniejące sesje i limity.

## Przed udostępnieniem aplikacji

Pozostają testy prawdziwego Play Integrity, certyfikatów Firebase i pełnego
przepływu na telefonie. Przed większym ruchem sprawdź ochronę przed nadmiarem
żądań: obecny limit IP widzi adres proxy i może grupować użytkowników.
Dzienne limity kont są wspólne i przechowywane w PostgreSQL.

Płatności włącz dopiero po przygotowaniu produktu Google Play, uprawnień,
powiadomień i trwałych kluczy szyfrujących zakupy. Generator wymaga wtedy
`--billing-product` i `--push-email` zamiast `--without-billing`.
[Ustawienia płatności](../../README.md#subskrypcje-google-play).

Identyfikatory wdrożenia i historyczne wyniki testów:
[raport z 19.10.2026](../../../docs/archiwum/task-14-deployment.pl.md).
