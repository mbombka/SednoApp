# Serwer Sedno

Produkcyjny serwer w Go 1.26 obsługuje upraszczanie, poprawianie, logowanie,
limity, zakupy i usuwanie konta. Korzysta z bazy `(default)` w Cloud Firestore
Standard (Native mode). Backend uzyskuje dostęp do bazy przez IAM, a aplikacja
Flutter korzysta z API. Baza Sedno nie zawiera tekstów, zdjęć ani wyników.
[Stan produkcji i instrukcja wdrożenia](deploy/firebase/README.pl.md).

`cmd/sedno` to punkt wejścia serwera i zadania `--cleanup`. Projekty .NET 10 LTS
w `src/` służą do sprawdzania zgodności. Z tych samych plików promptów korzystają
serwer Go i narzędzie pomiarowe .NET.

## Uruchomienie lokalne

Potrzebujesz Go 1.26.11 lub nowszego oraz Dockera z Compose. Polecenia wykonuj w `backend/`.
Emulator jest odrębnym procesem i nie łączy się z produkcyjną bazą.

```sh
docker compose up -d firestore
export ASPNETCORE_ENVIRONMENT=Development
export FIRESTORE_EMULATOR_HOST=127.0.0.1:8080
export Firestore__ProjectId=demo-sedno-local
export Firestore__UseEmulator=true
export Security__CredentialKey="$(openssl rand -base64 32)"
export Security__FingerprintKey="$(openssl rand -base64 32)"
export Model__Provider=mock
export PlayIntegrity__Provider=mock
go build -trimpath -o /tmp/sedno ./cmd/sedno
/tmp/sedno
```

Poczekaj na komunikat gotowości emulatora w `docker compose logs firestore`.
API: `http://127.0.0.1:5000`. `/health/live` sprawdza proces, `/health/ready` —
odczyt Firestore i brak trwającego importu. Emulator nie wymaga migracji schematu.
Dane lokalnego kontenera są tymczasowe. Zachowaj klucze bezpieczeństwa przy
ponownym uruchomieniu API korzystającego z tych samych danych.
Przechowuj klucze poza repozytorium.

Przy starcie instancji Cloud Run sprawdza domyślnie port TCP 8080. Pierwsze
żądanie może trafić do API po otwarciu portu. Wtedy dostęp do Firestore
sprawdzają operacje wykonywane w ramach żądania. W trakcie wdrożenia
`/health/ready` nadal pozwala zweryfikować dostęp do bazy i stan migracji.

Produkcja odrzuca emulator, również gdy ustawiono tylko `FIRESTORE_EMULATOR_HOST`.
Połączenie z prawdziwą bazą wymaga `Firestore__UseEmulator=false`, usunięcia tej
zmiennej oraz Application Default Credentials. Cloud Run używa konta usługi bez
plików kluczy. Nie uruchamiaj testów integracyjnych na produkcyjnym projekcie.

## Prawdziwe AI

Ustaw `OpenAI__ApiKey` w środowisku serwera.

```sh
Model__Provider=openai /tmp/sedno
```

OpenAI Responses API: `gpt-6-luna`, `reasoning.effort=none`, `service_tier=default`,
`store=false`, 4096 tokenów wyjścia, limit 8 sekund. Brak rozmów.
Walidacja przy uruchomieniu odrzuca inne wartości limitu tokenów i czasu;
eksperymenty z ustawieniami wykonuj w narzędziu pomiarowym.
[Prompt](src/Sedno.Infrastructure/Prompts/simplify.pl.txt) i
[narzędzia pomiarowe](tools/Sedno.ModelBenchmark/README.md) pozostają wspólne.

Do lokalnego logowania z rzeczywistym Firebase ustaw `Firebase__ProjectId` na projekt testowy.
Lokalna weryfikacja istnienia i usuwanie kont wymaga także
`Firebase__DeletionServiceAccountJsonPath`. To niezależne od połączenia z emulatorem bazy.

## Limity i dane

- Limit ruchu API jest lokalny dla instancji: domyślnie 60 żądań/min na
  zweryfikowane konto, tożsamość gościa lub adres wejścia bez sesji. Przed sesją
  użytkownicy za proxy Hosting mogą dzielić licznik. RTDN ma osobne 600 żądań/min
  i nadal wymaga weryfikacji tokenu Pub/Sub. Trzy instancje dają przybliżony
  trzykrotny limit; restart usuwa te liczniki. Limiter nie wykonuje operacji
  Firestore ani połączeń sieciowych; wcześniejsze uwierzytelnienie sesji może je
  wykonywać. [Granica zaufania, konfiguracja i testy](../docs/traffic-limiting-2026-10-21.pl.md).
- 5 udanych uproszczeń dziennie dla gościa, 400 łącznie dla subskrypcji. Reset o 00:00 UTC.
- Transakcja rezerwuje miejsce w dziennym dokumencie instalacji. Powiązane konto
  odczytuje dokumenty swoich instalacji; logowanie nie zeruje liczników.
- Transakcje Firestore chronią zapisy przy równoczesnych żądaniach i zmianach
  powiązań. Dzierżawa instalacji koordynuje zapisy między instancjami. Transakcja
  sprawdza ważność dzierżawy i aktualne powiązania kont.
- Metadane żądań chronią przed podwójnym wywołaniem AI. Zakończony duplikat zwraca
  `409 result_unavailable`, gdyż wynik nie jest przechowywany na serwerze. Aplikacja
  wysyła wtedy nowe żądanie z nowym identyfikatorem, co zużywa kolejne uproszczenie.
- Błąd modelu zwalnia rezerwację; porzucona rezerwacja przestaje obciążać limit po
  5 minutach, niezależnie od działania zadania sprzątającego.
- `daily_usage`: liczniki i rezerwacje do 8 dni. Pozostałe terminy:
  [procedury prywatności](../docs/privacy-operations-plan.pl.md).
- Wywołania Firebase Auth i Google Play są poza ponawianymi transakcjami. Krótkie
  dzierżawy dokumentów koordynują operacje konta między replikami; zapis sprawdza
  właściciela i ważność dzierżawy. Przerwane usuwanie konta wznawia zadanie sprzątające.

Sprzątanie lokalne:

```sh
/tmp/sedno --cleanup
```

W chmurze to godzinowe zadanie `sedno-cleanup`, uruchamiane przez Cloud Scheduler.
Nie wymaga klucza OpenAI, kluczy sesji ani pierścienia kluczy zakupów.
API może skalować się do zera; retencja nie zależy od ruchu. Nie używamy Firestore TTL.

## Płatności Google Play

Płatności skonfigurowano na istniejącym `sedno-api`, z kontem
`sedno-api@sednoapp-79241.iam.gserviceaccount.com` i bazą `(default)`.
Przed publicznym udostępnieniem wykonaj [testy zakupów na telefonie](../mobile/docs/google_play_subscription_sandbox.md).

### Subskrypcja

Skonfigurowany produkt to `subscription_full`, plan bazowy `monthly`, cena
9,99 PLN miesięcznie w Polsce. Domyślne wartości w Go to
`Billing__ProductId=subscription_full` i `Billing__Enabled=false`.
Produkcja jawnie ustawia `Billing__Enabled=true`. Plan `monthly` wybiera aplikacja.
Generator manifestów przy włączonych płatnościach wymaga
`--billing-product subscription_full` oraz konta Pub/Sub w `--push-email`.
Przy włączeniu wymagane są `Billing__Enabled=true`, `Billing__ProductId`,
`Billing__NotificationAudience`, `Billing__PushServiceAccountEmail` oraz trwały
`Billing__DataProtectionKeyPath`. Konto serwera wymaga uprawnień Android Publisher.

`Google__CredentialProvider=cloud-run` korzysta z tożsamości Cloud Run;
wariant `file` wymaga plików poświadczeń Firebase, Integrity i Billing.
Go i .NET odczytują i zapisują tokeny subskrypcji w formacie ASP.NET Core Data
Protection z nazwą aplikacji `Sedno` i przeznaczeniem `Sedno.PlayPurchase.v1`.
Cloud Run montuje z Secret Manager pierścień XML tylko do odczytu. Musi on
zawierać aktywny klucz AES-256-CBC z HMAC-SHA256. Jeśli korzystasz z istniejącej
bazy, zachowaj jej pierścień i oba klucze HMAC sesji i odcisków żądań.
W trybie Development polecenie `/tmp/sedno --init-billing-keyring ./test-keys`
tworzy nowy pierścień do lokalnych prób.

RTDN: uwierzytelniony Pub/Sub do `/notifications/google-play`; identyfikator
wiadomości zapewnia deduplikację. Oczekujący zakup nie daje dostępu. Weryfikacja
jest ważna maksymalnie 15 minut i nie dłużej niż zakup. Po jej wygaśnięciu
backend odświeża istniejący zakup przy żądaniu ustalającym limit, także bez
otwierania panelu subskrypcji. Świeży zapis nie powoduje połączenia z Google
ani zapisu w Firestore. Blokada konta i ponowny odczyt łączą równoczesne próby
między instancjami. Odświeżanie ma limit 2 sekund; po błędzie obowiązuje limit
darmowy bez zerowania użycia oraz minutowa przerwa przed następną próbą,
zapisana w zakupie jako opcjonalne `RefreshNotBefore`. Brak tego pola w starszych
dokumentach oznacza brak przerwy. RTDN i jawne przywracanie zakupu omijają tę
przerwę; poprawna weryfikacja ją usuwa. Nie odpytujemy nieaktywnych użytkowników.
Usunięcie konta nie anuluje subskrypcji.
[Aktualna kontrola RTDN i opis zmiany](../docs/subscription-verification-2026-10-21.pl.md).

### Pakiet jednorazowy

Produkt `simplifications_1000` jest obsługiwany na tym samym `sedno-api`
z tym samym kontem usługi i bazą `(default)`. Używa istniejącej flagi
`Billing__Enabled`. Google Play potwierdza produkt, płatność i powiązanie
zakupu z kontem Sedno. `POST /v1/purchases/simplifications` dodaje 1000 użyć
za każdą opłaconą sztukę w transakcji Firestore, a dopiero potem potwierdza
realizację zakupu w Google Play przez `consume`. Powtórzenie tokenu umożliwia
dokończenie realizacji bez ponownego dodawania użyć.

Saldo jest przechowywane na koncie, a skróty tokenów i stan zakupów w
`play_pack_purchases`. `GET /v1/quota` zwraca saldo i dostępne użycia. Pakiet
obsługuje oba tryby, ma pierwszeństwo przed limitem dziennym i nie resetuje się
o północy UTC. Udaną operację rozlicza się z pierwotnie zarezerwowanej puli.
Błąd i wygaśnięcie rezerwacji zwalniają użycie. Zwrot odejmuje użycia związane
z zakupem. Gdy pakiet się skończy, obowiązuje limit darmowy, subskrypcyjny
lub testerski. Sprawdź
[schemat API](../contracts/openapi.yaml) i
[próby pakietu w Google Play](../mobile/docs/google_play_subscription_sandbox.md#pakiet-jednorazowy).

## Testy i indeksy

```sh
FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 go test -count=1 ./...
go vet ./...
dotnet test Sedno.Backend.sln
```

Testy integracyjne Go łączą się z lokalnym emulatorem uruchomionym przed
`go test`. Testy integracyjne .NET uruchamiają własny emulator przez
Testcontainers. Testy używają syntetycznych danych i zastępują wywołania
modelu, weryfikację tożsamości i operacje Google Play.

Schemat dokumentów Go jest w [internal/store](internal/store). W [plikach
wdrożenia](deploy/firebase) są indeksy i reguły blokujące dostęp klientów.
Zmiany schematu muszą uwzględniać starsze rekordy. Historyczne migracje SQL
są wyłączone z kompilacji aplikacji. Npgsql służy narzędziu do dawnego importu.

## Diagnostyka odrzucenia Play Integrity

Wdrożona 19.10.2026; poprawka tolerancji zegarów: rewizja `sedno-api-00005-5g5`.
[Raport wdrożenia i weryfikacji](../docs/archiwum/integrity-diagnostics-deployment-2026-10-19.pl.md).

Backend Go zapisuje ostrzeżenie `Play Integrity rejected` (`EventId=4101`) z polem
`Reason`. Nie zapisuje tokenów, hashy, identyfikatorów instalacji, pełnych
odpowiedzi Google ani treści wyjątków. Dopuszcza różnicę zegarów do 5 sekund dla tokenu z przyszłości; maksymalny wiek
tokenu nadal wynosi 5 minut. Pozostałe kontrole Integrity pozostają bez zmian.

| Reason | Znaczenie |
| --- | --- |
| `missing_token`, `token_too_long` | Brak tokenu lub przekroczona długość |
| `decode_http_error` | Google odrzuciło odkodowanie; `HttpStatus` zawiera kod odpowiedzi |
| `token_from_future`, `token_expired` | Niedopuszczalny czas tokenu; `TokenAgeSeconds` zawiera wiek w sekundach (ujemny oznacza przyszłość) |
| `package_mismatch`, `request_hash_mismatch` | Niezgodny pakiet lub hash żądania |
| `app_not_recognized` | Brak `PLAY_RECOGNIZED` |
| `device_not_trusted` | Brak `MEETS_DEVICE_INTEGRITY` w tablicy werdyktów urządzenia |
| `invalid_response` | Nieprawidłowa struktura, brak wymaganego pola lub nieprawidłowa wartość; nie oznacza automatycznie odrzucenia urządzenia |
| `transport_error` | Błąd komunikacji lub odczytu danych |

Po wdrożeniu backendu powtórz logowanie → wylogowanie → logowanie na telefonie.
Zanotuj czas próby i odczytaj ostrzeżenia:

```sh
gcloud logging read \
  'resource.type="cloud_run_revision" AND resource.labels.service_name="sedno-api" AND jsonPayload.EventId=4101' \
  --project=sednoapp-79241 --freshness=30m --limit=50
```

Sama odpowiedź 403 z `/v1/guest-sessions` wskazuje etap awarii; dopiero `Reason`
pozwala ustalić, który warunek zawiódł. Diagnostyka nie odtworzy powodu dla
starszych żądań. Nie wymaga nowej wersji aplikacji Android.

## Potwierdzenie e-maila przy logowaniu

Wdrożone 19.10.2026, rewizja `sedno-api-00006-j9x`.
[Raport, testy i APK](../docs/archiwum/email-verification-2026-10-19.pl.md).

`/v1/auth/sessions` wymaga `email_verified=true` w podpisanym tokenie Firebase
przy logowaniu przez hasło (`password`). W przeciwnym razie zwraca HTTP 403,
`email_not_verified`, bez zużycia sesji gościa i bez tworzenia powiązania konta.
Warunek sprawdza także magazyn sesji Go. Logowanie Google zachowuje dotychczasowy
przebieg. Po potwierdzeniu adresu aplikacja odświeża token i łączy tę samą sesję
gościa; limit nie jest zerowany.

Od 20.10.2026 (`sedno-api-00010-wj5`) serwer odrzuca także wcześniej wystawione
sesje kont bez pola `AccountAccessVerified=true`. Backend zapisuje to pole
po sprawdzeniu tożsamości przy łączeniu konta. Dotyczy to również dawnych
sesji Google: użytkownik musi zalogować się ponownie. Sesje gości, powiązania
instalacji, limity i zakupy pozostają zachowane. Ponowne logowanie nie przywraca
ważności starego tokenu. [Raport kontroli](../docs/backend-access-2026-10-20.pl.md).
Wdrożenie serwera trzeba połączyć z udostępnieniem nowej aplikacji Android,
która obsługuje potwierdzanie i ponowne wysłanie wiadomości.

Język Firebase Authentication ustawiono na `pl` 19.10.2026; aplikacja jawnie
ustawia go również przed wysłaniem. Wersjonowana konfiguracja:
[auth/email-verification.pl.json](deploy/firebase/auth/email-verification.pl.json).
Maska aktualizacji to wyłącznie `notification.defaultLocale`.
Projekt odrzucił próbę zmiany treści, tematu i nadawcy przez API błędem
`EMAIL_TEMPLATE_UPDATE_NOT_ALLOWED`. Używana jest polska wiadomość systemowa
Firebase; własny tekst instrukcji jest w aplikacji. Nie skonfigurowano dodatkowego
operatora poczty i nie wysyłano wiadomości do użytkowników podczas konfiguracji.

## Odwoływanie sesji Firebase

Przygotowano kontrolę statusu i odwołania Firebase przy logowaniu oraz przy
używaniu sesji Sedna (cache instancji do 5 minut). Usuwanie konta wymaga
ponownego uwierzytelnienia tego samego użytkownika, z `auth_time` do 5 minut,
oraz kontroli bez cache. Sesje kont bez `FirebaseAuthTime` wymagają ponownego
logowania po wdrożeniu. Stare aplikacje nie mogą usuwać kont samym tokenem Sedna.
[Zmiany, testy i uwagi do wdrożenia](../docs/firebase-session-revocation-2026-10-20.pl.md).

## Poprawianie tekstu

`POST /v1/simplifications` przyjmuje opcjonalne `mode`: `simplify` (domyślnie)
lub `correct`. Odpowiedź potwierdza tryb w `result.mode`. Inne wartości,
w tym jawne `null`, są odrzucane przed rezerwacją limitu. Oba tryby korzystają
z tych samych transakcyjnych limitów i procedur zwalniania rezerwacji po błędzie.
Ponowienie tego samego identyfikatora z innym trybem zwraca `409 key_conflict`.

Osobny prompt [correct.pl.txt](src/Sedno.Infrastructure/Prompts/correct.pl.txt)
jest osadzony w Infrastructure jako `CorrectionPrompt`. Poprawia błędy językowe,
zachowuje sens i pytania, nie udziela odpowiedzi. Dotychczasowy prompt
upraszczania i parametry produkcyjnego modelu pozostają bez zmian.
Backend należy wdrożyć przed aplikacją z przełącznikiem; stare aplikacje mogą
dalej pomijać `mode`. Zmiana nie wymaga migracji Firestore ani nowych usług.

## Dostęp testerski

Pole `TesterAccessExpiresAt` konta w Firestore daje czasowy limit 400 operacji
dziennie bez zakupu. Datę sprawdza transakcja limitu; użycie nie jest zerowane.
[Skrypt administracyjny, ręczna edycja i wdrożenie](../docs/tester-access.pl.md).

## Język tekstu

`POST /v1/simplifications` przyjmuje opcjonalne `language` (domyślnie `pl`):
`pl`, `en` (UK), `en-US`, `fr`, `de`, `it`, `es`, `pt` (Portugalia), `sk`, `cs`,
`ro`, `nb` (Bokmål), `sv`. `TextLanguages` wybiera osobne prompty obu trybów.
Języki korzystają ze wspólnego limitu i ustawień modelu.
[Rozszerzenie kodu i kolejność wydania](../docs/multilingual-13-languages.pl.md).
[Opis zgodności, wdrożenia i rozszerzania](../docs/multilingual-app.pl.md).


## Obraz na potrzeby testów

Z katalogu głównego repozytorium zbuduj obraz i uruchom test kontenera.

```sh
docker build -f backend/Dockerfile -t sedno-go:test .
python3 tools/smoke_firebase_container.py --image sedno-go:test
```

Cloud Build korzysta z tego samego Dockerfile dla API i zadania `--cleanup`.
Lokalny test uruchamia emulator Firestore.
[Instrukcja konfiguracji Cloud Run](deploy/firebase/README.pl.md).
