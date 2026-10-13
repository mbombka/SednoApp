# SimplifierApp

A minimal Flutter application for Android. It currently opens a single home screen.

## Project layout

- `lib/main.dart` starts the application.
- `lib/app/` contains the application widget and shared theme.
- `lib/features/home/presentation/` contains the home screen and its view model.
- `test/` mirrors the application structure for unit and widget tests.
- `android/` contains the generated Android host project.

Add new features under `lib/features/<feature>/`. Add data or domain layers when a feature needs them, and keep tests beside the matching path under `test/`.

## Commands

Install the Flutter SDK and Android SDK before running the app on Android.

```sh
flutter pub get
flutter analyze
flutter test
flutter run
```

The Android application ID is the Flutter template default, `com.example.simplifier_app`. Set an ID you own before publishing.
