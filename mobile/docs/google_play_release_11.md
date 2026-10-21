# Wydanie 11 — obsługa odwołanych sesji i ponownego uwierzytelnienia

Podpisany pakiet: [sedno-0.1.0-11.aab](../build/releases/sedno-0.1.0-11.aab).

- Pakiet `xyz.sedno.app`, wersja `0.1.0`, kod wydania `11`.
- Dotychczasowy serwer `https://sednoapp-79241-api.web.app`.
- Panel zakupów włączony jawnie; produkt `subscription_full`, plan `monthly`.
- Zawiera zmiany mobilne po wydaniu 10: obsługę odrzucenia sesji Sedna po
  odebraniu dostępu w Firebase oraz ponowne uwierzytelnienie przed usunięciem konta.
- Zachowuje poprawki tekstów, historii i subskrypcji z wydania 10.
- Rozmiar: **70 414 699 bajtów**.
- SHA-256: `74a01775f0cca0c44e9d7d4a5b8f88c05b7ac9c0109a3c05a268de7f3a8642bd`.
- `jarsigner`: poprawny podpis 389 wpisów zawartości; certyfikat zgodny z wydaniem 10.
- Manifest: `xyz.sedno.app`, `0.1.0`, `versionCode=11`, brak `debuggable`.
- `bundletool validate`: poprawna struktura pakietu; brak powielonych wpisów ZIP.
- Architektury: `arm64-v8a`, `armeabi-v7a`, `x86_64`.
- [Mapa R8](../build/releases/mapping-v11.txt).
- [Suma kontrolna](../build/releases/sedno-0.1.0-11.aab.sha256).

Budowa zakończyła się sukcesem 21.10.2026:

```sh
flutter build appbundle --release --build-number=11 --dart-define-from-file=config/billing.local.json
```

Sprawdzenie formatowania: 87 plików, bez zmian. `flutter analyze`: bez problemów.
`flutter test`: **176/176 zaliczonych**. Podczas budowy pojawiły się ostrzeżenia
JDK, przyszłej obsługi Kotlin w pluginach Firebase i wersji XML Android SDK;
nie zablokowały budowy ani walidacji pakietu.

[Backend został wdrożony jako `sedno-api-00011-bfh`](../../docs/backend-deployment-2026-10-21.pl.md),
łącznie z odwoływaniem sesji, kontrolą ważności subskrypcji i nowym limiterem.
Te zmiany serwerowe działają niezależnie od AAB.

Pakiet **nie został wysłany do Google Play**. Test zakupu i odbiór na telefonie
pozostają do wykonania. Kolejny pakiet musi mieć numer wydania większy niż 11.
