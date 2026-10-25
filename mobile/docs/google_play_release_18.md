# Wydanie 18 — 0.2.0, czyszczenie komunikatów edytora

Podpisany pakiet: [sedno-0.2.0-18.aab](../build/releases/sedno-0.2.0-18.aab).

- Pakiet `xyz.sedno.app`, wersja **0.2.0**, kod wydania **18**.
- Poprawiono pozostające komunikaty OCR, aparatu, mikrofonu i odczytu głosowego:
  gumka, zmiana trybu, rozpoczęcie zdjęcia lub nagrania i nowa próba wysłania
  czyszczą poprzednie komunikaty.
- Zachowano 13 wariantów językowych oraz konfigurację wydania 17:
  `config/billing.local.json`, dotychczasowy serwer i płatności włączone do testów.
- Rozmiar: **73328603 bajty**.
- SHA-256: `7912c6c6f361bbe9da27873e6c16d2ae8c130f3d47ad09a9ee007c5539724e8b`.
- Certyfikat SHA-256: `C1:6D:39:16:CE:97:57:D7:F9:E4:B7:90:44:3E:ED:62:59:A6:F7:66:EC:B0:AB:ED:96:C2:DE:C5:00:36:63:49`, zgodny z wydaniem 17.
- [Suma kontrolna](../build/releases/sedno-0.2.0-18.aab.sha256),
  [mapa R8](../build/releases/mapping-v18.txt).

Budowa zakończyła się sukcesem:

```sh
JAVA_HOME=/opt/android-studio/jbr flutter build appbundle --release --build-name=0.2.0 --build-number=18 --dart-define-from-file=config/billing.local.json
```

Przed budową: 418 testów Fluttera przeszło, `flutter analyze` bez uwag,
formatowanie poprawne. Dodano 33 testy interfejsu i 60 testów logiki komunikatów.

`bundletool validate`, `jarsigner -verify`, CRC ZIP, kontrola braku powielonych
wpisów oraz kontrola manifestu przeszły. Manifest zawiera `versionName=0.2.0`,
`versionCode=18`, bez `debuggable=true`.
Narzędzia zgłosiły ostrzeżenia zgodności JDK, SDK i pluginów Firebase;
`jarsigner` zgłosił certyfikat samopodpisany, brak znacznika czasu oraz różnice
odczytu podpisów przez JarFile i JarInputStream. Zwrócił `jar verified.` i kod 0.

Nie przesyłano do Google Play ani nie testowano na fizycznym telefonie.
Następny pakiet wymaga kodu wydania większego niż 18.
