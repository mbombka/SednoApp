# SednoApp / Sedno

## Purpose
An Android application built with Flutter/Dart that simplifies Polish
texts, primarily for people who are hard of hearing or have cognitive
difficulties.
Project name: SednoApp. Display name: Sedno.
All user-facing content must be in Polish.

## Existing Code
Extend the existing scaffold; do not regenerate the project.
Preserve the lib/app and lib/features structure and corresponding tests.
Read README, existing code, and current dependencies before making changes.

## Features
- Navigation through the user menu: Start, Historia, Konto, O aplikacji,
  Prywatność i dane. No login required to start.
- Input: typing/pasting or camera → cropping → on-device OCR.
  The crop screen's Uprość button submits recognized text directly; after a
  validation error, failure or cancellation it stays in the editor for manual editing.
  Maximum: 4,000 characters. Reject empty or whitespace-only input.
- Photos must never leave the device.
- Simplification through the backend using OpenAI Responses API.
  Production settings: gpt-6-luna, reasoning.effort=none, service_tier=default,
  store=false, no conversation/previous_response_id, 4096 output tokens, 8 s timeout.
  Mock models require explicit Development configuration.
- Results replace the text in the same editable field. The result heading
  (Uproszczony tekst / Poprawiony tekst) and system Back restore the original
  from the latest successful operation. Copying uses the system text-selection
  menu; no separate Kopiuj button.
- Changing Uprość/Popraw, pressing the eraser, or starting microphone/camera input
  clears the editor and the saved original. Cancelled/failed capture leaves the
  editor empty; recognized text remains editable after a submission error or cancellation.
  Place the eraser to the right of the mode switch, with the same button style
  and touch-target size; use a slightly smaller 28 dp eraser icon.
- Encrypted, local-only history with manual deletion and 7-day expiration.
  Never display expired entries; delete them on reads, startup, and resume.
  Display the retention notice in Historia. Exclude history from backups.
- Free tier: 5 simplifications per day, including guest users.
- Subscription: PLN 9.99/month, 400 total simplifications per day.
  Google Play product ID: `subscription_full`; base plan ID: `monthly`.
  The app selects the regular auto-renewing monthly base plan and displays the
  price returned by Google Play. Enable billing explicitly for tests; complete
  purchase testing before public rollout. Use the existing `sedno-api` service,
  its existing service account and `(default)` database for Google Play tests.
  Do not provision a separate billing backend or database.
- Limits reset at 00:00 UTC according to server time.
- Free-tier counter: hidden at 2–5 remaining; at 1, show the remaining
  allowance and time until reset; at 0, block submission and show
  reset information and the subscription offer.
- Google/email authentication; billing through Google Play.
- Account and data deletion; signing out clears local history.
  Account deletion by email is operational, confirmed by the owner on 20.10.2026.

## Architecture
Flutter: feature-first, views → ViewModels → repositories → services.
Use dependency injection and extend existing architectural choices.
Backend: C#, ASP.NET Core, a supported .NET LTS release, Cloud Firestore Standard (Native mode).
Firestore is accessed only by the backend with IAM; mobile clients have no database access.
Daily quota reservations and identity linking must remain transactional.
The emulator is Development-only; metadata cleanup runs as a scheduled job.
The backend stores secrets and verifies identity, subscriptions, and limits.
Use an OpenAPI contract and separate development/production configurations.
Mocks must be explicit and unavailable in production configurations.

## Model implementation and benchmarks
- The shared Git-versioned prompt is `backend/src/Sedno.Infrastructure/Prompts/simplify.pl.txt`.
  Embed it in the Infrastructure assembly; application and benchmarks use `SimplificationPrompt`.
  Keep the accepted prompt unchanged during migration; evaluate prompt changes separately.
- `ResponsesClient` owns HTTP, validation and content-free metrics. Production
  `OpenAiModelProvider` restricts settings; experimental models belong only in benchmarks.
- Use `OpenAI:ApiKey` on the server. `OpenAI:AgentId` belongs only to benchmarks.
- Agent adapters, streaming and session cleanup live in `backend/tools/Sedno.ModelBenchmark/Agents`.
  The application must not reference the benchmark project or register an agent provider.
- Preserve benchmark tools and historical reports. `--text-report` may explicitly
  export built-in synthetic fixtures and results for review; never export application traffic.
- Before retiring an agent deployment, stop its requests and run the benchmark with
  `--live --cleanup-agent`. Review legacy untagged sessions separately.

## Security and Privacy
The application is intended for ages 13+. Users aged 13–17 should use it
with permission from a parent or guardian. It does not collect dates of birth.
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
