# Sedno — iOS native project

Status: source prepared on Linux. No iOS compilation, simulator run, signed IPA,
App Attest, Keychain backup restore, speech, camera or VoiceOver device acceptance
has been performed. Xcode, macOS, an iPhone and an Apple Developer account are
required for the remaining work. See the repository's `missing-information.md`.

The scaffold was generated in a separate temporary Flutter project and only its
`ios/` directory was copied here. Android and the existing Dart scaffold were
preserved. Deployment target is **iOS 15.5**, required by the installed ML Kit
text recognition dependency. The target is iPhone; iPad acceptance is not claimed.

## Configuration on a Mac

1. Install a compatible current Flutter SDK, Xcode and CocoaPods. Run
   `flutter doctor -v` and install Xcode command line tools/simulator components.
2. Register an iOS application in the **existing** Firebase project
   `sednoapp-79241`, using the real bundle identifier registered in Apple Developer.
   `xyz.sedno.app` is a candidate only, not a confirmed Apple registration.
3. Copy `Flutter/Sedno.example.xcconfig` to `Flutter/Sedno.local.xcconfig` and fill
   `SEDNO_BUNDLE_IDENTIFIER`, `DEVELOPMENT_TEAM` and `GOOGLE_REVERSED_CLIENT_ID`
   from the real Apple/Firebase configuration. No signing identity is invented
   or checked in. Keep signing certificates/profiles outside Git.
4. Enable Sign in with Apple and App Attest for the identifier and regenerate
   signing profiles. Review the Keychain Sharing capability and the generated
   signing profile on the owner's Mac. The shared Runner entitlements used by all
   configurations include `keychain-access-groups` with an empty array, as required
   by the installed `flutter_secure_storage` 11.2 documentation. No App Group or
   cross-application access group is configured. The native plugin only supplies
   `kSecAttrAccessGroup` when an explicit Dart `groupId` is provided; Sedno leaves
   that unset and uses its own application's default Keychain group. Verify
   secure preference write/read/delete across a signed restart before acceptance. Debug uses App Attest `development`; Release and Profile use
   `production`, including TestFlight. The backend must allow the matching
   Team ID, bundle ID and environment. Simulator lacks real App Attest and must
   not silently bypass production verification.
5. Supply the corresponding iOS Firebase/OAuth values through the Dart build
   configuration described in `../README.md`. The Google reversed client ID URL
   scheme comes from the local xcconfig. Do not copy Android Firebase app IDs.
6. In `mobile/`, run `flutter pub get`, then `cd ios && pod install`. Open
   `Runner.xcworkspace`. Flutter manages the generated Swift package when enabled;
   CocoaPods remains configured for dependencies requiring it (including ML Kit).
   Do not add duplicate native dependencies manually.
7. Run `flutter build ios --simulator --debug --dart-define-from-file=...` to check
   compilation, then native `RunnerTests` with Xcode on a configured simulator.
   Run signed builds on a real device, followed by `flutter build ipa --release
   --dart-define-from-file=...` only after configuration and security acceptance.

Keep Development and Production Dart configurations separate. A simulator build
proves compilation, not end-to-end production access. Billing remains explicitly
controlled by the separate Apple flag; configure real App Store product IDs
before enabling it. Do not publish purchases before sandbox acceptance.

## Platform contracts

- `sedno/installation`: `isFreshInstallation` -> bool and `markInitialized`.
  Before reading any secure preference, Dart calls the first method. A missing
  backup-excluded app-container marker clears the native history document and its
  own Keychain key, then returns true. Dart must await clearing its own secure
  preference namespace, then call `markInitialized`. A crash in between repeats
  cleanup at the next start. Updates preserve the marker. Marker corruption and
  protected-data/storage errors fail closed. This prevents Keychain credentials,
  AI consent and installation IDs surviving reinstall; it does not itself make
  a promise about server-side allowance across reinstalls.

- `pl.sedno/history`: `read` -> nullable string, `write` with a string argument,
  `clear`. Serial native queue, AES-256-GCM, versioned document, atomic write,
  complete file protection, backup exclusions on directory and file. The key is
  non-synchronising Keychain `WhenUnlockedThisDeviceOnly`. `CORRUPT` makes the
  Dart repository clear the document; storage/locked-device errors remain
  `STORAGE` and must not silently erase history. Retention is enforced in Dart.
- `sedno/speech`: `listen` with `language`, nullable string result; `cancel`.
  Both speech and microphone permissions are required. Recognition sets
  `requiresOnDeviceRecognition = true` and checks capability; unsupported
  languages fail without network fallback. No audio file is created. The native
  monotonic timer ends after 1.5 seconds of silence following recognised speech
  or 60 seconds total, independently of wall-clock changes. RMS and partial-result updates estimate silence and require
  real microphone acceptance in quiet/noisy conditions.
- `sedno/text-playback`: `speak` with `text` and `language`, `stop`. Only an
  installed matching-language voice is selected. The `speak` Future remains pending
  until its utterance finishes or is stopped, preserving the active Stop control;
  stale delegate callbacks cannot complete a newer utterance. Speech and playback stop in
  background, on audio interruption and when headphones disconnect. No automatic
  resume. Test voice availability and operation in flight mode for every locale.
- `sedno/app_attest`: `isSupported`, `generateKey`, `attestKey` and
  `generateAssertion`. The last two require `keyId` and `clientDataHash` (32-byte
  SHA-256 digest encoded base64url); return standard padded base64 attestation or
  assertion. `invalid_key` distinguishes keys that require controlled recovery.
  Dart/backend own challenge construction, replay protection and key ID storage.
  Native code does not log request contents or proofs.

## Required acceptance

- Test history expiration on startup/resume/read, deletion/logout, concurrent
  writes, locked device, corrupt file and missing key. Restore a backup to a
  second device and confirm no history/key migration or iCloud synchronisation.
- Reinstall and update the app; validate installation/session and App Attest key
  recovery together. Interrupt first launch between secure preference cleanup
  and marker commit; confirm next start repeats cleanup. Try a locked-device
  launch and corrupt marker; startup must fail without silently reusing old state. Keychain items can survive deletion of an app: do not assume
  reinstall clears identity or grants a new allowance.
- Test camera rotation/crop/OCR and temporary-file removal on success, failure,
  cancel and background. Permissions do not request Photo Library access because
  this flow uses the camera and private temporary files.
- Speech/voices: test `pl-PL`, `en-GB`, `en-US`, `fr-FR`, `de-DE`, `it-IT`,
  `es-ES`, `pt-PT`, `sk-SK`, `cs-CZ`, `ro-RO`, `nb-NO`, `sv-SE` offline on real
  devices; no language is marked accepted from API support checks alone.
- Review permission translations, system language fallback to Polish, large text,
  VoiceOver, interruption handling and 1.5/60-second timing.
- Review all SDK privacy manifests and App Store privacy answers against actual
  behaviour. The app manifest declares the file timestamp reason for app-private
  file handling and the system boot time reason `35F9.1` for monotonic local speech
  timers; uptime values remain on device. It does not replace the store privacy
  questionnaire or policy.
  Confirm encryption export classification before submitting the archive.

References: [Flutter iOS deployment](https://docs.flutter.dev/deployment/ios),
[ML Kit package iOS requirements](https://pub.dev/packages/google_mlkit_text_recognition),
[App Attest](https://developer.apple.com/documentation/devicecheck/dcappattestservice),
[on-device speech](https://developer.apple.com/documentation/speech/sfspeechrecognizer/supportsondevicerecognition),
[required-reason APIs](https://developer.apple.com/documentation/bundleresources/app-privacy-configuration/nsprivacyaccessedapitypes/nsprivacyaccessedapitype).
