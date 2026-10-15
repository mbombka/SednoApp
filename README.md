# SednoApp

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

The Android application ID and namespace are `io.github.mbombka.sedno`.
Register this exact Android package in Firebase and Google Play, together with
its signing certificate fingerprints. A Firebase Android registration for the
previous package cannot be reused: add a new Android app in the same Firebase
project, update `FIREBASE_APP_ID` and any other changed Firebase/OAuth configuration,
and register debug and Play App Signing certificate fingerprints as appropriate.
Set backend `PlayIntegrity__PackageName` and `Billing__PackageName` to
`io.github.mbombka.sedno` for their corresponding production integrations.
The display name remains **Sedno**. Android treats a different application ID as
a separate installation; local history and credentials from older packages are
not automatically transferred. External console configuration is a separate
setup step and is not changed by editing this repository.

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
server quota. Without backend configuration, submission is unavailable.

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

The backend includes opt-in adapters for a saved OpenAI Agent and direct GPT-6 Luna calls. They remain disabled by
default in production and uses a mock in Development until explicitly configured.
See [server setup](backend/README.md#openai-simplification) and the
[Polish acceptance procedure](docs/model-acceptance.pl.md). The API key stays on
the server. Account access, live quality and real request cost require verification.
For the saved agent configured in OpenAI Platform, follow
[Agents API setup](backend/README.md#saved-openai-agent) using `OpenAI:ApiKey` and
`OpenAI:AgentId`. The prompt and model are managed in the saved agent.
