# Odwoływanie sesji Sedna po zmianach w Firebase — 20.10.2026

Implementacja i testy lokalne zadania 2 z `Tasks.md`. Zmiany nie zostały
wdrożone na serwer ani sprawdzone na telefonie. Nie budowano APK.

## Zachowanie

Nowe sesje kont zapisują `FirebaseAuthTime`, pochodzący z podpisanego pola
`auth_time` ID tokenu Firebase. Backend przy logowaniu sprawdza aktualny status
konta przez istniejące połączenie IAM z Firebase Authentication. Porównuje czas
uwierzytelnienia z `validSince`; reset hasła lub odwołanie sesji unieważnia więc
również poświadczenie Sedna o wcześniejszym czasie uwierzytelnienia.
Blokada i brak użytkownika odmawiają dostępu.

Przy używaniu sesji kontrola konta ma osobny cache w każdej instancji API:

- Ważność maksymalnie 5 minut od rozpoczęcia sprawdzenia, bez odświeżania przy odczycie.
- Wspólny wynik kontroli dla sesji tego samego UID; równoczesne chybienia czekają
  na jedno wywołanie. Anulowanie jednego żądania nie anuluje pozostałych.
- Maksymalnie 10 000 wpisów w pamięci, brak zapisów wyników kontroli w Firestore.
- Kolejne sprawdzenie dopiero przy żądaniu; brak odpytywania nieaktywnych kont.
- Wygaśnięty wynik nie daje dostępu przy błędzie Firebase. API zwraca wówczas
  błąd serwera, a kolejna próba ponawia kontrolę. Nie zapisuje błędu jako zgody.

Logowanie zawsze omija cache. `DELETE /v1/account` wymaga ponadto JSON
`{"idToken":"…"}` z tokenem Firebase tego samego użytkownika i `auth_time`
nie starszym niż 5 minut. Kontrola Firebase omija cache i sprawdza zarówno
czas nowego uwierzytelnienia, jak i czas uwierzytelnienia sesji Sedna.
Świeże `iat` po odświeżeniu tokenu nie zastępuje świeżego `auth_time`.
Opis pól Firebase: [UserInfo w dokumentacji Google](https://docs.cloud.google.com/identity-platform/docs/reference/rest/v1/UserInfo).

Aplikacja potwierdza tożsamość przez ponowne podanie hasła lub wybór konta Google
oraz `reauthenticateWithCredential`, a dopiero potem pobiera i wysyła ID token.
Błąd potwierdzenia tożsamości nie wysyła żądania usunięcia.
Odpowiedź 401 usuwa stare poświadczenie Sedna, wylogowuje Firebase i Google,
czyści historię i odświeża ekran Konta. Odrzucenie nie uruchamia automatycznej
pętli pobierania limitu ani ponownego wysłania tekstu jako gość.

## Wdrożenie i zgodność

Sesje kont bez `FirebaseAuthTime` są odrzucane. Po wdrożeniu użytkownicy takich
sesji muszą zalogować się ponownie. Sesje gości nie wymagają kontroli Firebase.
Nowa wersja aplikacji obsługuje odrzucenie sesji i nowe wymaganie usuwania konta;
starsza aplikacja nie może usuwać kont samym poświadczeniem Sedna.

Konto oznaczone do usunięcia od razu traci dostęp. Jeżeli usunięcie w Firebase
lub dalsze sprzątanie zostanie przerwane, istniejące zadanie sprzątające wznawia
operację z zapisanego znacznika. Odpowiedź 401 nie jest potwierdzeniem usunięcia
całości danych. Potwierdzenie 204 nadal pozwala aplikacji dokończyć lokalne
czyszczenie po ponownym uruchomieniu.

Nie zmieniono transakcyjnego wiązania tożsamości i limitów. Nie utworzono
nowej bazy, backendu ani konta usługi.

## Sprawdzenie

- `dart format`: zmienione pliki sformatowane.
- `flutter analyze`: brak uwag.
- `flutter test`: wszystkie 176 testów przeszły.
- `dotnet test backend/Sedno.Backend.sln --no-restore -m:1`: 105 testów
  jednostkowych, 69 integracyjnych z lokalnym emulatorem Firestore, 38 testów
  narzędzi pomiarowych — wszystkie przeszły.
- Testy obejmują reset hasła, odwołanie, blokadę i usunięcie użytkownika,
  ponowne użycie starego poświadczenia po nowym logowaniu, granicę 5 minut,
  brak zbędnych kontroli, łączenie równoczesnych kontroli, anulowanie pojedynczego
  oczekującego żądania i awarię Firebase po wygaśnięciu cache.
- Usuwanie konta: brak tokenu, stary `auth_time`, inny użytkownik, blokada,
  odwołana sesja Sedna mimo świeżego tokenu Firebase i poprawne usunięcie.
- Testy aplikacji sprawdzają ponowne uwierzytelnienie e-mail/Google, brak wysyłania
  usunięcia po błędzie uwierzytelnienia, czyszczenie po 401, wznowienie lokalnego
  czyszczenia oraz formularz hasła i aktualizację otwartego ekranu Konta.

Testy SDK wymagały uruchomienia poza ograniczonym sandboxem (cache Fluttera,
lokalne gniazda .NET i Docker). Kontrole Firebase i Google są zastąpione atrapami;
nie wykonywano resetów, blokad ani usunięć rzeczywistych kont.

## Zmienione pliki

- `Tasks.md`
- `backend/README.md`
- `backend/src/Sedno.Api/Program.cs`
- `backend/src/Sedno.Application/Contracts.cs`
- `backend/src/Sedno.Domain/Models.cs`
- `backend/src/Sedno.Infrastructure/AccountDeletionService.cs`
- `backend/src/Sedno.Infrastructure/FirebaseAccountAccess.cs`
- `backend/src/Sedno.Infrastructure/FirebaseTokenVerifier.cs`
- `backend/src/Sedno.Infrastructure/GuestStore.cs`
- `backend/tests/Sedno.IntegrationTests/ApiTests.cs`
- `backend/tests/Sedno.IntegrationTests/BackendFixture.cs`
- `backend/tests/Sedno.IntegrationTests/DeletionApiTests.cs`
- `backend/tests/Sedno.IntegrationTests/SessionRevocationTests.cs`
- `backend/tests/Sedno.UnitTests/AccountDeletionTests.cs`
- `backend/tests/Sedno.UnitTests/AuthenticationTests.cs`
- `backend/tests/Sedno.UnitTests/FirebaseAccountAccessTests.cs`
- `contracts/openapi.yaml`
- `mobile/lib/features/account/data/backend_session_gateway.dart`
- `mobile/lib/features/account/data/firebase_account_repository.dart`
- `mobile/lib/features/account/domain/account_repository.dart`
- `mobile/lib/features/account/presentation/account_screen.dart`
- `mobile/lib/features/shared/data/development_mocks.dart`
- `mobile/lib/features/simplification/data/http_simplification_repository.dart`
- `mobile/lib/features/subscription/data/backend_subscription_repository.dart`
- `mobile/test/features/account/data/account_deletion_test.dart`
- `mobile/test/features/account/data/backend_session_gateway_test.dart`
- `mobile/test/features/account/data/firebase_account_deletion_test.dart`
- `mobile/test/features/account/presentation/account_screen_test.dart`
