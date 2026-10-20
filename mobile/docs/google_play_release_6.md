# Wydanie 6 — 20.10.2026

Nazwa wersji: `0.1.0`, numer wydania: `6`, pakiet: `xyz.sedno.app`.

## Zmiany

- Konto domyślnie otwiera logowanie Google lub e-mail/hasło.
- Link „Nie masz konta? Utwórz konto” otwiera osobny formularz rejestracji.
- Rejestracja wymaga wpisania hasła dwukrotnie i sprawdza jego zgodność przed
  wywołaniem Firebase. Hasło rejestracyjne musi mieć co najmniej 6 znaków.
- Każde pole hasła ma niezależny podgląd z polską etykietą dla TalkBack oraz
  polem dotyku co najmniej 48 dp. Zmiana formularza czyści i ponownie ukrywa hasła.
- „Nie pamiętam hasła” otwiera formularz wysyłania polskiej wiadomości Firebase.
  Komunikat po wysłaniu nie ujawnia, czy adres ma konto.
- Nowa ikona z nawiasami i kropką jest używana jako ikona klasyczna, adaptacyjna,
  tematyczna oraz na ekranie uruchamiania.
- Użyto dostarczonego `docs/Content/sedno-icon.svg` i wariantu
  `docs/Content/sedno-icon-A-512.png`. Zasoby odtwarza
  `python3 tools/generate_android_icons.py` (wymaga Pillow).

## Sprawdzenie

- `dart format --output=none --set-exit-if-changed lib test`: bez zmian.
- `flutter analyze`: brak uwag.
- `flutter test`: wszystkie 148 testów przeszły.
- Testy obejmują oddzielne formularze, podgląd obu haseł, wyczyszczenie podglądu
  po zmianie formularza, brak rejestracji przy niezgodnych lub brakujących hasłach,
  odzyskiwanie hasła, polski język wysyłki, neutralny komunikat dla brakującego
  konta oraz formularz przy dużej czcionce na ekranie o szerokości 320 dp.
- Sprawdzono strukturę XML zasobów i wymiary pięciu ikon PNG. Ikonę PNG obejrzano.
- Zmiany nie wymagają aktualizacji backendu; nie zmieniano kodu serwera w tym wydaniu.

Dostarczenie prawdziwej wiadomości resetującej hasło oraz wygląd ikon z maską
programu uruchamiającego i ekranu startowego wymagają sprawdzenia na telefonie.

## Budowa

```sh
flutter build appbundle --release --build-number=6 --dart-define-from-file=config/firebase.local.json
```

## Pliki

- `mobile/lib/features/account/presentation/account_screen.dart` i nowy `password_field.dart`.
- `mobile/lib/features/account/domain/account_repository.dart`.
- `mobile/lib/features/account/data/firebase_account_repository.dart`.
- `mobile/lib/features/shared/data/development_mocks.dart`.
- `mobile/test/features/account/presentation/account_screen_test.dart`.
- `mobile/test/features/account/data/email_verification_test.dart`.
- `mobile/android/app/src/main/res/drawable/ic_launcher_foreground.xml`, `ic_sedno_splash.xml`.
- Pięć `mobile/android/app/src/main/res/mipmap-*/ic_launcher.png`.
- Nowy `tools/generate_android_icons.py`.
- `mobile/pubspec.yaml`, `mobile/README.md`, `mobile/docs/google_play_internal_test.md` i ten raport.

Pozostałe zastane zmiany w repozytorium zachowano.

## Opis zmian do Play Console

> Rozdzieliliśmy logowanie i tworzenie konta. Dodaliśmy podgląd hasła,
> powtórzenie hasła przy rejestracji oraz odzyskiwanie dostępu do konta.
> Zaktualizowaliśmy ikonę aplikacji.

## Gotowy artefakt

Budowa zakończyła się sukcesem. Pakiet do przesłania:
`mobile/build/releases/sedno-0.1.0-6.aab` (ścieżka od katalogu głównego).

- Rozmiar: 70000639 bajtów.
- SHA-256: `3e7d45f3e36facaac11b3ae298c8e1ce9e69e5735eb714e1d85f20cef0cd72f5`.
- Wersja sprawdzona bezpośrednio w manifeście AAB: `0.1.0`, kod `6`.
- Pakiet `xyz.sedno.app`, brak włączonego `debuggable`.
- Podpis sprawdzony dla wszystkich wpisów zawartości; certyfikat zgodny z istniejącym
  `android/keystore/sedno-upload-certificate.pem`. Brak powielonych wpisów ZIP.
- Pięć ikon PNG w AAB porównano piksel po pikselu z nowymi zasobami. Pakiet zawiera
  także oba zaktualizowane drawable wektorowe.
- Obsługiwane architektury: `arm64-v8a`, `armeabi-v7a`, `x86_64`.
- Mapa R8: `mobile/build/releases/mapping-v6.txt`.
- Suma kontrolna: `mobile/build/releases/sedno-0.1.0-6.aab.sha256`.

Podczas budowy pluginy Firebase zgłosiły ostrzeżenie o przyszłym wsparciu
Built-in Kotlin; nie zablokowało ono budowy. Nie przesyłano pakietu do Google Play.
