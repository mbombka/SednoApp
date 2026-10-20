# Wydanie 9 — poprawki subskrypcji

Podpisany pakiet: `mobile/build/releases/sedno-0.1.0-9.aab` (od katalogu głównego).

- Pakiet `xyz.sedno.app`, wersja `0.1.0`, kod wydania `9`.
- Adres serwera i konfiguracja płatności jak w [wydaniu 8](google_play_release_8.md).
- Panel subskrypcji pod przyciskami logowania na ekranie Konto.
- Przycisk „Zarządzaj subskrypcją w Google Play” (zarządzanie i anulowanie).
- Subskrypcja odświeżana przy starcie, powrocie do aplikacji i zmianie konta;
  bez odpytywania co 5 minut.
- Rozmiar: 70 324 154 bajty.
- SHA-256: `fc4d8f67bd67b51779e57b7281931ae4c1cd717d6be36a41bfc75bebd0081f6d`.
- Podpis zweryfikowany (`jarsigner`); certyfikat zgodny z wydaniem 8.
- Manifest: poprawny pakiet, kod wersji 9, brak `debuggable`.
- Architektury: `arm64-v8a`, `armeabi-v7a`, `x86_64`.
- Mapa R8: `mobile/build/releases/mapping-v9.txt`.
- Suma kontrolna: `mobile/build/releases/sedno-0.1.0-9.aab.sha256`.

Budowa zakończyła się sukcesem:

```sh
flutter build appbundle --release --build-number=9 --dart-define-from-file=config/billing.local.json
```

Poprawka utraty subskrypcji po ponownym zalogowaniu jest po stronie serwera
(subskrypcja ważna do daty wygaśnięcia z Google Play, bez 15-minutowego okna).
Działa dopiero po wdrożeniu backendu; sam AAB jej nie zawiera.

Pakiet nie został przesłany do Google Play. Następny numer wydania musi być wyższy niż 9.
