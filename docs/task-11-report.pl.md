# Zadanie 11 — raport zmian

Dodano informację o przetwarzaniu tekstu przez AI przed przyciskiem wysłania,
ekran prywatności dla gości i kont, potwierdzane usuwanie konta z ostrzeżeniem
o osobnym anulowaniu subskrypcji, usuwanie Firebase i danych konta z PostgreSQL,
czyszczenie historii, sesji i edytora oraz zatrzymanie ponowień tekstu po zmianie sesji.
Lokalne czyszczenie po potwierdzeniu serwera można ponowić po błędzie magazynu.
Publiczna trasa backendu `/usun-konto` podaje kontakt mailowy bez wymagania aplikacji.

## Weryfikacja

- `dart format`: wykonany na zmienionych plikach Dart.
- `flutter analyze`: bez uwag (końcowy przebieg).
- `flutter test`: 83 testy przeszły; po ostatniej zmianie uruchomiono ponownie
  testy konta i repozytorium HTTP.
- `dotnet test backend/Sedno.Backend.sln`: 24 testy jednostkowe i 21 integracyjnych
  przeszło; integracyjne korzystały z PostgreSQL w Testcontainers.
- `git diff --check`: bez błędów.

Testy obejmują brak autoryzacji, odmowę dla gościa, izolację kont, wiele urządzeń,
usuwanie metadanych i zakupów, błąd dostawcy, odrzucenie starego tokenu Firebase
przy ponownym łączeniu, brak tekstu/wyniku/tokenów w logach, lokalne czyszczenie,
ponowienie po błędzie pamięci, potwierdzenie/anulowanie w UI i reset edytora.

## Konfiguracja i ograniczenia

Przed wdrożeniem ustawić `Firebase__DeletionServiceAccountJsonPath` i
`Privacy__DeletionEmail` zgodnie z backend/README.md. Brak konfiguracji produkcyjnej
zatrzymuje uruchomienie backendu. Konto usuwane jest przez API administracyjne
Firebase; nie anuluje to subskrypcji ani nie usuwa konta Google.
Weryfikacja istnienia Firebase podczas łączenia wymaga tych samych poświadczeń.

Nie wykonano połączeń z prawdziwym Firebase, Google Play ani produkcyjną pocztą.
Nie wdrożono hostingu ani nie zbudowano APK. Strona stanie się publiczna po
wdrożeniu backendu HTTPS; rzeczywisty adres trzeba wpisać w Play Console.
Droga przez stronę otwiera klienta pocztowego. Operator musi zweryfikować
właściciela konta i obsłużyć zgłoszenie; nie ma niezabezpieczonego endpointu
usuwającego konto na podstawie podanego e-maila.

Firebase i PostgreSQL nie mają wspólnej transakcji: po powodzeniu Firebase i
błędzie zapisu należy ponowić z tym samym bearerem. Utrata odpowiedzi po commicie
wymaga sprawdzenia stanu lub pomocy operatora; aplikacja nie uznaje 401 za dowód
usunięcia. Zdalne usunięcie nie czyści historii na pozostałych urządzeniach.
Kopie zapasowe serwera, terminy obsługi i brakujące fakty polityki są jawnie
oznaczone do uzupełnienia przed publikacją.

Wymagania checklisty zweryfikowano w
[dokumentacji Google Play](https://support.google.com/googleplay/android-developer/answer/13327111).
Adapter tożsamości wykorzystuje oficjalne metody
[delete](https://docs.cloud.google.com/identity-platform/docs/reference/rest/v1/projects.accounts/delete)
i [lookup](https://docs.cloud.google.com/identity-platform/docs/reference/rest/v1/projects.accounts/lookup).

## Zmienione i dodane pliki

- `backend/README.md`
- `backend/src/Sedno.Api/DeletionPage.cs`
- `backend/src/Sedno.Api/Program.cs`
- `backend/src/Sedno.Infrastructure/AccountDeletionService.cs`
- `backend/src/Sedno.Infrastructure/GuestStore.cs`
- `backend/tests/Sedno.IntegrationTests/BackendFixture.cs`
- `backend/tests/Sedno.IntegrationTests/DeletionApiTests.cs`
- `backend/tests/Sedno.UnitTests/AccountDeletionTests.cs`
- `contracts/openapi.yaml`
- `docs/google-play-data-safety.pl.md`
- `docs/privacy-policy-draft.pl.md`
- `docs/task-11-report.pl.md`
- `mobile/lib/app/app.dart`
- `mobile/lib/features/account/data/backend_session_gateway.dart`
- `mobile/lib/features/account/data/firebase_account_repository.dart`
- `mobile/lib/features/account/presentation/account_screen.dart`
- `mobile/lib/features/home/presentation/home_screen.dart`
- `mobile/lib/features/privacy/presentation/privacy_screen.dart`
- `mobile/lib/features/simplification/data/http_simplification_repository.dart`
- `mobile/test/features/account/data/account_deletion_test.dart`
- `mobile/test/features/account/data/firebase_account_deletion_test.dart`
- `mobile/test/features/account/presentation/account_screen_test.dart`
- `mobile/test/features/simplification/data/http_simplification_repository_test.dart`
