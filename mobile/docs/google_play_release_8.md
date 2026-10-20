# Wydanie 8 — płatności na istniejącym API

Podpisany pakiet: `mobile/build/releases/sedno-0.1.0-8.aab` (od katalogu głównego).

- Pakiet `xyz.sedno.app`, wersja `0.1.0`, kod wydania `8`.
- Adres serwera: `https://sednoapp-79241-api.web.app` — dotychczasowe API.
- Włączony panel zakupów, produkt `subscription_full`, plan `monthly`.
- Cena jest pobierana z Google Play; ustalona cena w Polsce to 9,99 PLN miesięcznie.
- Aktualna polityka 13+, poprawki ekranów konta i „O aplikacji”.
- Rozmiar: 70 249 034 bajty.
- SHA-256: `1532e4cbd63924e489211ce940cd69037d980ba37265fe147d557a10951f7ee6`.
- Podpis zweryfikowany dla wszystkich 388 wpisów zawartości, zgodny z dotychczasowym
  publicznym certyfikatem przesyłania. Brak powielonych wpisów ZIP.
- Manifest AAB: poprawny pakiet, wersja i brak włączonego `debuggable`.
- Architektury: `arm64-v8a`, `armeabi-v7a`, `x86_64`.
- Mapa R8: `mobile/build/releases/mapping-v8.txt`.
- Suma kontrolna: `mobile/build/releases/sedno-0.1.0-8.aab.sha256`.

Budowa zakończyła się sukcesem:

```sh
flutter build appbundle --release --build-number=8 --dart-define-from-file=config/billing.local.json
```

Lokalny plik `billing.local.json` zawiera tę samą konfigurację Firebase i Integrity
co dotychczasowa aplikacja, dotychczasowy adres API i `PLAY_BILLING_ENABLED=true`.
Nie jest wersjonowany. Można też użyć `firebase.local.json` i jawnej flagi włączającej
panel oraz dotychczasowego adresu backendu.

Pakiet przygotowano do testów wewnętrznych. Nie przesłano go do Google Play
i nie wykonano rzeczywistego zakupu. Następny numer wydania musi być wyższy niż 8.
Nie używaj odrzuconego AAB 7 z niewłaściwym adresem.

Podczas budowy pojawiły się ostrzeżenia JDK oraz ostrzeżenie pluginów Firebase
o przyszłym wsparciu Built-in Kotlin; budowa zakończyła się sukcesem.

[Stan serwera i ustawienia Play Console](../../docs/billing-deployment-2026-10-20.pl.md).
