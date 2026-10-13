# SimplifierApp agent notes

## Project intent and current state

- SimplifierApp is a Flutter app targeting Android. The Dart package name is `simplifier_app`.
- The app currently has one home screen with a welcome message. Its planned purpose is to simplify long text; that feature has not been implemented.
- The Android application ID is the Flutter template placeholder `com.example.simplifier_app`. Replace it with an ID the owner controls before publishing.

## Architecture decisions

- `lib/main.dart` starts the app; `lib/app/` owns the root `MaterialApp` and shared theme.
- Put feature code under `lib/features/<feature>/`. The existing home feature has a presentation screen and a small view model.
- Add domain and data layers only when a feature needs them. No state management package, backend, or persistence approach has been chosen yet.
- Use Material 3. Keep business logic outside widgets when it becomes necessary to test it independently.
- `test/` mirrors relevant `lib/` paths. `flutter_test` provides unit and widget tests.

## Working in this repository

- Keep the displayed app name `SimplifierApp` and the Dart package name `simplifier_app` distinct.
- Follow the existing Dart formatting and `flutter_lints` rules. For code changes, run `dart format`, `flutter analyze`, and affected `flutter test` cases.
- Update this file when a durable project decision changes. Keep user setup and usage instructions in `README.md`; avoid duplicating them here.
