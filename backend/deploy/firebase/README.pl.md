# Backend Sedno w Firebase Hosting i Cloud Run

Stan z 19.10.2026: API działa pod **https://sednoapp-79241-api.web.app**.
`GET /health/ready` zwraca 200 po sprawdzeniu połączenia z PostgreSQL.
Jest to pierwszy etap bez płatności Google Play. Pełny test na telefonie wymaga
jeszcze konfiguracji Play Integrity i aplikacji w kanale testowym Google Play.

Projekt: `sednoapp-79241` (numer `1003558402460`), pakiet Android: `xyz.sedno.app`,
nazwa aplikacji: Sedno. Serwer i baza są w `europe-central2` (Warszawa).
Domena strony `sedno.xyz` i istniejąca witryna Firebase pozostają oddzielne od API.
Nie zmieniano DNS. W aplikacji używaj adresu API powyżej jako `BACKEND_BASE_URL`.

## Działające zasoby

| Zasób | Konfiguracja |
| --- | --- |
| Firebase Hosting `sednoapp-79241-api` | Osobna witryna API, HTTPS, jedna reguła RE2 przypięta do rewizji Cloud Run |
| Cloud Run `sedno-api` | ASP.NET Core / .NET 10 LTS, Production, 1 CPU, 512 MiB, 1–3 instancje, współbieżność 20 |
| Cloud SQL `sedno-postgres` | PostgreSQL 17, db-f1-micro, SSD 10 GiB, jedna strefa, ochrona przed usunięciem |
| Baza `sedno` | Osobne konta `sedno_api` i `sedno_migrate`; API bez DDL, tworzenia baz/ról i praw superusera |
| Cloud Run Job `sedno-migrate` | Jawne migracje przed przełączeniem ruchu; brak automatycznych ponowień |
| Artifact Registry `backend` | Obrazy przypinane digestem, region Warszawa |
| Secret Manager | Hasła bazy, klucze HMAC i klucz OpenAI; replikacja w Warszawie, odwołania do wersji 1 |

Cloud SQL ma szyfrowane połączenia, bez wpisów w autoryzowanych sieciach publicznych.
Cloud Run łączy się przez zarządzany socket `/cloudsql/...` i Cloud SQL Client.
Pula Npgsql ma maksymalnie 5 połączeń na instancję API. Skonfigurowano codzienne
kopie o 02:00 UTC, zachowanie 7 kopii i PITR z logami z 1 dnia. Zweryfikowano
30-dniową retencję logów w bucketcie Cloud Logging `_Default`.
Nie wykonano próby odtwarzania kopii.

Minimum jedna instancja i CPU bez throttlingu zapewniają pracę godzinowego
sprzątania metadanych. Baza i serwer naliczają stałe opłaty także bez ruchu.
Mały tier bazy wymaga oceny obciążenia przed udostępnieniem większej liczbie osób.

## Tożsamość i sekrety

`Google:CredentialProvider=cloud-run` korzysta z przypisanego konta
`sedno-api@sednoapp-79241.iam.gserviceaccount.com`. Backend pobiera krótkotrwałe
tokeny z metadanych, wskazując zakres OAuth osobno dla Play Integrity, Firebase
i Google Play Billing. Nie tworzy plików z kluczami prywatnymi Google. Ten wariant
jest odrzucany poza środowiskiem Production Cloud Run.

Klient metadanych wyłącza proxy, przekierowania i loggery HTTP. Waliduje nagłówek,
rozmiar i strukturę odpowiedzi; tokeny przechowuje wyłącznie w pamięci i odświeża
przed wygaśnięciem. Domyślny token bez zakresu nie wystarcza do Play Integrity —
potwierdzono to testem rzeczywistym i dodano regresję.

Konto API ma Cloud SQL Client, Service Usage Consumer oraz własną rolę
`sednoFirebaseUsers` z `firebaseauth.users.get/delete`. Ma Secret Accessor
oddzielnie na `sedno-postgres`, `sedno-credential-key`, `sedno-fingerprint-key`
i `sedno-openai-key`. Konto `sedno-migrate` ma Cloud SQL Client i dostęp wyłącznie
do sekretu `sedno-postgres-migration`. Konto budowy `sedno-build` ma zapis obrazów
w tym repozytorium, odczyt paczek źródłowych i zapis logów.

Właściciel zatwierdził 19.10.2026 inicjalizację nowej bazy i skopiowanie klucza
OpenAI z lokalnego magazynu `sedno-backend-dev` do `sedno-openai-key`.
Klucza nie wypisywano ani nie umieszczano w aplikacji. HMAC dla nowej bazy
wygenerowano oddzielnie. Nie uruchamiaj ponownie inicjalizacji ani nie zmieniaj
samoczynnie kluczy HMAC: ich migracja musi zachować sesje i wspólne limity.

## Kolejne wdrożenia

Z katalogu głównego repozytorium, po zalogowaniu lokalnymi narzędziami:

```sh
export PATH="$PWD/backend/.local-tools/google-cloud-sdk/bin:$PWD/backend/.local-tools:$PATH"
gcloud auth login
firebase login
# Wybierz nowy TAG wydania, potem odczytaj digest z wyniku budowy.
gcloud builds submit --project sednoapp-79241 --billing-project sednoapp-79241 \
  --region europe-central2 \
  --service-account projects/sednoapp-79241/serviceAccounts/sedno-build@sednoapp-79241.iam.gserviceaccount.com \
  --config backend/deploy/firebase/cloudbuild.yaml \
  --substitutions _IMAGE=europe-central2-docker.pkg.dev/sednoapp-79241/backend/api:<TAG> .
python3 tools/prepare_firebase.py \
  --project sednoapp-79241 --region europe-central2 --site sednoapp-79241-api \
  --image europe-central2-docker.pkg.dev/sednoapp-79241/backend/api@sha256:<DIGEST> \
  --sql-instance sednoapp-79241:europe-central2:sedno-postgres \
  --google-credentials cloud-run --without-billing \
  --output backend/deploy/generated
cd backend/deploy/generated
bash deploy.sh
```

Generator działa lokalnie, tworząc `service.json`, `migration.json`, `firebase.json`
i skrypt wdrożenia. Manifesty zawierają odwołania do sekretów, nie ich wartości.
Przed wykonaniem przejrzyj konfigurację i upewnij się, że migracja zachowuje
zgodność ze starą wersją API w czasie przełączenia. Skrypt czeka na migrację,
wdraża usługę, sprawdza gotowość Cloud Run, publikuje Hosting i testuje publiczne
HTTPS `/health/ready`. Gotowość Cloud Run obejmuje probe połączenia z bazą.

`.gcloudignore` i `.dockerignore` ograniczają źródła do kodu produkcyjnego,
Dockerfile, konfiguracji budowy i osadzonej polityki. Nie wysyłają pliku Google
Services, lokalnych sekretów, mobilnej aplikacji, benchmarków ani SDK.
Kontener działa bez roota i nasłuchuje na porcie przekazanym jako `PORT`.

Hosting używa jednej reguły regex dla `/v1`, `/health`, powiadomień i dokumentów,
z `pinTag=true`. Jedna reguła zapobiega równoległemu nadpisywaniu tej samej usługi
przez Firebase CLI. Główna ścieżka `/` tej witryny nie jest stroną aplikacji.
Wszystkie odpowiedzi API mają `Cache-Control: no-store`.

Zachowaj stary digest i wydanie Hosting do wycofania. Rollback Hosting przywraca
przypiętą rewizję; bezpośredni adres Cloud Run wymaga osobnego przywrócenia ruchu.
Rollback kodu nie odwraca migracji bazy. Nie usuwaj bazy przy wycofaniu aplikacji.

## Flutter, logowanie i lokalny Development

`backend/tools/google-services.json` potwierdza projekt i pakiet. Flutter używa
jawnych `FirebaseOptions`, więc plik Google Services i dodatkowy plugin Gradle
nie są wymagane. Google i email/password w Firebase Auth zostały potwierdzone.
Identyfikator OAuth Web pobrano do lokalnego pliku konfiguracji. Nie dodano Analytics.

`mobile/config/firebase.local.json` zawiera publiczną konfigurację Firebase,
`GOOGLE_WEB_CLIENT_ID`, numer projektu Play i adres API. Plik jest pomijany przez Git.
Uruchomienie lub budowa z katalogu `mobile`:

```sh
flutter run --dart-define-from-file=config/firebase.local.json
flutter build apk --debug --dart-define-from-file=config/firebase.local.json
```

Dla lokalnego backendu nadal potrzebne są Compose PostgreSQL i sekrety opisane
w `backend/README.md`. Z katalogu `backend`:

```sh
dotnet run --project src/Sedno.Api --launch-profile Development
dotnet run --project src/Sedno.Api --launch-profile DevelopmentMock
```

Pierwszy profil używa prawdziwego modelu, drugi jawnej demonstracji. Oba nasłuchują
na `http://127.0.0.1:5000`; mock Integrity działa tylko lokalnie. Do testu logowania
z prawdziwym Firebase ustaw lokalnie `Firebase__ProjectId=sednoapp-79241`.
Emulator Android łączy się przez `http://10.0.2.2:5000`; przekaż ten adres osobnym
`--dart-define=BACKEND_BASE_URL=...` po pliku konfiguracji. Produkcja odrzuca mocki.

Test samego kontenera z jednorazową lokalną bazą:

```sh
docker build -f backend/Dockerfile -t sedno-api:local .
python3 tools/smoke_firebase_container.py --image sedno-api:local
```

## Pozostałe warunki uruchomienia aplikacji

W Play Console trzeba powiązać właściwy projekt z Play Integrity, przygotować
wydanie w kanale testowym i sprawdzić rzeczywisty token na urządzeniu. Zweryfikuj
odciski certyfikatów debug i Play App Signing w Firebase. APK debug nie zastępuje
testu aplikacji rozpoznawanej przez Google Play. Nie osłabiaj weryfikacji Integrity
w produkcji, aby ominąć ten krok.

`Billing:Enabled=false` jest jawnym pierwszym etapem; działa limit 5 na dzień UTC.
Aby włączyć subskrypcję, utwórz produkt i miesięczny plan 9,99 zł w Google Play,
nadaj kontu API dostęp w Play Console, skonfiguruj RTDN i przygotuj trwały
pierścień ASP.NET Data Protection. Generator bez `--without-billing` wymaga
`--billing-product` i `--push-email`; pierścień musi być współdzielony przez
Secret Manager w trybie read-only. Stare klucze są potrzebne do odczytu zakupów.
Polecenie `--init-billing-keyring <pusty-katalog>` działa tylko w Development;
nie używaj nowego pierścienia do istniejących zakupów.

Limit IP procesu działa na adresie połączenia proxy. Może grupować wielu klientów;
przed większym ruchem wymaga zweryfikowanego łańcucha proxy lub ochrony na brzegu.
Dzienne limity kont i instalacji są wspólne, atomowe i przechowywane w PostgreSQL.
Test odtworzenia bazy, TalkBack i pełne testy na telefonie pozostają do wykonania.
Zmiana hostingu nie jest potwierdzeniem zgodności prawnej aplikacji.

Wyniki i identyfikatory rewizji: [raport wdrożenia](../../../docs/task-14-deployment.pl.md).
Źródła: [Firebase Hosting](https://firebase.google.com/docs/hosting/cloud-run),
[tożsamość Cloud Run](https://docs.cloud.google.com/run/docs/securing/service-identity).
