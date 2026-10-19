# SednoApp

Strona aplikacji: [sedno.xyz](https://sedno.xyz).

A Flutter application for Android that simplifies Polish text through the backend.

## Project layout

- `lib/main.dart` starts the application.
- `lib/app/` contains the application widget and shared theme.
- `lib/features/home/presentation/` contains the home screen and its view model.
- `test/` mirrors the application structure for unit and widget tests.
- `android/` contains the generated Android host project.
- `lib/features/*/domain/` contains validated models and repository contracts.
- `lib/features/photo/` contains local camera capture, cropping, Polish OCR, and
  temporary photo cleanup. The recognized text is editable on **Start**.
- `lib/features/shared/data/development_mocks.dart` contains in-memory development
  repositories. Their constructors reject production (`dart.vm.product`) builds.
- `contracts/openapi.yaml` defines the HTTPS backend contract. It has no
  photo or history upload endpoint.

Add new features under `lib/features/<feature>/`. Add data or domain layers when a feature needs them, and keep tests beside the matching path under `test/`.

Input length is measured in Unicode grapheme clusters using `characters`.
The maximum is 4,000 clusters; whitespace-only input is invalid. Development
mocks take an injected clock and are used only when explicitly injected.

## Commands

Install the Flutter SDK and Android SDK before running the app on Android.

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

The Android application ID and namespace are `xyz.sedno.app`, based on the
reverse domain `sedno.xyz` with an `app` suffix.
Register this exact Android package in Firebase and Google Play, together with
its signing certificate fingerprints. A Firebase Android registration for the
previous package cannot be reused: add a new Android app in the same Firebase
project, update `FIREBASE_APP_ID` and any other changed Firebase/OAuth configuration,
and register debug and Play App Signing certificate fingerprints as appropriate.
Set backend `PlayIntegrity__PackageName` and `Billing__PackageName` to
`xyz.sedno.app` for their corresponding production integrations.
The display name remains **Sedno**. Android treats a different application ID as
a separate installation; local history and credentials from older packages are
not automatically transferred. External console configuration is a separate
setup step and is not changed by editing this repository.

For local Android Studio emulator testing, run the Development backend on port
5000 and set **Run → Edit Configurations → Flutter → Additional run args** to
`--dart-define=BACKEND_BASE_URL=http://10.0.2.2:5000`. Stop and run the app again;
hot reload does not change compile-time configuration. The Android debug variant
allows HTTP only to `10.0.2.2`, `127.0.0.1` and `localhost`. This exception is not
included in release builds. Without `BACKEND_BASE_URL`, submission is unavailable.
Google/Firebase sign-in configuration is not required for local guest testing.

Guest simplification needs `BACKEND_BASE_URL` (HTTPS) and, in production,
`PLAY_CLOUD_PROJECT_NUMBER`. The **Konto** screen (in the user menu) supports Firebase Google and
email/password sign-in when the Android app is configured. For that, also
supply `FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_PROJECT_ID`,
`FIREBASE_SENDER_ID`, and `GOOGLE_WEB_CLIENT_ID` as Flutter `--dart-define`
values. Enable Google and email/password in Firebase Auth,
register the app's Android signing certificate, and use the same Firebase
project ID on the backend. These IDs are app configuration, not model secrets.
The backend issues a separate revocable bearer after verifying the Firebase
ID token. The Kotlin host requests a standard Play Integrity token for guest
session creation. The development backend explicitly mocks that check; a
production release requires a registered Play app and server configuration.
The Start screen uses the backend session for simplification and displays the
server quota. The free tier includes 5 simplifications per UTC day, including
guests. The remaining allowance warning appears only at 1 remaining; at 0,
submission is blocked. Limits reset at 00:00 UTC according to server time.
Without backend configuration, submission is unavailable.

The camera and OCR flow needs a physical Android device check. Follow
[`mobile/docs/android_camera_ocr_manual_check.md`](mobile/docs/android_camera_ocr_manual_check.md).

Monthly subscriptions use Google Play Billing and require a signed-in Sedno
account for purchase/restore. Set `PLAY_SUBSCRIPTION_PRODUCT_ID` to the product
configured on the backend. The app shows Play's localized price; the backend
verifies and acknowledges purchases and receives authenticated RTDN pushes.
See [backend configuration](backend/README.md#google-play-subscriptions) and the
[Google Play sandbox procedure](mobile/docs/google_play_subscription_sandbox.md).

The Start screen has a rounded text editor and circular simplification/camera
buttons. The user icon opens a full-screen panel with rounded navigation sections for
Start, Konto and Historia, plus access to privacy information. AI processing is explained
in a confirmation dialog before the first submission in a screen session; quota
and reset details appear on submission when the remaining allowance is low.

## Real AI integration

The backend uses OpenAI Responses API with `gpt-6-luna`, `reasoning.effort=none`,
`service_tier=default`, `store=false`, 4096 output tokens and an eight-second timeout.
Configure the server-only `OpenAI:ApiKey` before starting the default `openai` mode.
Development mocks require an explicit `Model:Provider=mock`; production rejects mocks.

The accepted prompt is versioned in
[`backend/src/Sedno.Infrastructure/Prompts/simplify.pl.txt`](backend/src/Sedno.Infrastructure/Prompts/simplify.pl.txt)
and shared with the [model benchmark](backend/tools/Sedno.ModelBenchmark/README.md).
The benchmark retains agent comparisons and historical timing/quality reports;
agent code is not part of the application backend.
See [server setup](backend/README.md#openai-simplification), including the migration
cleanup procedure, and [acceptance checks](docs/model-acceptance.pl.md).
The Flutter API contract is unchanged; photos stay on the device.

## Informacje o aplikacji i prywatności

Menu użytkownika → **O aplikacji** opisuje Sedno, limity, ostrzeżenie AI i kontakt.
Ekran **Prywatność i dane** zawiera pełne zasady, dane administratora, prawa,
retencję i sposób usunięcia konta. Adresy informacji:

- https://sedno.xyz/#prywatnosc — działające podsumowanie; pełna polityka jest w aplikacji.
- https://sedno.xyz/prywatnosc/ — publiczna polityka, odpowiedź HTTPS 200 sprawdzona 16.10.2026.
- https://sedno.xyz/usun-konto/ — publiczna instrukcja zgłoszeń, odpowiedź HTTPS 200 sprawdzona 16.10.2026.

Dokumenty i adresy mają jedno źródło: `docs/privacy-policy.pl.json`. Po edycji:

```sh
python3 tools/generate_privacy_policy.py
python3 tools/generate_privacy_policy.py --check
```

Generator wymaga Pythona 3 i `dart` w PATH. Tworzy
[politykę Markdown](docs/privacy-policy.pl.md), treść Flutter, wspólne adresy i pliki
HTML `docs/public/prywatnosc/index.html` oraz `docs/public/usun-konto/index.html`.
Backend osadza politykę w assembly i udostępnia `/prywatnosc` bez logowania.
Adres strony głównej nie jest adresem API. Przygotowanie plików nie publikuje ich
na domenie. Sekcja `#prywatnosc` jest częścią istniejącej strony głównej.
Pełny dokument HTML można włączyć do tej sekcji lub udostępnić z niej odnośnik.
Podczas kontroli zadania 14 obie strony odpowiadały przez HTTPS; przed zgłoszeniem
w Play Console trzeba sprawdzić ich zgodność z bieżącą konfiguracją usługi.

[Przyjęte zasady i procedura wdrożenia](docs/privacy-operations-plan.pl.md)
odróżniają działający kod od wybranego hostingu, retencji logów/kopii/poczty
oraz prac wymaganych przed produkcją. Nie utworzono zasobów Google ani nie zmieniono
umów lub kont dostawców. Dawna polityka robocza pozostaje archiwum.

## Firebase / Cloud Run

Od 19.10.2026 API działa pod **https://sednoapp-79241-api.web.app**.
Backend C# w Cloud Run korzysta z PostgreSQL w Warszawie oraz Secret Manager.
Pierwszy etap ma wyłączone płatności Google Play. Test na telefonie wymaga
powiązania projektu z Play Integrity i konfiguracji aplikacji w kanale testowym.

[Instrukcja wdrożenia i lokalne profile Development](backend/deploy/firebase/README.pl.md)
· [Raport i pozostałe ograniczenia](docs/task-14-deployment.pl.md).
