# Wydanie 12 — Popraw, lokalny odczyt i dostęp testerski

Podpisany pakiet: [sedno-0.1.0-12.aab](../build/releases/sedno-0.1.0-12.aab).

- Pakiet `xyz.sedno.app`, wersja `0.1.0`, kod wydania `12`.
- Dotychczasowy serwer `https://sednoapp-79241-api.web.app`.
- Tryby Uprość i Popraw, zachowanie wybranego trybu w wyniku i historii.
- Lokalny polski odczyt tekstu z edytora w trybie Popraw; wymaga pobranego
  polskiego głosu offline w Androidzie. Nie zużywa limitu AI.
- Status czasowego dostępu testerskiego, data wygaśnięcia i obsługa powrotu
  do darmowego limitu bez zerowania dzisiejszego użycia.
- Panel zakupów włączony jawnie; produkt `subscription_full`, plan `monthly`.
- Zawiera wcześniejsze poprawki sesji, subskrypcji, historii i dostępności.
- Rozmiar: **70 497 563 bajty**.
- SHA-256: `4ee9e65622b1a25926f2734cd393e27b8002328b540bbdafaea0be41c33233c2`.
- Podpis `jarsigner`: poprawny. Certyfikat identyczny z wydaniem 11.
- SHA-256 certyfikatu: `C1:6D:39:16:CE:97:57:D7:F9:E4:B7:90:44:3E:ED:62:59:A6:F7:66:EC:B0:AB:ED:96:C2:DE:C5:00:36:63:49`.
- Manifest: `xyz.sedno.app`, `0.1.0`, `versionCode=12`, brak `debuggable`.
- `bundletool 1.18.3 validate`: poprawna struktura pakietu.
- ZIP: poprawne CRC, brak powielonych wpisów.
- Architektury: `arm64-v8a`, `armeabi-v7a`, `x86_64`.
- [Mapa R8](../build/releases/mapping-v12.txt).
- [Suma kontrolna](../build/releases/sedno-0.1.0-12.aab.sha256).

Budowa zakończyła się sukcesem 22.10.2026:

```sh
JAVA_HOME=/opt/android-studio/jbr flutter build appbundle --release --build-number=12 --dart-define-from-file=config/billing.local.json
```

`flutter analyze`: bez uwag; `flutter test`: 212 testów przeszło.
Formatowanie `mobile/lib` i `mobile/test`: 104 pliki, bez zmian.
Dokumenty prywatności są spójne z wersją w repozytorium.
`JAVA_HOME=/opt/android-studio/jbr ./gradlew :app:testDebugUnitTest`: sukces,
6 testów natywnych Androida.
Kompilacja zgłasza ostrzeżenia o przyszłej zgodności Kotlin w pluginach Firebase,
wersjach XML Android SDK i dostępie natywnym JDK; nie przerwały budowania.
Walidacja bundletool zgłasza ostrzeżenie protobuf/JDK o przestarzałym `Unsafe`.

[Backend wdrożono jako `sedno-api-00012-9j4`](../../docs/backend-deployment-2026-10-22.pl.md),
łącznie z aktualnymi promptami, trybem Popraw i czasowym dostępem testerskim.
Prompty są osadzone w backendzie, nie w AAB.

Pakiet **nie został wysłany do Google Play**. Pozostają testy na telefonie,
w tym odczyt offline oraz brak polskiego głosu, rzeczywiste testy zakupów Google Play
na kontach testerów licencji i ocena jakości nowych promptów.
Kolejny pakiet musi mieć numer wydania większy niż 12.
