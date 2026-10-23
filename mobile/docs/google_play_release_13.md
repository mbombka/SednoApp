# Wydanie 13 — wynik w edytorze i usuwanie całej historii

Podpisany pakiet: [sedno-0.1.0-13.aab](../build/releases/sedno-0.1.0-13.aab).

- Pakiet `xyz.sedno.app`, wersja `0.1.0`, kod wydania **13**.
- Wynik Uprość/Popraw zastępuje tekst w tym samym edytorze.
- Nagłówek wyniku oraz systemowy Wstecz przywracają oryginał ostatniej operacji.
- Gumka 28 dp czyści tekst i zapamiętany oryginał; jej obszar dotyku ma minimum 48 dp.
- Zmiana trybu i rozpoczęcie nagrywania lub zdjęcia czyszczą poprzedni tekst.
- Historia: „Usuń całą historię teraz” z koszem, potwierdzenie, obsługa błędu
  i blokada podczas usuwania.
- Dotychczasowy serwer `https://sednoapp-79241-api.web.app`.
- Płatności jawnie włączone konfiguracją; produkt `subscription_full`, plan `monthly`.
- Rozmiar: **70 528 909 bajtów** (około 70,5 MB).
- SHA-256: `e99546a405039627841f519035d5622e02e29b997cd7b278bdf6d96ab9734e73`.
- `jarsigner`: poprawny podpis; certyfikat zgodny z AAB 12.
- SHA-256 certyfikatu: `C1:6D:39:16:CE:97:57:D7:F9:E4:B7:90:44:3E:ED:62:59:A6:F7:66:EC:B0:AB:ED:96:C2:DE:C5:00:36:63:49`.
- Manifest: `xyz.sedno.app`, `versionName=0.1.0`, `versionCode=13`, bez `debuggable`.
- `bundletool 1.18.3 validate`: poprawny pakiet.
- ZIP: poprawne CRC i brak powielonych wpisów.
- Architektury: `arm64-v8a`, `armeabi-v7a`, `x86_64`.
- [Mapa R8](../build/releases/mapping-v13.txt).
- [Suma kontrolna](../build/releases/sedno-0.1.0-13.aab.sha256).

Budowa 22.10.2026 zakończona sukcesem:

```sh
JAVA_HOME=/opt/android-studio/jbr flutter build appbundle --release --build-number=13 --dart-define-from-file=config/billing.local.json
```

Weryfikacja:

- `dart format --output=none --set-exit-if-changed lib test`: 108 plików, bez zmian.
- `flutter analyze`: bez uwag.
- `flutter test`: **225 testów przeszło**.
- Podpis, certyfikat, struktura ZIP i manifest sprawdzone po zakończeniu budowy.
- `git diff --check`: bez błędów.

Podczas kompilacji występują ostrzeżenia JDK i pluginów Firebase o przyszłej
zgodności z Built-in Kotlin. Bundletool zgłasza ostrzeżenie protobuf/JDK dotyczące
`Unsafe`. Nie zablokowały kompilacji ani walidacji AAB.

**Wdrożenie backendu nie jest potrzebne.** Zmiany od AAB 12 dotyczą aplikacji;
nie zmieniono backendu ani kontraktu API. Nadal działa rewizja
[`sedno-api-00012-9j4`](../../docs/backend-deployment-2026-10-22.pl.md).
W tym zadaniu nie wykonywano zmian w chmurze ani publikacji w Google Play.

Pozostaje odbiór nowego przepływu na telefonie, w szczególności gest Wstecz,
TalkBack, nagrywanie/zdjęcie po wyczyszczeniu pola i usuwanie historii.
Rzeczywiste testy zakupów Google Play pozostają wymagane przed publicznym wydaniem.
Kolejny pakiet musi mieć kod wydania większy niż 13.

Przygotowanie wydania zmieniło `mobile/pubspec.yaml`, ten dokument, odnośniki
w `README.md`, `mobile/README.md`, `docs/README.md` oraz informację o AAB
w `docs/edytor-wynik.pl.md`. Artefakty zapisano w ignorowanym katalogu
`mobile/build/releases/`; wcześniejsze niezacommitowane zmiany zachowano.
