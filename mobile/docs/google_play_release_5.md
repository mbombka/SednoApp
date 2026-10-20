# Wydanie 5 — 20.10.2026

Podpisany pakiet do przesłania na kanał testowy Google Play:
`mobile/build/releases/sedno-0.1.0-5.aab` (ścieżka od katalogu głównego).

- Pakiet: `xyz.sedno.app`.
- Nazwa wersji: `0.1.0`; numer wydania: `5`, po poprzednim wydaniu 4.
- Rozmiar: 69 903 942 bajty.
- SHA-256: `c3425cc718df86423c7f28343d48d621c162450b02414c3082150162ec71a736`.
- Podpis: istniejący klucz przesyłania, zgodny z publicznym
  `android/keystore/sedno-upload-certificate.pem`.
- SHA-256 certyfikatu: `C1:6D:39:16:CE:97:57:D7:F9:E4:B7:90:44:3E:ED:62:59:A6:F7:66:EC:B0:AB:ED:96:C2:DE:C5:00:36:63:49`.
- Jeden AAB zawiera `arm64-v8a`, `armeabi-v7a` i `x86_64`.
- Mapa R8: `mobile/build/releases/mapping-v5.txt`.
- Suma kontrolna: `mobile/build/releases/sedno-0.1.0-5.aab.sha256`.

## Zawartość

Pakiet zawiera bieżące zmiany aplikacji, w tym potwierdzanie e-maila i poprawkę
obsługi nieudanego połączenia po potwierdzeniu: tożsamość Firebase pozostaje
zachowana, aplikacja pokazuje stan „Adres e-mail potwierdzony” i pozwala ponowić
łączenie z kontem Sedna. Komunikat odrzucenia instalacji jest widoczny przy
przycisku zamiast pozostawiać użytkownika na mylącym ekranie sprawdzania poczty.

## Budowa i kontrola

```sh
flutter build appbundle --release --build-number=5 --dart-define-from-file=config/firebase.local.json
```

Budowa zakończyła się sukcesem. Zweryfikowano konfigurację produkcyjnego API,
obecność ustawień Firebase i Play Integrity, manifest wewnątrz AAB (pakiet,
wersja i brak włączonego `debuggable`) oraz zgodność certyfikatu przesyłania.
Weryfikacja JAR potwierdziła podpis wszystkich 388 wpisów zawartości i brak
powielonych wpisów ZIP. Narzędzie JDK zgłosiło ostrzeżenia dla samopodpisanego
certyfikatu, braku znacznika czasu i kolejności manifestu w archiwum; weryfikacja
podpisów przez `JarFile` zakończyła się sukcesem.

Kod przed budową przeszedł `flutter analyze` bez uwag oraz 142 testy Fluttera.
Numer w `pubspec.yaml` ustawiono na `0.1.0+5`; kolejne wydanie wymaga numeru co
najmniej 6. Nie przesyłano pakietu do Google Play w ramach przygotowania pliku.

Przykładowy opis zmian do Play Console:

> Usprawniliśmy tworzenie konta i potwierdzanie adresu e-mail. Aplikacja lepiej
> wyjaśnia błędy połączenia i pozwala ponowić logowanie bez ponownego
> potwierdzania adresu.
