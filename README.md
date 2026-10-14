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

The Android application ID is the development placeholder `com.example.sedno_app`. Set an ID you own before publishing.
This ID replaces the previous development ID. Android treats it as a separate
installation, so register the new package and signing certificate in Firebase
and Google Play before testing sign-in or Play Integrity. Data stored under the
previous package ID is not available to the new installation.

Guest simplification needs `BACKEND_BASE_URL` (HTTPS) and, in production,
`PLAY_CLOUD_PROJECT_NUMBER`. The **Konto** tab supports Firebase Google and
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
