# Serwer Sedno

Serwer obsługuje uproszczenia AI, logowanie, limity i usuwanie konta.
Korzysta z C# / .NET 10 LTS i PostgreSQL. Działa pod adresem
`https://sednoapp-79241-api.web.app`; płatności są obecnie wyłączone.
[Wdrożenie w chmurze](deploy/firebase/README.pl.md).

## Uruchomienie lokalne

Potrzebujesz .NET 10 SDK i działającego Dockera z Compose. Polecenia wykonuj w `backend/`.
Poniższy przykład tworzy lokalną bazę i używa odpowiedzi demonstracyjnych zamiast płatnego AI.

```sh
export POSTGRES_PASSWORD="$(openssl rand -base64 32)"
docker compose up -d --wait
export ASPNETCORE_ENVIRONMENT=Development
export ConnectionStrings__Postgres="Host=localhost;Port=5432;Database=sedno;Username=sedno;Password=${POSTGRES_PASSWORD}"
export Security__CredentialKey="$(openssl rand -base64 32)"
export Security__FingerprintKey="$(openssl rand -base64 32)"
# Wykonaj instalację narzędzia tylko, jeśli dotnet-ef nie jest dostępne.
dotnet tool install --global dotnet-ef --version 10.0.3
dotnet ef database update --project src/Sedno.Infrastructure --startup-project src/Sedno.Api
dotnet run --project src/Sedno.Api --launch-profile DevelopmentMock
```

Serwer nasłuchuje na `http://127.0.0.1:5000`.
`/health/live` sprawdza proces, a `/health/ready` — połączenie z bazą.
Profil `DevelopmentMock` udaje AI i kontrolę Play Integrity. Produkcja odrzuca atrapy.

Przy kolejnych uruchomieniach zachowaj to samo hasło bazy i klucze bezpieczeństwa.
Zmienne z przykładu działają tylko w bieżącym terminalu; nie losuj ich ponownie dla
istniejącej bazy. Do trwałego zapisu lokalnego użyj `dotnet user-secrets set`
z `--project src/Sedno.Api` dla `ConnectionStrings:Postgres`,
`Security:CredentialKey` i `Security:FingerprintKey`. Nie zapisuj wartości w Git.

## Prawdziwe AI

Zapisz klucz jako `OpenAI:ApiKey` w lokalnym magazynie .NET user-secrets
`sedno-backend-dev` lub ustaw `OpenAI__ApiKey` w środowisku. Następnie uruchom:

```sh
dotnet run --project src/Sedno.Api --launch-profile Development
```

To wywołuje płatne OpenAI Responses API: `gpt-6-luna`, `reasoning.effort=none`,
`service_tier=default`, `store=false`, 4096 tokenów wyjścia, limit 8 sekund.
Nie są tworzone rozmowy. Klucza nigdy nie dodawaj do aplikacji Android.
[Prompt](src/Sedno.Infrastructure/Prompts/simplify.pl.txt) jest wspólny dla serwera
oraz [pomiarów AI](tools/Sedno.ModelBenchmark/README.md).

Do lokalnego logowania z rzeczywistym Firebase ustaw
`Firebase__ProjectId=sednoapp-79241`. Lokalna weryfikacja istnienia i usuwanie kont
wymagają także pliku konta usługi wskazanego przez `Firebase__DeletionServiceAccountJsonPath`.
Produkcyjny Cloud Run korzysta z własnego konta usługi, bez plików kluczy.

## Limity i dane

- Darmowy limit: 5 udanych uproszczeń dziennie; płatny: 400 łącznie. Reset o 00:00 UTC.
- Logowanie łączy wykorzystanie gościa z kontem i nie daje nowej puli.
- Baza przechowuje sesje, liczniki i metadane żądań, bez tekstów i wyników.
- Ten sam klucz żądania zapobiega podwójnemu wykonaniu. Utraconego wyniku
  nie da się pobrać ponownie: zakończony duplikat zwraca `409 result_unavailable`.
- Błąd modelu zwalnia rezerwację limitu; niezakończona rezerwacja wygasa po 5 minutach.
- Usunięcie konta usuwa dane Sedno i tożsamość Firebase, ale nie anuluje subskrypcji Google Play.

Opis endpointów: [contracts/openapi.yaml](../contracts/openapi.yaml).
Czasy przechowywania i obsługa usuwania: [procedury prywatności](../docs/privacy-operations-plan.pl.md).
Loguj wyłącznie metryki techniczne. Wyłącz przechwytywanie treści, nagłówków
uwierzytelniania i adresów zawierających tokeny także w narzędziach monitoringu.

## Subskrypcje Google Play

Płatności pozostają wyłączone do zakończenia konfiguracji i
[testów zakupów](../mobile/docs/google_play_subscription_sandbox.md).
Wymagane ustawienia serwera:

| Ustawienie | Znaczenie |
| --- | --- |
| `Billing__Enabled=true` | Włącza obsługę zakupów |
| `Billing__ProductId` | Identyfikator produktu Google Play; pakiet to `xyz.sedno.app` |
| `Billing__NotificationAudience` | Dokładny adres HTTPS odbierający powiadomienia |
| `Billing__PushServiceAccountEmail` | Konto podpisujące powiadomienia Pub/Sub |
| `Billing__DataProtectionKeyPath` | Trwały, wspólny magazyn kluczy szyfrujących tokeny zakupów |

Konto serwera musi mieć dostęp do zakupów w Play Console i Android Publisher API.
Cloud Run używa `Google__CredentialProvider=cloud-run`; wariant `file` wymaga
`Billing__ServiceAccountJsonPath` oraz plików poświadczeń Firebase i Integrity.
W chmurze pierścień kluczy zakupów jest udostępniany z Secret Manager tylko do odczytu.
Zachowaj stare klucze przy kolejnych wdrożeniach — bez nich nie odczytasz istniejących zakupów.

Powiadomienia Google Play (RTDN) trafiają przez uwierzytelniony Pub/Sub do
`/notifications/google-play`. Skonfiguruj ponowienia i obsługę niedostarczonych wiadomości.
Serwer weryfikuje zakupy i potwierdza je w Google; zakup oczekujący nie daje dostępu.
Zapamiętana weryfikacja jest ważna najwyżej 15 minut i nie dłużej niż zakup;
po jej wygaśnięciu obowiązuje limit darmowy bez zerowania użycia.

## Testy i zmiany bazy

```sh
dotnet test Sedno.Backend.sln
```

Testy integracyjne uruchamiają odrębny PostgreSQL przez Docker. Testują m.in.
limity, współbieżność, timeouty, logowanie, zakupy, usuwanie i brak treści w logach.

Nową zmianę schematu przygotuj i sprawdź przed wdrożeniem:

```sh
dotnet ef migrations add NazwaZmiany --project src/Sedno.Infrastructure --startup-project src/Sedno.Api --output-dir Migrations
```

W produkcji migracje wykonuje osobne zadanie `sedno-migrate` przed wdrożeniem API.
Aktualizacja polityki prywatności: [instrukcja dokumentów](../docs/public/README.pl.md).
