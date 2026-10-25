# Wydanie 17 — 0.2.0, 13 wariantów językowych

Podpisany pakiet: [sedno-0.2.0-17.aab](../build/releases/sedno-0.2.0-17.aab).

- Pakiet `xyz.sedno.app`, wersja **0.2.0**, kod wydania **17**.
- Polski, angielski UK i USA, francuski, niemiecki, włoski, hiszpański,
  portugalski z Portugalii, słowacki, czeski, rumuński, norweski Bokmål i szwedzki.
- Wybór języka obejmuje interfejs, treść, dyktowanie, głosy i lokalne polityki.
  Rzeczywista dostępność mowy zależy od silnika oraz pobranych modeli urządzenia.
- Backend: `sedno-api-00014-mmh`, https://sednoapp-79241-api.web.app.
  [Raport wdrożenia](../../docs/backend-deployment-2026-10-23-multilingual.pl.md).
- Dotychczasowe produkcyjne ustawienia i `config/billing.local.json`;
  płatności włączone do testów z istniejącym produktem i planem.
- Rozmiar: **73327830 bajtów**.
- SHA-256: `ac74945834359a61b21cdb8edfb9e3311c42e2b83d14833dd57835edf14a1777`.
- Certyfikat SHA-256: `C1:6D:39:16:CE:97:57:D7:F9:E4:B7:90:44:3E:ED:62:59:A6:F7:66:EC:B0:AB:ED:96:C2:DE:C5:00:36:63:49`, zgodny z AAB 16.
- [Suma kontrolna](../build/releases/sedno-0.2.0-17.aab.sha256),
  [mapa R8](../build/releases/mapping-v17.txt).

Budowa:

```sh
JAVA_HOME=/opt/android-studio/jbr flutter build appbundle --release --build-name=0.2.0 --build-number=17 --dart-define-from-file=config/billing.local.json
```

Budowa zakończyła się sukcesem. `bundletool validate`, `jarsigner -verify`,
CRC ZIP, kontrola braku powielonych wpisów i manifestu przeszły.
Manifest: `versionName=0.2.0`, `versionCode=17`, bez `debuggable`.
Architektury: arm64-v8a, armeabi-v7a, x86_64.
Ostrzeżenia narzędzi i podpisu zapisano w lokalnych logach; poprawna weryfikacja
podpisu nie zastępuje testu instalacji i przebiegu zakupów przez Google Play.

Nie przesyłano do Google Play. Nie testowano na telefonie ani nie wykonywano
rzeczywistych zakupów, poczty Firebase czy oceny jakości wyników AI.
Następny pakiet wymaga kodu wydania większego niż 17.
