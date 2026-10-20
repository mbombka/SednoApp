# Serwer Sedno

Serwer obsługuje uproszczenia AI, logowanie, limity, zakupy i usuwanie konta.
C# / .NET 10 LTS, Cloud Firestore **Standard, Native mode**, baza `(default)`.
Dostęp do bazy ma wyłącznie backend przez IAM; aplikacja Flutter korzysta z API.
Zdjęcia, teksty i wyniki nie są zapisywane w bazie backendu.

Serwer `https://sednoapp-79241-api.web.app` działa z Firestore od 19.10.2026.
Przeniesiono metadane testowe; starą instancję Cloud SQL i cztery kopie zapasowe
usunięto 19.10.2026. Obsługę płatności na istniejącym serwerze włączono
20.10.2026 do testów przez Google Play; odbiór zakupów pozostaje do wykonania.
[Wdrożenie, migracja i pozostałe porządki](deploy/firebase/README.pl.md).

## Uruchomienie lokalne

Potrzebujesz .NET 10 SDK i Dockera z Compose. Polecenia wykonuj w `backend/`.
Emulator jest odrębnym procesem i nie łączy się z produkcyjną bazą.

```sh
docker compose up -d
export ASPNETCORE_ENVIRONMENT=Development
export FIRESTORE_EMULATOR_HOST=127.0.0.1:8080
export Firestore__ProjectId=demo-sedno-local
export Firestore__UseEmulator=true
export Security__CredentialKey="$(openssl rand -base64 32)"
export Security__FingerprintKey="$(openssl rand -base64 32)"
dotnet run --project src/Sedno.Api --launch-profile DevelopmentMock
```

Poczekaj na komunikat gotowości emulatora w `docker compose logs firestore`.
API: `http://127.0.0.1:5000`. `/health/live` sprawdza proces, `/health/ready` —
odczyt Firestore i brak trwającego importu. Emulator nie wymaga migracji schematu.
Dane lokalnego kontenera są tymczasowe. Zachowaj klucze bezpieczeństwa przy
ponownym uruchomieniu API korzystającego z tych samych danych.
Do trwałego zapisu kluczy użyj .NET user-secrets (`Security:CredentialKey`,
`Security:FingerprintKey`), nigdy Git.

Produkcja odrzuca emulator, również gdy ustawiono tylko `FIRESTORE_EMULATOR_HOST`.
Połączenie z prawdziwą bazą wymaga `Firestore__UseEmulator=false`, usunięcia tej
zmiennej oraz Application Default Credentials. Cloud Run używa konta usługi bez
plików kluczy. Nie uruchamiaj testów integracyjnych na produkcyjnym projekcie.

## Prawdziwe AI

Zapisz `OpenAI:ApiKey` w .NET user-secrets lub ustaw `OpenAI__ApiKey` na serwerze:

```sh
dotnet run --project src/Sedno.Api --launch-profile Development
```

OpenAI Responses API: `gpt-6-luna`, `reasoning.effort=none`, `service_tier=default`,
`store=false`, 4096 tokenów wyjścia, limit 8 sekund. Brak rozmów.
Walidacja przy uruchomieniu odrzuca inne wartości limitu tokenów i czasu;
eksperymenty z ustawieniami wykonuj w narzędziu pomiarowym.
[Prompt](src/Sedno.Infrastructure/Prompts/simplify.pl.txt) i
[narzędzia pomiarowe](tools/Sedno.ModelBenchmark/README.md) pozostają wspólne.

Do lokalnego logowania z rzeczywistym Firebase ustaw `Firebase__ProjectId=sednoapp-79241`.
Lokalna weryfikacja istnienia i usuwanie kont wymaga także
`Firebase__DeletionServiceAccountJsonPath`. To niezależne od połączenia z emulatorem bazy.

## Limity i dane

- 5 udanych uproszczeń dziennie dla gościa, 400 łącznie dla subskrypcji. Reset o 00:00 UTC.
- Transakcja rezerwuje miejsce w dziennym dokumencie instalacji. Powiązane konto
  odczytuje dokumenty swoich instalacji; logowanie nie zeruje liczników.
- Równoczesne żądania oraz zmiany powiązań są kontrolowane transakcjami Firestore.
  Lokalna kolejka instalacji ogranicza konflikty w obrębie jednej instancji;
  dzierżawa instalacji kolejkuje zapisy również między instancjami. Transakcje
  dodatkowo sprawdzają ważność dzierżawy i aktualne powiązania kont.
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
dotnet run --project src/Sedno.Api --no-launch-profile -- --cleanup
```

W chmurze to godzinowe zadanie `sedno-cleanup`, uruchamiane przez Cloud Scheduler.
Nie wymaga klucza OpenAI, kluczy sesji ani pierścienia kluczy zakupów.
API może skalować się do zera; retencja nie zależy od ruchu. Nie używamy Firestore TTL.

## Subskrypcje Google Play

Płatności skonfigurowano na istniejącym `sedno-api`, z kontem
`sedno-api@sednoapp-79241.iam.gserviceaccount.com` i bazą `(default)`.
[Stan wdrożenia i ustawienia Play Console](../docs/billing-deployment-2026-10-20.pl.md).
Przed publicznym udostępnieniem wykonaj [testy zakupów](../mobile/docs/google_play_subscription_sandbox.md).
Skonfigurowany produkt to `subscription_full`, plan bazowy `monthly`, cena
9,99 PLN miesięcznie w Polsce. `Billing:ProductId` ma domyślną wartość
`subscription_full` w `appsettings.json`; `Billing:Enabled` w pliku pozostaje `false`,
a jawna konfiguracja wdrożonego serwera ustawia `Billing__Enabled=true`.
Przy nadpisaniu konfiguracji użyj `Billing__ProductId=subscription_full`.
Plan `monthly` wybiera aplikacja; nie wpisuj go zamiast identyfikatora produktu.
Generator manifestów przy włączonych płatnościach wymaga
`--billing-product subscription_full` oraz konta Pub/Sub w `--push-email`.
Przy włączeniu wymagane są `Billing__Enabled=true`, `Billing__ProductId`,
`Billing__NotificationAudience`, `Billing__PushServiceAccountEmail` oraz trwały
`Billing__DataProtectionKeyPath`. Konto serwera wymaga uprawnień Android Publisher.

`Google__CredentialProvider=cloud-run` korzysta z tożsamości Cloud Run;
wariant `file` wymaga plików poświadczeń Firebase, Integrity i Billing.
Pierścień Data Protection jest wspólny, z Secret Manager tylko do odczytu.
Zachowaj klucze i identyfikatory kont podczas migracji — bez nich nie odczytasz
istniejących zakupów ani nie zweryfikujesz ich powiązania.

RTDN: uwierzytelniony Pub/Sub do `/notifications/google-play`; identyfikator
wiadomości zapewnia deduplikację. Oczekujący zakup nie daje dostępu. Weryfikacja
jest ważna maksymalnie 15 minut i nie dłużej niż zakup. Po jej wygaśnięciu
obowiązuje limit darmowy bez zerowania użycia. Usunięcie konta nie anuluje subskrypcji.

## Testy i indeksy

```sh
dotnet test Sedno.Backend.sln
```

Testy integracyjne uruchamiają emulator Firestore przez Testcontainers/Docker,
bez połączenia z Google. Tożsamość, zakupy, AI i czas są kontrolowane w testach.
Sprawdzają współbieżność, limity, sesje, usuwanie, retencję i import danych.

Schemat dokumentów jest w `FirestoreStore`, indeksy i zakaz dostępu klientów w
[plikach wdrożenia](deploy/firebase). Zmiany schematu dokumentów muszą uwzględniać
starsze rekordy; brak EF nie usuwa potrzeby planowania migracji danych.
Historyczne migracje SQL pozostają w Git, wyłączone z kompilacji aplikacji.
Npgsql występuje wyłącznie w oddzielnym narzędziu jednorazowej migracji.

## Diagnostyka odrzucenia Play Integrity

Wdrożona 19.10.2026; poprawka tolerancji zegarów: rewizja `sedno-api-00005-5g5`.
[Raport wdrożenia i weryfikacji](../docs/archiwum/integrity-diagnostics-deployment-2026-10-19.pl.md).

Backend zapisuje ostrzeżenie `PlayIntegrityRejected` (EventId 4101) z polem
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
| `transport_error`, `io_error` | Błąd komunikacji lub odczytu danych |

Po wdrożeniu backendu powtórz logowanie → wylogowanie → logowanie na telefonie.
Zanotuj czas próby i odczytaj ostrzeżenia:

```sh
gcloud logging read \
  'resource.type="cloud_run_revision" AND resource.labels.service_name="sedno-api" AND (textPayload:"Play Integrity rejected." OR jsonPayload.EventId.Name="PlayIntegrityRejected")' \
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
Warunek sprawdza także `GuestStore`. Logowanie Google zachowuje dotychczasowy
przebieg. Po potwierdzeniu adresu aplikacja odświeża token i łączy tę samą sesję
gościa; limit nie jest zerowany.

To kontrola wystawiania nowych sesji. Wcześniej wystawione sesje kont zachowują
ważność do wylogowania lub wygaśnięcia. Nowa aplikacja przy odczycie oczekującego
konta unieważnia lokalną sesję backendu, jeśli zachowała ją starsza wersja.
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
