# Potwierdzanie adresu e-mail — 19.10.2026

Dodano potwierdzanie adresu przy rejestracji e-mail/hasło. Google zachowuje
poprzedni przepływ. Przed potwierdzeniem aplikacja korzysta z sesji gościa;
nie łączy jej z kontem i nie zeruje limitu.

## Zachowanie aplikacji

Po utworzeniu użytkownika Firebase aplikacja wywołuje `sendEmailVerification`
z językiem `pl`. Pokazuje ekran „Sprawdź pocztę” z instrukcją:

> Aby dokończyć tworzenie konta, kliknij link w wiadomości od Sedna.
> Sprawdź też folder Spam. Potem wróć tutaj i wybierz „Sprawdź potwierdzenie”.

Po powrocie z poczty lub naciśnięciu przycisku aplikacja odświeża użytkownika,
sprawdza potwierdzenie i wymusza nowy token przed połączeniem konta z backendem.
Ponowne wysłanie ma 60-sekundową przerwę w interfejsie; dodatkowe ograniczenia
zapewnia Firebase. Awaria wysyłania zachowuje stan oczekiwania i możliwość
ponowienia bez ponownego tworzenia konta. Stan oczekiwania działa także po
ponownym uruchomieniu lub zalogowaniu do wcześniej utworzonego konta.

Dodano konkretne polskie komunikaty dla słabego hasła, nieprawidłowego lub
zajętego adresu, błędnych danych logowania, braku sieci i nadmiernej liczby prób.
Hasło jest czyszczone po pomyślnej operacji i przy przejściu do oczekiwania.

## Serwer i konfiguracja poczty

`/v1/auth/sessions` zwraca HTTP 403 `email_not_verified` dla tokenu z dostawcą
`password`, jeśli podpisany token nie zawiera `email_verified=true`. Kontrola
jest również w `GuestStore`. Odrzucenie nie zużywa sesji gościa. Nie zmieniono
kontroli podpisu, projektu ani ważności tokenu. Istniejące sesje backendu
pozostają ważne do wylogowania lub wygaśnięcia; nowa aplikacja unieważnia starą
lokalną sesję konta, jeśli Firebase nadal wskazuje niepotwierdzony adres.

Domyślny język Firebase Authentication ustawiono na `pl`. Próby ustawienia własnej
treści, tematu „Potwierdź adres e-mail w Sednie” i nadawcy „Sedno” zostały odrzucone
przez Firebase (`EMAIL_TEMPLATE_UPDATE_NOT_ALLOWED`). W użyciu pozostaje polska
wiadomość systemowa Firebase, a własna instrukcja jest w aplikacji. Nie dodano
zewnętrznego operatora poczty. Podczas konfiguracji nie wysyłano prawdziwych wiadomości.

## Wdrożenie i artefakt

- Cloud Build: `466bbd80-cf79-4094-a5a9-f457848d5818`, `SUCCESS`.
- Obraz: `europe-central2-docker.pkg.dev/sednoapp-79241/backend/api@sha256:63f0b24fc6d419459130e87b61e0fb011f9248fedc6e5cad386942262c3d3d56`.
- Cloud Run: `sedno-api-00006-j9x`, ruch 100%.
- Firebase Hosting: `05752b0cf67738ff`, przypięcie do nowej rewizji potwierdzone.
- Publiczne API: `https://sednoapp-79241-api.web.app`.
- Zmienne środowiska API, odwołania do sekretów, konto usługi i zasoby bez zmian.
- Cleanup pozostał na poprzednim obrazie; nie zmieniano reguł ani danych Firestore.
- Zbudowano `mobile/build/app/outputs/flutter-apk/app-debug.apk` (228949270 bajtów).
- SHA-256 APK: `5ff18905014e762fc2e9af4e1b2024ad5fb81a1dd62561206e093fe1e2937508`.

Telefon wymaga aktualizacji aplikacji do nowego APK. Starsza aplikacja nie ma
ekranu potwierdzania; nowe niepotwierdzone konta e-mail są już blokowane na serwerze.

## Weryfikacja

- `dart format --output=none --set-exit-if-changed lib test`: bez zmian.
- `flutter analyze`: brak uwag.
- `flutter test`: 138 testów przeszło; po uzupełnieniu obsługi awarii wysyłania
  ponownie sprawdzono 24 testy funkcji konta — wszystkie przeszły.
- Backend: 90 testów jednostkowych, 58 integracyjnych i 38 benchmarkowych przeszło.
- Testy obejmują podpisany znacznik potwierdzenia, odmowę przy braku potwierdzenia,
  dalszą dostępność sesji gościa, zachowanie wykorzystania limitu po połączeniu,
  polski język wysyłki, ponowienie po błędzie, odczyt stanu oczekiwania,
  odświeżenie tokenu i przerwę przed ponowną wysyłką.
- `flutter build apk --debug --dart-define-from-file=config/firebase.local.json`: sukces.
  Narzędzia Android zgłosiły ostrzeżenia o wersji XML SDK i przyszłej zgodności
  pluginów Firebase z Built-in Kotlin; nie zablokowały budowy.
- Po wdrożeniu `/health/live` i `/health/ready`: HTTP 200. Brak tokenu Integrity
  nadal daje HTTP 403 `integrity_failed`. Sprawdzenie gotowości nie wysyła e-maili.

Dostarczenie wiadomości oraz kliknięcie prawdziwego linku wymagają próby na
telefonie. Testy automatyczne używają atrap poczty i uwierzytelniania.

## Pliki zmienione w tej funkcji

- `mobile/lib/features/account/domain/account.dart`, `account_repository.dart`.
- `mobile/lib/features/account/data/firebase_account_repository.dart`.
- `mobile/lib/features/account/presentation/account_screen.dart`.
- `mobile/lib/features/shared/data/development_mocks.dart`.
- `mobile/test/features/account/data/email_verification_test.dart`.
- `mobile/test/features/account/presentation/account_screen_test.dart`.
- `backend/src/Sedno.Application/Contracts.cs`.
- `backend/src/Sedno.Infrastructure/FirebaseTokenVerifier.cs`, `GuestStore.cs`.
- `backend/src/Sedno.Api/Program.cs`.
- `backend/tests/Sedno.UnitTests/AuthenticationTests.cs`.
- `backend/tests/Sedno.IntegrationTests/ApiTests.cs`, `BackendFixture.cs`.
- `contracts/openapi.yaml`.
- `backend/deploy/firebase/auth/email-verification.pl.json`.
- `mobile/README.md`, `backend/README.md` i ten raport.

Pozostałe zastane zmiany w obszarze aplikacji i wcześniejszej diagnostyki Integrity
zostały zachowane.
