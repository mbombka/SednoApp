# Serwer Sedno

Serwer obsługuje uproszczenia AI, logowanie, limity, zakupy i usuwanie konta.
C# / .NET 10 LTS, Cloud Firestore **Standard, Native mode**, baza `(default)`.
Dostęp do bazy ma wyłącznie backend przez IAM; aplikacja Flutter korzysta z API.
Zdjęcia, teksty i wyniki nie są zapisywane w bazie backendu.

Serwer `https://sednoapp-79241-api.web.app` działa z Firestore od 19.10.2026.
Przeniesiono metadane testowe; stary Cloud SQL zatrzymano. Płatności pozostają wyłączone.
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
  `409 result_unavailable`, gdyż wynik nie jest przechowywany na serwerze.
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

Płatności są wyłączone do zakończenia [testów zakupów](../mobile/docs/google_play_subscription_sandbox.md).
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
