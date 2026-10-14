# SimplifierApp

A minimal Flutter application for Android. It currently opens a single home screen.
The planned purpose is to simplify long text.

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
- `api/openapi.yaml` defines the future HTTPS backend contract. It has no
  photo or history upload endpoint.

Add new features under `lib/features/<feature>/`. Add data or domain layers when a feature needs them, and keep tests beside the matching path under `test/`.

Input length is measured in Unicode grapheme clusters using `characters`.
The maximum is 4,000 clusters; whitespace-only input is invalid. The mocks
take an injected clock and share a quota repository, so development can run
without an API. They are not connected to the current placeholder screen.

## Commands

Install the Flutter SDK and Android SDK before running the app on Android.

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

The Android application ID is the Flutter template default, `com.example.simplifier_app`. Set an ID you own before publishing.

The **Konto** tab supports Firebase Google and email/password sign-in when the
Android app is configured. Supply `FIREBASE_API_KEY`, `FIREBASE_APP_ID`,
`FIREBASE_PROJECT_ID`, `FIREBASE_SENDER_ID`, `GOOGLE_WEB_CLIENT_ID`,
`BACKEND_BASE_URL` (HTTPS), and `PLAY_CLOUD_PROJECT_NUMBER` as Flutter
`--dart-define` values. Enable Google and email/password in Firebase Auth,
register the app's Android signing certificate, and use the same Firebase
project ID on the backend. These IDs are app configuration, not model secrets.
The backend issues a separate revocable bearer after verifying the Firebase
ID token. The Kotlin host requests a standard Play Integrity token for guest
session creation. The development backend explicitly mocks that check; a
production release requires a registered Play app and server configuration.
The current Start screen still uses development simplification mocks and is
not yet connected to the backend session.

The camera and OCR flow needs a physical Android device check. Follow
[`mobile/docs/android_camera_ocr_manual_check.md`](mobile/docs/android_camera_ocr_manual_check.md).
