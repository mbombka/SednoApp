# Wydanie 15 — wszystkie komunikaty pod polem tekstowym

Podpisany pakiet: [sedno-0.1.0-15.aab](../build/releases/sedno-0.1.0-15.aab).

- Pakiet `xyz.sedno.app`, wersja `0.1.0`, kod wydania **15**.
- Wszystkie komunikaty wyświetlane wcześniej pod przyciskami ekranu Start
  są w białym obszarze edytora,
  po lewej stronie pod polem tekstowym, przed przełącznikiem i przyciskami.
- Dotyczy to ostrzeżenia AI, braku tekstu na zdjęciu, błędów OCR i uprawnień,
  mikrofonu i nasłuchiwania, odczytu głosowego, walidacji oraz potwierdzenia
  przekazania tekstu. Awaryjny komunikat o niedostępnym aparacie również
  trafił w to miejsce zamiast do dolnego paska.
- Pole oddaje miejsce komunikatom, zachowując pozycję przycisków.
  Przy dużej czcionce lub małej wysokości obszar komunikatów można przewijać;
  zajmuje najwyżej połowę wnętrza edytora, pozostawiając miejsce na tekst.
- Serwer: `https://sednoapp-79241-api.web.app`.
- Płatności jawnie włączone konfiguracją jak w AAB 14;
  produkt `subscription_full`, plan `monthly`.
- Rozmiar: **70 544 073 bajty** (około 70,5 MB).
- SHA-256: `7a6d06f39159b35496236be19f1279ba4fb5b3932b7ce5f524bd2370f41e9e85`.
- Certyfikat podpisujący zgodny z AAB 14, SHA-256:
  `C1:6D:39:16:CE:97:57:D7:F9:E4:B7:90:44:3E:ED:62:59:A6:F7:66:EC:B0:AB:ED:96:C2:DE:C5:00:36:63:49`.
- [Mapa R8](../build/releases/mapping-v15.txt).
- [Suma kontrolna](../build/releases/sedno-0.1.0-15.aab.sha256).

Budowa 23.10.2026 zakończona sukcesem:

```sh
JAVA_HOME=/opt/android-studio/jbr flutter build appbundle --release --build-number=15 --dart-define-from-file=config/billing.local.json
```

Weryfikacja:

- `dart format --output=none --set-exit-if-changed lib test tool`: 111 plików, bez zmian.
- `flutter analyze`: bez uwag.
- `flutter test`: **247 testów przeszło**.
- Nowe 18 testów położenia komunikatów obejmuje OCR, brak uprawnień,
  niedostępny aparat, mikrofon, nasłuchiwanie, odczyt, walidację i powodzenie;
  każdy scenariusz przy skali tekstu 1,0 oraz 2,5 i wysokości 280 dp.
  Sprawdzono zachowanie pozycji przycisków i brak dodatkowego przewijania strony.
- `jarsigner -verify`: `jar verified`; certyfikat zgodny z AAB 14.
- `bundletool validate`: zakończony kodem 0.
- Manifest: `xyz.sedno.app`, `versionName=0.1.0`, `versionCode=15`, bez `debuggable`.
- ZIP: poprawne CRC i brak powielonych wpisów.
- Architektury: `arm64-v8a`, `armeabi-v7a`, `x86_64`.
- `git diff --check` dla plików tego wydania: bez błędów.

Kompilacja i walidacja zgłosiły ostrzeżenia JDK, pluginów Firebase o przyszłej
zgodności z Built-in Kotlin oraz protobuf/Unsafe. Jarsigner zgłosił ostrzeżenia
o samopodpisanym certyfikacie, braku znacznika czasu i różnicach odczytu ZIP
przez JarFile oraz JarInputStream, jak dla AAB 14. Podpis i walidacja poprawne.

Nie wykonywano testu nowego AAB na telefonie ani rzeczywistych zakupów,
publikacji w Google Play, wdrożenia backendu lub strony. Lokalne zmiany
promptu serwera nie są częścią pakietu mobilnego.
Testy zakupów pozostają wymagane przed publicznym wydaniem.
Kolejny pakiet musi mieć kod wydania większy niż 15.

Zmiany tego wydania: `mobile/lib/features/home/presentation/home_screen.dart`,
`mobile/test/features/home/presentation/home_notice_layout_test.dart`,
`mobile/pubspec.yaml`, ten dokument oraz odnośniki w `README.md`,
`mobile/README.md` i `docs/README.md`. Artefakty zapisano w ignorowanym
katalogu `mobile/build/releases/`. Pozostałe niezacommitowane zmiany zachowano.
