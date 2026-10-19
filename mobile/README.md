# Aplikacja Android

Potrzebujesz Fluttera z Dartem zgodnym z [pubspec.yaml](pubspec.yaml), Android SDK
oraz emulatora lub telefonu. Wszystkie polecenia poniżej wykonuj w `mobile/`.

## Uruchomienie

Lokalny plik `config/firebase.local.json` zawiera adres serwera i konfigurację
Firebase oraz Google. Jest pomijany przez Git; po nowym pobraniu projektu trzeba
go przygotować z ustawień tego samego projektu Firebase.

```sh
flutter pub get
flutter run --dart-define-from-file=config/firebase.local.json
```

Potrzebne pola: `BACKEND_BASE_URL`, `PLAY_CLOUD_PROJECT_NUMBER`,
`FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_PROJECT_ID`, `FIREBASE_SENDER_ID`
i `GOOGLE_WEB_CLIENT_ID`. To konfiguracja aplikacji; klucz OpenAI pozostaje na serwerze.
Flutter korzysta z `FirebaseOptions`; nie wymaga dodatkowego pluginu Google Services
ani kopiowania `google-services.json` do Androida.

Pakiet: `xyz.sedno.app`. Projekt: `sednoapp-79241`, numer `1003558402460`.
Adres serwera: `https://sednoapp-79241-api.web.app`. Google i e-mail/hasło są
włączone w Firebase. Test na telefonie wymaga również certyfikatów podpisu
w Firebase i wersji rozpoznawanej przez Play Integrity.

## Serwer lokalny

Uruchom [backend w trybie demonstracyjnym](../backend/README.md), a następnie
skieruj emulator Androida na port 5000:

```sh
flutter run --dart-define-from-file=config/firebase.local.json \
  --dart-define=BACKEND_BASE_URL=http://10.0.2.2:5000
```

Po zmianie konfiguracji zatrzymaj aplikację i uruchom ją ponownie.
Lokalne testy gościa nie wymagają logowania Firebase. HTTP jest dopuszczone tylko
w wersji debug dla adresów lokalnych; wydanie produkcyjne wymaga HTTPS.

## Testy i plik APK

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug --dart-define-from-file=config/firebase.local.json
```

Plik powstaje w `build/app/outputs/flutter-apk/app-debug.apk`.
To wersja testowa. Publikacja w Google Play wymaga podpisanego wydania AAB.
[Pierwsze wydanie w testach wewnętrznych](docs/google_play_internal_test.md).

Podpis wydania jest w lokalnych `android/key.properties` i
`android/keystore/sedno-upload.jks`. Zachowaj ich zabezpieczoną kopię poza projektem.
Po pobraniu projektu odtwórz je z kopii; układ ustawień pokazuje
[key.properties.example](android/key.properties.example). Bez klucza release nie zbuduje się.

Próby na urządzeniu: [aparat i OCR](docs/android_camera_ocr_manual_check.md),
[subskrypcje](docs/google_play_subscription_sandbox.md) i
[dostępność](../docs/model-acceptance.pl.md#dostępność).

Aparat działa wewnątrz Sedna: **Zrób zdjęcie → Zaznacz tekst → Odczytaj**.
Ramka początkowo obejmuje całe zdjęcie. Można przesunąć jej rogi, aby odczytać
fragment. Zdjęcie pozostaje nieruchome; nie ma dodatkowego zatwierdzania zdjęcia
ani wyboru proporcji. Zdjęcia i wycinanie fragmentów pozostają na urządzeniu.

Kod jest w `lib/app/` i `lib/features/`; testy mają odpowiadający układ w `test/`.
Aktualny opis komunikacji z serwerem: [kontrakt API](../contracts/openapi.yaml).

## Ikona i ekran uruchamiania

Źródło logo: [sedno-app-icon.svg](../docs/Content/sedno-app-icon.svg).
Znak jest zapisany jako ścieżki, bez zależności od czcionek.
Zasoby w `android/app/src/main/res/` zawierają ikony PNG dla starszych Androidów,
ikonę adaptacyjną od Androida 8 oraz wariant jednokolorowy od Androida 13.
Kolor ikon tematycznych wybiera system. Ekran uruchamiania pokazuje biały znak
na niebieskim kole i jasnym tle, również w trybie ciemnym.

Po zmianie logo sprawdź na telefonie ikonę w menu i na ekranie głównym,
maskę okrągłą i zaokrągloną oraz ikony tematyczne, jeżeli program uruchamiający
je obsługuje. Sprawdź też ekran startowy po pełnym zamknięciu aplikacji,
w jasnym i ciemnym trybie systemu, na Androidzie 12+ i starszym.
Zmiana ikony wymaga nowej instalacji lub aktualizacji aplikacji;
przeładowanie kodu Fluttera jej nie zmienia.
