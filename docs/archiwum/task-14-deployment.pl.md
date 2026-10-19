> Dokument archiwalny. Opisuje stan z czasu zadania. [Bieżąca dokumentacja](../README.md).

# Zadanie 14 — wdrożenie backendu, 19.10.2026

API działa pod **https://sednoapp-79241-api.web.app**.
To pierwszy etap bez płatności Google Play. Migracje i testy HTTPS zakończyły się
powodzeniem. Pełny przepływ na urządzeniu z prawidłowym tokenem Play Integrity
pozostaje do sprawdzenia po konfiguracji Play Console i wydania testowego.

## Potwierdzona konfiguracja

| Element | Stan |
| --- | --- |
| Projekt Firebase / Google Cloud | `sednoapp-79241`, numer `1003558402460` |
| Android / nazwa aplikacji | `xyz.sedno.app` / Sedno; potwierdzono również w zbudowanym APK |
| Strona aplikacji | `sedno.xyz`; nie zmieniano DNS ani istniejącej witryny |
| Osobna witryna Hosting API | `sednoapp-79241-api` |
| Cloud Run | `sedno-api`, region `europe-central2`, status Ready=True |
| Rewizja | `sedno-api-00002-cc7` |
| Przypięcie Firebase Hosting | `fh-5d13ea48ac9b2222` |
| Obraz | `europe-central2-docker.pkg.dev/sednoapp-79241/backend/api:firebase-20261019` |
| Digest | `sha256:712058d43952b3a4ecc2408e86429a74e0408a52b3ac679c04709986d34a3656` |
| Cloud Build | `6ebc40de-6233-43b6-a78e-12655a76d61f`, SUCCESS |
| Baza | `sedno-postgres` / `sedno`, PostgreSQL 17, Warszawa, RUNNABLE |
| Authentication | Google i email/password włączone; OAuth Web ID pobrany do lokalnej konfiguracji Fluttera |
| Model | OpenAI Responses, gpt-6-luna, reasoning none, tier default, store=false, 4096 tokenów, timeout 8 s |
| Billing | Jawnie wyłączony do czasu utworzenia produktu w Google Play |

Backend C# i PostgreSQL pozostały zachowane. Firebase Hosting przekazuje żądania
HTTPS do Cloud Run. Nie wprowadzono Firestore, Firebase Functions, Analytics ani
zmiany API aplikacji. Historia i zdjęcia nadal nie mają endpointu wysyłania.

## Baza i sekrety

Właściciel zatwierdził inicjalizację bazy oraz skopiowanie klucza OpenAI z lokalnego
magazynu `sedno-backend-dev` do `sedno-openai-key` w tym projekcie. Operację wykonano
bez wypisywania wartości i bez umieszczania ich w źródłach lub aplikacji.
Wcześniejsze odrzucenie automatycznego przeglądu rozwiązano przez tę jawną zgodę.

Utworzono odrębne role PostgreSQL `sedno_api` oraz `sedno_migrate`. Konto API ma
połączenie i operacje na danych, bez CREATE w schemacie, tworzenia ról/baz i praw
superusera; sprawdzono te uprawnienia podczas inicjalizacji. Konto migracji jest
właścicielem bazy i przekazuje uprawnienia do nowych tabel/sekwencji kontu API.
Wymagane do nadania właściciela członkostwo administratora w roli migracji dodano
na czas inicjalizacji i odebrano. Migracje uruchomiono jako oddzielny job przed
przełączeniem ruchu. Powtórzenie joba po zmianie obrazu zachowało istniejący schemat.

Secret Manager zawiera wersję 1 sekretów `sedno-postgres`, `sedno-postgres-migration`,
`sedno-credential-key`, `sedno-fingerprint-key`, `sedno-openai-key`, z replikacją
w Warszawie. Konto serwera ma dostęp tylko do swoich czterech sekretów, a konto
migracji tylko do połączenia migracji. Nie resetowano limitów ani kluczy przy
przełączaniu rewizji. Było to pierwsze wdrożenie bazy; nie eksportowano treści
ani ruchu aplikacji z lokalnego środowiska.

Cloud SQL: db-f1-micro, jedna strefa, SSD 10 GiB, szyfrowane połączenia,
brak wpisów w autoryzowanych sieciach publicznych, ochrona przed usunięciem.
Kopie: codziennie o 02:00 UTC, zachowanie 7 kopii, logi PITR z 1 dnia.
Cloud Logging `_Default`: zweryfikowano retencję 30 dni. Nie wykonano odtwarzania kopii.

Cloud Run: 1 CPU, 512 MiB, 1–3 instancje, współbieżność 20, CPU bez throttlingu.
Zapewnia to pracę godzinowego sprzątania metadanych. Baza i minimalna instancja
naliczają stałe opłaty także bez ruchu; nie zmierzono pełnego rachunku chmurowego.
Mały tier bazy wymaga testu obciążenia przed szerszym udostępnieniem.

## Weryfikacja

| Kontrola | Wynik |
| --- | --- |
| Pełny zestaw .NET po poprawce OAuth, 19.10 | **154/154**: 67 unit, 38 benchmark, 49 integracyjne z PostgreSQL |
| Testy generatora manifestów, 19.10 | **6/6** |
| `bash -n` i `git diff --check` | Poprawne |
| Cloud Build docelowego obrazu | Sukces |
| Job migracji | Sukces; używa wyłącznie sekretu bazy i oddzielnego konta |
| Publiczne `/health/live` i `/health/ready` | HTTPS 200 |
| Publiczne `/prywatnosc` i `/usun-konto` | HTTPS 200 |
| `/v1/quota` bez sesji | HTTPS 401 |
| `/v1/guest-sessions` ze sztucznym nieprawidłowym tokenem | HTTPS 403, brak sesji i użycia limitu |
| Cache-Control odpowiedzi powyżej | `no-store` |
| Konto usługi → Firebase lookup losowego nieistniejącego UID | HTTP 200, brak użytkownika |
| Tymczasowy job diagnostyczny | Zakończony sukcesem i usunięty |
| APK debug z konfiguracją chmurową, 19.10 | Zbudowane: `mobile/build/app/outputs/flutter-apk/app-debug.apk` |
| Pakiet w APK (`aapt dump badging`) | `xyz.sedno.app`, wersja 0.1.0+1 |

Testy zachowują scenariusze odpowiedzi atrap, timeoutów, zwalniania rezerwacji,
limitów 5/400 i resetu UTC, współbieżności, łączenia kont oraz prób nadpisania
instrukcji. Prompt pozostał bez zmian:
`31DA60C0D623E64C7FD6CEABFA9F69FADA2E8321CE839C8B8B37A2F21109DE02`.
Atrapy sprawdzają oddzielenie danych od instrukcji, nie gwarantują zachowania
rzeczywistego modelu dla dowolnego tekstu.

W przygotowaniu z 16.10 wykonano `dart format` (67 plików, 0 zmian),
`flutter analyze` (bez problemów) i pełne `flutter test` (**112/112**).
Automatyczny audyt dostępności sprawdził główny przepływ przy skali 100% i 250%,
kontrast, etykiety, cele dotykowe Android ≥48 dp i brak błędów układu.
Od tego czasu nie zmieniano UI; 19.10 ponownie zbudowano APK z konfiguracją API.
Nie wykonano ręcznego audytu TalkBack ani testu kamery/OCR na fizycznym urządzeniu.

## Poprawki sprawdzone podczas wdrożenia

- Konto usługi Cloud Run używa krótkotrwałych tokenów z jawnie żądanym zakresem
  OAuth. Rzeczywisty test wykazał 403 `ACCESS_TOKEN_SCOPE_INSUFFICIENT` dla tokenu
  domyślnego i 400 `INVALID_ARGUMENT` dla celowo nieprawidłowego tokenu Integrity
  po ustawieniu poprawnego zakresu. Dodano testy dla Integrity, Firebase i Billing.
- Adnotacja Cloud SQL joba musi znajdować się na szablonie wykonania, nie zadania.
  Poprawiono generator i test regresji; migracje w chmurze zakończyły się sukcesem.
- Jedna reguła RE2 z `pinTag` zastąpiła równoległe reguły dla tej samej usługi,
  które powodowały konflikt wersji w Firebase CLI. Testy sprawdzają trasy API
  i dokumentów oraz wykluczenie strony głównej i obcych ścieżek.
- Skrypt wdrożenia sprawdza gotowość Cloud Run i końcowy adres Firebase Hosting.
  Początkowe połączenie do bezpośredniej domeny run.app otrzymało błąd TLS;
  końcowy test właściwego adresu klienta przez HTTPS przeszedł poprawnie.

## Koszty modelu i pozostałe ograniczenia

Zachowano [pomiar z 16.10](../../backend/tools/Sedno.ModelBenchmark/results/2026-10-16-firebase-costs.md):
trzy syntetyczne próbki produkcyjnego default zużyły 4369 tokenów wejścia i 178
wyjścia, bazowo 0,00052590 USD razem, średnio 0,00017530 USD na wywołanie.
To kalkulacja według stawek z dnia pomiaru, bez podatków, cache i hostingu;
nie jest rachunkiem ani reprezentatywną prognozą. Podczas wdrożenia 19.10
nie wysyłano tekstów do modelu i nie eksportowano aplikacyjnego ruchu.

Pozostają: powiązanie projektu z Play Integrity w Play Console, test poprawnego
tokenu z wersji aplikacji rozpoznawanej przez Play, kontrola certyfikatów Firebase
oraz pełny test upraszczania/logowania na telefonie. Nie dodano obejścia Integrity
lub mocka do produkcji. Płatności wymagają produktu i planu Google Play, uprawnień
konta API, RTDN i trwałego pierścienia Data Protection. APK debug nie jest podpisanym
wydaniem do publikacji w Google Play.

Limit IP instancji opiera się na adresie proxy i może grupować wielu klientów;
przed większym ruchem potrzebuje zweryfikowanej konfiguracji proxy lub ochrony
na brzegu. Dzienne limity są wspólne i atomowe w PostgreSQL. Ustawienia poczty,
obsługa praw, test odtwarzania i publikacja dokumentów właściwych dla uruchomienia
produkcyjnej aplikacji nadal wymagają procedur operatora; wdrożenie backendu nie
jest stwierdzeniem zgodności prawnej.

Budowa APK zgłaszała ostrzeżenia o mechanizmie Kotlin Gradle Plugin w FlutterFire
oraz wersji XML narzędzi Android SDK; zakończyła się sukcesem. Poprzednie odtwarzanie
pakietów .NET zgłaszało NU1900 (brak dostępu do indeksu podatności); pełne testy
przeszły, lecz nie potwierdzono aktualnego statusu podatności zależności.

## Zmienione pliki

- Konfiguracja budowy: `.gitignore`, `.dockerignore`, `.gcloudignore`, `backend/Dockerfile`.
- Backend: `Program.cs`, `appsettings.Production.json`, `CloudRunHosting.cs`,
  `Properties/launchSettings.json`, `CloudRunAccessTokenSource.cs`.
- Wdrożenie: `backend/deploy/firebase/cloudbuild.yaml`, `deploy.sh`, `README.pl.md`,
  `empty/.gitkeep`; `tools/prepare_firebase.py`, `tools/smoke_firebase_container.py`.
- Testy: `OpenAiApiTests.cs`, `CloudRunHostingTests.cs`, `BillingKeyRingTests.cs`,
  `FirebaseTransportApiTests.cs`, `CloudRunAccessTokenTests.cs`,
  `tools/tests/test_prepare_firebase.py`, `mobile/test/app/accessibility_audit_test.dart`.
- Dokumentacja: główny i backendowy README, dokumenty stanu hostingu/prywatności,
  raport przygotowania i ten raport; zachowane metryki i wycena benchmarku.
- Poza Git: plik Google Services, konfiguracja Fluttera, manifesty z odwołaniami
  do sekretów i lokalne narzędzia. Klucze i hasła serwera nie są plikami aplikacji.

Instrukcja: [Firebase / Cloud Run](../../backend/deploy/firebase/README.pl.md).
