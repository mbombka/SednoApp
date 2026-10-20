# Wydanie 10 — jaśniejsze teksty i poprawki po testach

Podpisany pakiet: `mobile/build/releases/sedno-0.1.0-10.aab` (od katalogu głównego).

- Pakiet `xyz.sedno.app`, wersja `0.1.0`, kod wydania `10`.
- Adres serwera i konfiguracja płatności jak w [wydaniu 8](google_play_release_8.md).
- Upraszczanie: limit czasu 20 s na próbę; ponowne „Uprość” po przekroczeniu czasu
  daje nowy wynik zamiast błędu (zużywa wtedy jedno uproszczenie).
- Konto: adres zalogowanego konta, panel subskrypcji z ceną z Google Play,
  przyciski zależne od stanu subskrypcji.
- Godzina nowego limitu w czasie telefonu zamiast „00:00 UTC”.
- Historia: data, termin usunięcia, ukryty oryginał, pytanie przed usunięciem.
- O aplikacji i Prywatność i dane: krótsze sekcje, klikalne linki, bez przycisków kopiowania;
  usunięto nieaktualne zdanie o wyłączonych płatnościach.
- Rozmiar: 70 375 276 bajtów.
- SHA-256: `dc4879b4311e89f731a0c216c788794520970962646c3b03233b57af5ceec807`.
- Podpis zweryfikowany (`jarsigner`); certyfikat zgodny z wydaniem 9.
- Manifest: poprawny pakiet, kod wersji 10, brak `debuggable`.
- Architektury: `arm64-v8a`, `armeabi-v7a`, `x86_64`.
- Mapa R8: `mobile/build/releases/mapping-v10.txt`.
- Suma kontrolna: `mobile/build/releases/sedno-0.1.0-10.aab.sha256`.

Budowa zakończyła się sukcesem:

```sh
flutter build appbundle --release --build-number=10 --dart-define-from-file=config/billing.local.json
```

Pakiet nie został przesłany do Google Play. Następny numer wydania musi być wyższy niż 10.
