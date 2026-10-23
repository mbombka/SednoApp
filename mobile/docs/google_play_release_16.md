# Wydanie 16 — polski i angielski (UK)

Podpisany pakiet: [sedno-0.1.0-16.aab](../build/releases/sedno-0.1.0-16.aab).

- Pakiet `xyz.sedno.app`, wersja **0.1.0**, kod wydania **16**.
- Interfejs, komunikaty, etykiety TalkBack i polityka prywatności po polsku
  oraz angielsku; wybór w Menu użytkownika → Język, z lokalnym zapisem preferencji.
- Język obejmuje przetwarzanie tekstu, lokalne dyktowanie, odczyt i wiadomości
  konta Firebase. OCR pozostaje lokalny, z modelem pisma łacińskiego.
- API potwierdza język wyniku; starsze wpisy historii domyślnie oznaczają polski.
- Osobne prompty Uprość / Popraw dla obu języków; serwer używa plików `en-gb`.
- Serwer: `https://sednoapp-79241-api.web.app`, rewizja `sedno-api-00013-8x6`.
  [Raport wdrożenia backendu](../../docs/backend-deployment-2026-10-23.pl.md).
- Płatności jawnie włączone istniejącą konfiguracją `config/billing.local.json`,
  produkt `subscription_full`, plan `monthly`; cena pochodzi z Google Play.
- Rozmiar: **71 968 808 bajtów** (około 72.0 MB).
- SHA-256: `a81ce71675978ba001fb67114ec850768a2ce89ff25d99996473e315777bc7cb`.
- Certyfikat podpisujący zgodny z AAB 15, SHA-256:
  `C1:6D:39:16:CE:97:57:D7:F9:E4:B7:90:44:3E:ED:62:59:A6:F7:66:EC:B0:AB:ED:96:C2:DE:C5:00:36:63:49`.
- [Mapa R8](../build/releases/mapping-v16.txt).
- [Suma kontrolna](../build/releases/sedno-0.1.0-16.aab.sha256).

## Budowa i walidacja — 23.10.2026

```sh
JAVA_HOME=/opt/android-studio/jbr flutter build appbundle --release --build-number=16 --dart-define-from-file=config/billing.local.json
```

Budowa release zakończona sukcesem. Sprawdzono:

- `dart format --output=none --set-exit-if-changed lib test tool`: 122 pliki, 0 zmian.
- `flutter analyze --no-pub`: brak uwag; `flutter test --no-pub`: 261 testów przeszło.
- `./gradlew :app:testDebugUnitTest`: 6 testów przeszło.
- `jarsigner -verify`: `jar verified`; certyfikat identyczny jak w AAB 15.
- `bundletool validate`: kod wyjścia 0.
- Manifest: `xyz.sedno.app`, `versionName=0.1.0`, `versionCode=16`, bez `debuggable`.
- ZIP: poprawne CRC i brak powielonych wpisów.
- Architektury: `arm64-v8a`, `armeabi-v7a`, `x86_64`.
- Zapisano mapę R8 i sumę SHA-256 osobno od pakietu.

Budowa i walidacja zgłosiły ostrzeżenia pluginów o przyszłej zgodności z Built-in
Kotlin, narzędzi SDK o wersji XML oraz JDK/protobuf o przestarzałych mechanizmach.
Jarsigner zgłosił ostrzeżenia o certyfikacie samopodpisanym, braku znacznika czasu
oraz różnicach odczytu ZIP przez JarFile i JarInputStream. Weryfikacja podpisu
oraz bundletool zakończyły się powodzeniem.

Nie wysyłano pakietu do Google Play. Nie testowano go na fizycznym telefonie,
nie wykonywano zakupów ani wysyłania wiadomości Firebase. Ocena jakości
angielskich wyników AI i testy zakupów pozostają wymagane przed publicznym wydaniem.
Kolejny AAB musi mieć kod wydania większy niż 16.

Zmiany plików tego wydania i wdrożenia opisuje raport backendu.
Wcześniejsze niezacommitowane zmiany zachowano; nie wykonywano commita.
