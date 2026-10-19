> Dokument archiwalny. Opisuje stan z czasu zadania. [Bieżąca dokumentacja](../README.md).

# Zadanie 14 — przygotowanie backendu do Firebase

Aktualny stan wdrożenia z 19.10.2026 opisuje [raport wdrożenia](task-14-deployment.pl.md).
Poniższy dokument zachowuje przebieg przygotowania z 16.10.2026.

Data: 16.10.2026. Przygotowano i sprawdzono lokalnie wdrożenie ASP.NET Core na
Cloud Run z Firebase Hosting, Cloud SQL PostgreSQL i Secret Manager. Nie wdrożono
zasobów w Google Cloud: projekt Firebase `sednoapp-79241` potwierdzono z dostarczonego pliku,
lecz brakuje uwierzytelnienia operatora. Zadanie nie jest ukończone
w części rzeczywistego przeniesienia danych i przełączenia ruchu.

## Potwierdzone informacje

- Pakiet i namespace Android: `xyz.sedno.app`, nazwa aplikacji: Sedno.
- Domena strony: `sedno.xyz`, odpowiedź HTTPS 200 sprawdzona na żywo.
- `/prywatnosc` i `/usun-konto` przekierowują do ścieżek z ukośnikiem, które zwracają
  HTTPS 200 i zawierają dokumenty. Publiczny HTML różni się od plików lokalnych;
  dostępność nie potwierdza zgodności wszystkich zapisów z działającą usługą.
- Nie potwierdzono praw do domeny, konfiguracji konsol Firebase/Play ani adresu API.
- Domyślny region: `europe-central2` (Warszawa), zgodnie z istniejącym planem
  prywatności. Aktualna dokumentacja Firebase potwierdza obsługę tego regionu.
- .NET 10 LTS; lokalnie SDK 10.0.112. Flutter 3.47.7, Dart 3.13.5; Android SDK dostępny.
- Firebase w Flutter używa `FirebaseOptions` i `--dart-define`. `google-services.json`
  może potwierdzić projekt i pakiet, ale nie jest potrzebny do bieżącej inicjalizacji
  ani nie daje dostępu do wdrażania. Nie dodano Analytics lub natywnych SDK obok FlutterFire.

## Implementacja

Kontener buduje tylko backend produkcyjny i osadzony dokument prywatności, działa
bez roota i używa portu Cloud Run. Katalogi build, w tym stare `bin\Debug`, nie
trafiają do kontekstu. Osobny job `--migrate` wykonuje migracje przed przełączeniem
ruchu, z oddzielnym użytkownikiem bazy i kontem serwisowym.

Generator tworzy trzy manifesty: usługę Cloud Run, job migracji i witrynę Hosting
API. Wymaga obrazu przypiętego digestem, projektu, witryny, Cloud SQL, produktu
Play i konta Pub/Sub. Sekrety mają przypięte wersje. Hosting przekazuje istniejące
ścieżki API i dokumenty, przypina rewizję i nie zastępuje strony głównej.

Transport Cloud Run uwzględnia TLS zakończony przez platformę, bez zaufania do
nagłówków klienta `X-Forwarded-*`. Inne wdrożenia nadal odrzucają HTTP w produkcji.
Wszystkie odpowiedzi API mają `no-store`; probes dodają także `no-cache`.

Klucze szyfrowania zakupów są współdzielone przez read-only mount Secret Manager,
z wyłączonym automatycznym generowaniem. Brak używalnego pierścienia zatrzymuje
start usługi z Billing. Lokalna komenda `--init-billing-keyring` inicjalizuje
pierścień tylko w Development i pustym katalogu. Istniejące klucze trzeba zachować
przy migracji; instrukcja obejmuje też pierścień z wieloma kluczami.

Profile `Development` i `DevelopmentMock` słuchają lokalnie na porcie 5000.
Mock modelu wymaga jawnego profilu/konfiguracji, pozostaje zabroniony w produkcji.
Prompt i ustawienia modelu nie zmieniły się. Hash promptu:
`31DA60C0D623E64C7FD6CEABFA9F69FADA2E8321CE839C8B8B37A2F21109DE02`.

## Wyniki kontroli

| Kontrola | Wynik |
| --- | --- |
| `dart format lib test` | 67 plików, 0 zmian |
| `flutter analyze` | Bez problemów |
| `flutter test` | 112/112 |
| `dotnet test backend/Sedno.Backend.sln --no-restore` | 141/141: 56 unit, 38 benchmark, 47 integracyjne z PostgreSQL |
| `python3 -m unittest discover -s tools/tests -v` | 4/4 |
| Przygotowanie manifestów z przykładową konfiguracją Warszawy | Sukces, brak połączeń z Google |
| `bash -n` skryptu wdrożenia | Sukces |
| Budowa `backend/Dockerfile` | Sukces, obraz lokalny `sedno-task14:local` |
| Test kontenera z jednorazowym PostgreSQL | Sukces: migracja bez modelu, port 9090, probes, dokumenty, 401 bez sesji, no-store; użytkownik 1654 |
| `flutter build apk --debug` | Sukces: `mobile/build/app/outputs/flutter-apk/app-debug.apk` |
| `git diff --check` | Sukces |

Testy zachowują dotychczasowe scenariusze limitów 5/400, współbieżności i resetu UTC,
mockują sieć i czas timeoutów. Nowe scenariusze integracyjne sprawdzają próby
nadpisania instrukcji jako dane użytkownika, stały prompt, obsługę błędów bez
wycieku, no-store, produkcyjny transport i odszyfrowanie zakupu przez drugą instancję
bez zmiany plików kluczy. Testy atrap nie gwarantują odporności rzeczywistego modelu.

## Dostępność

Nowe testy widgetów sprawdziły Start, zgodę na wysyłkę do AI, wynik, Historię
z zapisanym wpisem i Konto przy skalowaniu 100% i 250% na ekranie 412 × 892.
Automatyczne wytyczne Flutter: kontrast tekstu, podpisy elementów interaktywnych,
cele dotykowe Android ≥48 dp i brak błędów układu. Wynik pozytywny. Zachowano
istniejące kontrole prywatności, menu, ostrzeżeń i innych rozmiarów ekranów.
Nie wykonano manualnego audytu TalkBack na urządzeniu; wynik nie jest certyfikacją WCAG.

## Koszt modelu

Wykonano 8 nowych płatnych wywołań benchmarku na tekstach syntetycznych: rozgrzewkę
oraz 3 próbki dla default i fast. Wszystkie się powiodły. Produkcyjny default,
bez rozgrzewki: 4369 tokenów wejścia i 178 wyjścia, bazowo 0,00052590 USD razem,
średnio 0,00017530 USD na wywołanie. Mediana: 1771,16 ms.

[Szczegóły kosztów](../../backend/tools/Sedno.ModelBenchmark/results/2026-10-16-firebase-costs.md)
i [metryki bez treści](../../backend/tools/Sedno.ModelBenchmark/results/2026-10-16-firebase.jsonl).
To kalkulacja po aktualnych stawkach, bez faktury, cache, dopłat, podatków i hostingu.
Nie zmierzono kosztów chmury, ponieważ jej nie uruchomiono. Jedna stale działająca
instancja Cloud Run i CPU bez throttlingu zapewniają sprzątanie metadanych co godzinę,
ale generują koszt stały. Małe powtarzalne próbki nie przewidują pełnego ruchu.

## Ograniczenia i dalsze wdrożenie

Pełna procedura: [Firebase / Cloud Run](../../backend/deploy/firebase/README.pl.md).
Potrzebne są projekt Firebase, konfiguracja produktu Play, kont i sekretów, baza,
przeniesienie jej danych i kluczy, kontrola migracji, wdrożenie oraz sprawdzenie
rzeczywistego Androida z Firebase Auth, Play Integrity i Billing/RTDN. Nie skasowano
starej bazy ani backendu. Nie zmieniono DNS lub kont dostawców.

Limit IP procesu pozostaje oparty na adresie połączenia proxy, nie zweryfikowanym
IP użytkownika. Może grupować użytkowników; nie jest globalnym limitem instancji.
Przed większym ruchem wymaga zweryfikowanej konfiguracji proxy lub ochrony na brzegu.
Dzienne limity instalacji i kont pozostają wspólne i atomowe w PostgreSQL.

Przy odtwarzaniu pakietów .NET pojawiło się NU1900: brak dostępu do indeksu
podatności NuGet. Kompilacja i testy przeszły, ale nie potwierdzono aktualnego
statusu podatności zależności. Flutter przy budowie ostrzegał o użyciu starszego
mechanizmu Kotlin Gradle Plugin przez firebase_auth/firebase_core; APK powstało.
Nie aktualizowano zależności w tym zadaniu. Zbudowany APK to debug, bez konfiguracji
produkcyjnego API i podpisu wydania do Google Play.

## Zmienione pliki

- `.gitignore`, `.dockerignore`, `README.md`, `backend/README.md`.
- `backend/Dockerfile`.
- `backend/src/Sedno.Api/Program.cs`, `CloudRunHosting.cs`, `Properties/launchSettings.json`.
- `backend/deploy/firebase/README.pl.md`, `cloudbuild.yaml`, `deploy.sh`, `empty/.gitkeep`.
- `backend/tests/Sedno.IntegrationTests/OpenAiApiTests.cs`, `CloudRunHostingTests.cs`,
  `BillingKeyRingTests.cs`, `FirebaseTransportApiTests.cs`.
- `tools/prepare_firebase.py`, `tools/smoke_firebase_container.py`, `tools/tests/test_prepare_firebase.py`.
- `mobile/test/app/accessibility_audit_test.dart`.
- `backend/tools/Sedno.ModelBenchmark/results/2026-10-16-firebase.jsonl`
  i `2026-10-16-firebase-costs.md`.
- `docs/public/README.pl.md`, `docs/privacy-operations-plan.pl.md`, ten raport.

Źródła sprawdzone 16.10.2026:
[Firebase Hosting + Cloud Run](https://firebase.google.com/docs/hosting/cloud-run?hl=en),
[kontrakt kontenera](https://docs.cloud.google.com/run/docs/container-contract),
[model i ceny OpenAI](https://developers.openai.com/api/docs/models/gpt-6-luna).

## Uzupełnienie po przekazaniu google-services.json

Plik `backend/tools/google-services.json` potwierdza projekt `sednoapp-79241`,
numer `1003558402460` i pakiet `xyz.sedno.app`. Ustawiono identyfikator projektu
w `appsettings.Production.json` oraz wygenerowano pomijany przez Git
`mobile/config/firebase.local.json` z istniejącymi wartościami FlutterFire.
Plik źródłowy również jest pomijany przez Git. Nie wypisywano klucza API.
Brakuje klienta OAuth Web (lista oauth_client jest pusta), rzeczywistego adresu
API i uwierzytelnienia operatora Google Cloud. Nie wdrożono zasobów.

Pobrano i sprawdzono lokalne narzędzia: Google Cloud SDK 589.0.0 i Firebase CLI
15.34.0 w `backend/.local-tools` (pomijane przez Git). Nadal brak zalogowanego
operatora. Testy `FirebaseTransportApiTests` po zmianie projektu: 2/2; spójność
projektu, numeru i pakietu w plikach konfiguracji oraz `git diff --check`: poprawne.
W tym uzupełnieniu zmieniono wyłącznie konfigurację i dokumentację; poprzedni
pełny przebieg testów i APK opisano powyżej. Nie przebudowywano APK z niepełną
konfiguracją OAuth i API.

## Uzupełnienie po logowaniu operatora

Logowanie oraz dostęp do projektu `sednoapp-79241` zostały potwierdzone; rozliczenia
są włączone. Włączono wymagane API, utworzono repozytorium Artifact Registry
`europe-central2/backend` oraz konto budowy `sedno-build` z dostępem do odczytu
paczki źródłowej, zapisu obrazów w tym repozytorium i zapisu logów. Wybrane
uprawnienia operatora Cloud Build zostały sprawdzone. Nie wdrożono jeszcze API
ani bazy. Starsze akapity o braku zasobów/logowania opisują poprzedni etap.

Użytkownik potwierdził, że produkt Google Play nie jest jeszcze utworzony.
Generator zyskał jawne `--without-billing` dla pierwszego etapu API; nie
wyłącza automatycznie płatności przy niepełnej konfiguracji zwykłego wariantu.
Testy generatora po rozszerzeniu: 5/5. Dodano i sprawdzono `.gcloudignore`
(zakres wysyłki: 46 plików); `git diff --check` poprawny.

Firebase Auth zwraca `CONFIGURATION_NOT_FOUND` dla konfiguracji projektu
i dostawcy Google. Konto Google Cloud nie zastępuje inicjalizacji Authentication
w Firebase ani powiązania Play Integrity w Play Console.

Budowa Cloud Build zakończyła się sukcesem. Identyfikator:
`f35b6ada-789f-419b-be24-23c7083bb9ba`. Obraz:
`europe-central2-docker.pkg.dev/sednoapp-79241/backend/api:firebase-20261016`. Niezmienny digest:
`sha256:ca31293515c2e851ace5ee0f271ad8c910ab9b33db46f715c0026e5e02b44600`. Obraz znajduje się w Artifact Registry;
nie oznacza to uruchomienia usługi Cloud Run lub bazy PostgreSQL.

## Uzupełnienie po uruchomieniu Authentication

Potwierdzono aktywnych dostawców Google i email/password oraz dostępny OAuth Web
client ID. Lokalną konfigurację Fluttera uzupełniono automatycznie; nowy plik
Google Services nie jest potrzebny. Dodano wariant tożsamości usługi Cloud Run
bez tworzenia plików kluczy prywatnych Google. Nowy provider pobiera tokeny tylko
z metadanych Google, ogranicza odpowiedź, waliduje ją i odświeża token zgodnie
z wstrzykniętym zegarem. Lokalny wariant plikowy pozostał dostępny.

Zmiany tego etapu: `CloudRunAccessTokenSource.cs`, `Program.cs`,
`CloudRunAccessTokenTests.cs`, `FirebaseTransportApiTests.cs`,
`tools/prepare_firebase.py`, `tools/tests/test_prepare_firebase.py` oraz dokumentacja.
Pełne testy .NET: **151/151** (64 unit, 38 benchmark, 49 integracyjne).
Testy generatora: **6/6**. `git diff --check` poprawny. Nie zmieniano UI,
promptu ani produkcyjnych ustawień modelu; nie powtarzano pomiarów modelu.

Utworzono konta usług API i migracji z ograniczonym IAM, osobną witrynę Hosting
`sednoapp-79241-api` i zlecono bazę Cloud SQL `sedno-postgres` w europe-central2.
Instancja ma tier db-f1-micro, PostgreSQL 17, SSD 10 GiB, jedną strefę,
7 codziennych kopii, PITR z logami z 1 dnia, szyfrowane połączenia oraz ochronę
przed usunięciem; nie dodano autoryzowanych sieci publicznych.

Automatyczny przegląd bezpieczeństwa odrzucił uruchomienie inicjalizacji
persistentnej bazy oraz skopiowanie klucza OpenAI z lokalnego magazynu
`sedno-backend-dev` do konkretnego sekretu `sedno-openai-key` w projekcie
`sednoapp-79241`, wskazując brak dostatecznie szczegółowej autoryzacji tego
eksportu. Poproszono o jawną zgodę. Skrypt nie został uruchomiony, nie utworzono
sekretów i nie uruchomiono usługi API. Nie obchodzono odrzucenia.

Nowy obraz tożsamości Cloud Run zbudowano poprawnie: build `ce7b3fa3-3f54-4d1a-a500-183881b8a0ae`,
`europe-central2-docker.pkg.dev/sednoapp-79241/backend/api:firebase-identity-20261016`,
digest `sha256:ef0f14bd96750842a674e2a81566c12452e4456fa73198bd035e00569f1df3b4`.
Manifesty przygotowano z tym digestem i jawnym trybem bez Billing; oczekują na
zatwierdzenie operacji z bazą i sekretem.
