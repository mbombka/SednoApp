# SimplifierApp / Simplyfi_it

## Purpose
An Android application built with Flutter/Dart that simplifies Polish
texts, primarily for people who are hard of hearing or have cognitive
difficulties.
Project name: SimplifierApp. Display name: Simplyfi_it.
All user-facing content must be in Polish.

## Existing Code
Extend the existing scaffold; do not regenerate the project.
Preserve the lib/app and lib/features structure and corresponding tests.
Read README, existing code, and current dependencies before making changes.

## Features
- Top navigation tabs: Start, Historia, Konto. No login required to start.
- Input: typing/pasting or camera → cropping → on-device OCR → manual editing.
  Maximum: 4,000 characters. Reject empty or whitespace-only input.
- Photos must never leave the device.
- Simplification through the backend; initially use a mock model.
- Full-screen result: Kopiuj, Pokaż oryginał, Nowy tekst.
- Encrypted, local-only history with manual deletion and 7-day expiration.
  Never display expired entries; delete them on reads, startup, and resume.
  Display the retention notice in Historia. Exclude history from backups.
- Free tier: 2 simplifications per day, including guest users.
- Subscription: PLN 9.99/month, 400 total simplifications per day.
- Limits reset at 00:00 UTC according to server time.
- Free-tier counter: hidden at 2 remaining; at 1, show the remaining
  allowance and time until reset; at 0, block submission and show
  reset information and the subscription offer.
- Google/email authentication; billing through Google Play.
- Account and data deletion; signing out clears local history.

## Architecture
Flutter: feature-first, views → ViewModels → repositories → services.
Use dependency injection and extend existing architectural choices.
Backend: C#, ASP.NET Core, a supported .NET LTS release, PostgreSQL.
The backend stores secrets and verifies identity, subscriptions, and limits.
Use an OpenAPI contract and separate development/production configurations.
Mocks must be explicit and unavailable in production configurations.

## Security and Privacy
Use HTTPS. Never include the model API key in the application.
Never log input texts, photos, tokens, or simplified results.
The backend must not persist simplification content.
Installation identifiers are pseudonymous, not anonymous.
Reinstallation may bypass guest limits; Play Integrity mitigates abuse.
Signing in must not grant a fresh free allowance.
Before the first submission, explain that text is processed by an AI provider.
The privacy policy requires controller details, providers, legal bases,
and retention rules. Do not make unsupported legal compliance claims.

## Accessibility
Simple Polish, light backgrounds, dark navy text, blue buttons.
WCAG AA contrast, touch targets ≥48 dp, text scaling,
TalkBack support, and labels for icons.
Display a warning that AI simplification may contain errors.

## Testing and Definition of Done
Unit tests for logic, widget tests for UI, integration tests for the backend.
Mock time, network, OCR, the model, authentication, and billing.
Run dart format, flutter analyze, flutter test, and dotnet test
for the relevant components.
Report changed files, test results, and environment limitations.
Never claim an APK was built unless the build actually ran successfully.