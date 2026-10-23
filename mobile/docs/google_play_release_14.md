# Wydanie 14 — komunikat AI pod polem tekstowym

Podpisany pakiet: [sedno-0.1.0-14.aab](../build/releases/sedno-0.1.0-14.aab).

- Pakiet `xyz.sedno.app`, wersja `0.1.0`, kod wydania **14**.
- Komunikat „AI może się mylić” znajduje się po lewej stronie pod polem tekstowym,
  w białym obszarze edytora, po otrzymaniu wyniku Uprość lub Popraw.
- Pole elastycznie oddaje miejsce komunikatowi. Przyciski pozostają na miejscu;
  pojawienie się ostrzeżenia nie dodaje przewijania całego ekranu.
- Długi wynik można przewijać wewnątrz pola tekstowego.
- Pakiet obejmuje również obecne w kodzie aktualizacje ekranu O aplikacji,
  politykę prywatności z 23.10.2026 i odnośnik do jej pełnej wersji na stronie.
- Serwer: `https://sednoapp-79241-api.web.app`.
- Płatności jawnie włączone konfiguracją, jak w AAB 13;
  produkt `subscription_full`, plan `monthly`.
- Rozmiar: **70 534 799 bajtów** (około 70,5 MB).
- SHA-256: `cbd69a4475636f4bc544e36859134e02c3d4296673edb54cef3787f6c1998fa2`.
- Certyfikat podpisujący zgodny z AAB 13, SHA-256:
  `C1:6D:39:16:CE:97:57:D7:F9:E4:B7:90:44:3E:ED:62:59:A6:F7:66:EC:B0:AB:ED:96:C2:DE:C5:00:36:63:49`.
- [Mapa R8](../build/releases/mapping-v14.txt).
- [Suma kontrolna](../build/releases/sedno-0.1.0-14.aab.sha256).
- [Podglądy krótkiego i długiego wyniku](../../docs/podglady-edytora/README.md).

Budowa 23.10.2026 zakończona sukcesem:

```sh
JAVA_HOME=/opt/android-studio/jbr flutter build appbundle --release --build-number=14 --dart-define-from-file=config/billing.local.json
```

Weryfikacja:

- `dart format --output=none --set-exit-if-changed lib test tool`: 110 plików, bez zmian.
- `flutter analyze`: bez uwag.
- `flutter test`: **229 testów przeszło**; testy układu obejmują oba tryby,
  powiększenie tekstu i przewijanie przy małej dostępnej wysokości.
- `jarsigner -verify`: `jar verified`; certyfikat zgodny z poprzednim wydaniem.
- `bundletool validate`: poprawny pakiet.
- Manifest: `xyz.sedno.app`, `versionName=0.1.0`, `versionCode=14`, bez `debuggable`.
- ZIP: poprawne CRC i brak powielonych wpisów.
- Architektury: `arm64-v8a`, `armeabi-v7a`, `x86_64`.

Kompilator zgłosił ostrzeżenia JDK, przyszłej zgodności pluginów Firebase
z Built-in Kotlin i wersji XML Android SDK. Bundletool zgłosił ostrzeżenie
protobuf/JDK dotyczące `Unsafe`. Jarsigner w JDK 25 zgłosił samopodpisany
certyfikat, brak znacznika czasu oraz różnice odczytu ZIP przez JarFile
i JarInputStream (manifest podpisu znajduje się na końcu archiwum).
Weryfikacja podpisu i walidacja bundletool zakończyły się powodzeniem.

Nie wykonywano publikacji w Google Play, wdrożenia serwera ani strony.
Lokalna zmiana promptu backendu nie jest częścią AAB i nie została wdrożona.
Nie wykonywano testu nowego pakietu na telefonie ani rzeczywistych zakupów.
Testy zakupów pozostają wymagane przed publicznym wydaniem.
Kolejny pakiet musi mieć kod wydania większy niż 14.

Przygotowanie wydania zmieniło `mobile/pubspec.yaml`, ten dokument i odnośniki
w `README.md`, `mobile/README.md` oraz `docs/README.md`.
Artefakty zapisano w ignorowanym katalogu `mobile/build/releases/`.
Pozostałe niezacommitowane zmiany zachowano.
