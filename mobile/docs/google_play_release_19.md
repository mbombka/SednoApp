# Wydanie 19 — 0.2.0, zapamiętywanie akceptacji informacji o AI

Podpisany pakiet: [sedno-0.2.0-19.aab](../build/releases/sedno-0.2.0-19.aab).

- Pakiet `xyz.sedno.app`, wersja **0.2.0**, kod wydania **19**.
- Akceptacja informacji przed pierwszym wysłaniem jest zapisywana lokalnie
  dla instalacji, wspólnie dla trybów „Uprość” i „Popraw”. Kolejne uruchomienia
  aplikacji nie wymagają ponownej akceptacji. Anulowanie nie zapisuje akceptacji.
- Konfiguracja zgodna z wydaniem 18: `config/billing.local.json`, dotychczasowy
  serwer i płatności włączone do testów.
- Rozmiar: **73335042 bajty**.
- SHA-256: `30c2cc59f6d7ebedecd9ac6cd25d9d4b9beb29d6dc24403c43df917eee7c80f6`.
- Certyfikat SHA-256: `C1:6D:39:16:CE:97:57:D7:F9:E4:B7:90:44:3E:ED:62:59:A6:F7:66:EC:B0:AB:ED:96:C2:DE:C5:00:36:63:49`, zgodny z poprzednimi wydaniami.
- [Suma kontrolna](../build/releases/sedno-0.2.0-19.aab.sha256),
  [mapa R8](../build/releases/mapping-v19.txt).

Budowa zakończyła się sukcesem:

```sh
JAVA_HOME=/opt/android-studio/jbr flutter build appbundle --release --build-name=0.2.0 --build-number=19 --dart-define-from-file=config/billing.local.json
```

Przed budową: 431 testów Fluttera przeszło, `flutter analyze` bez uwag,
formatowanie poprawne. Zmiana akceptacji ma 13 nowych testów.

`bundletool validate`, `jarsigner -verify`, CRC ZIP, kontrola braku powielonych
wpisów oraz kontrola manifestu przeszły. Manifest zawiera `versionName=0.2.0`,
`versionCode=19`, bez `debuggable=true`.
Narzędzia zgłosiły ostrzeżenia zgodności JDK i pluginów Firebase;
szczegóły walidacji i podpisu zapisano lokalnie w `/tmp/sedno-v19-validation.log`
i `/tmp/sedno-v19-signature.log`. `jarsigner` zwrócił `jar verified.` i kod 0.

Nie przesyłano do Google Play ani nie testowano na fizycznym telefonie.
Następny pakiet wymaga kodu wydania większego niż 19.
