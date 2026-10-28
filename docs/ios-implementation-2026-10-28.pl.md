# Implementacja iPhone — 28.10.2026

Branch: `iPhoneVersion`, utworzony z aktualnego lokalnego `main`.
Przygotowano kod wspólnej aplikacji Android/iOS i rozszerzenia istniejącego
backendu. Nie jest to odebrana ani opublikowana wersja iOS: brak Maca/Xcode,
iPhone'a i konta Apple Developer uniemożliwia jej kompilację oraz rzeczywiste
próby usług Apple. Wszystkie te braki są w
[missing-information.md](../missing-information.md).

## Zakres zmian

- `mobile/ios/`: projekt Xcode i CocoaPods, minimum iOS 15.5, istniejące logo,
  ekran startowy, 13 lokalizacji uprawnień, capabilities, privacy manifest,
  lokalny szablon konfiguracji i instrukcja macOS.
- Swift: AES-GCM historii, klucz Keychain związany z urządzeniem, wyłączenie
  kopii zapasowych, zapis atomowy, reset po reinstalacji, App Attest,
  lokalne dyktowanie i odczyt. Odczyt pozostawia aktywny przycisk Stop aż do
  końca wypowiedzi; stare callbacks nie kończą nowszej sesji. Dyktowanie używa
  zegara monotonicznego, kończy po 1,5 s ciszy po mowie lub po 60 s.
- `mobile/lib/main.dart`, `lib/app/` i adaptery funkcji: wybór implementacji
  zależnej od platformy przez istniejące składanie zależności. Aparat,
  kadrowanie i ML Kit korzystają z bieżącego wieloplatformowego kodu.
- Sesje iOS: rejestracja App Attest, podpisane jednorazowe wyzwania, utrwalenie
  dowodu do ponowienia po utracie odpowiedzi oraz jedna automatyczna próba
  odzyskania klucza. Rotacja zachowuje identyfikator instalacji i licznik użycia.
  Równoczesne żądania klienta współdzielą tworzenie sesji.
- Pierwsza instalacja: marker w kontenerze aplikacji nie przechodzi przez backup;
  stara historia i secure preferences są czyszczone przed zapisaniem markera.
  Osobny trwały znacznik zapewnia ponowienie wylogowania Firebase po przerwanym
  starcie — Firebase przechowuje swoje dane Keychain niezależnie.
- Konto: Apple obok Google/e-mail, ukryty adres, świeża reautoryzacja przed
  usunięciem i odwołanie dostępu Apple. iOS odwołuje kod autoryzacyjny,
  Android token dostępu przez właściwe dla jego SDK API. Brak dowodu nie usuwa konta.
- Łączenie metod w obu kierunkach: istniejący Google/e-mail → Apple i Apple
  → Google, z potwierdzeniem, ponownym uwierzytelnieniem i kontrolą niezmienionego
  UID. Odrębnych kont Firebase nie scalamy automatycznie po e-mailu.
- Backend: Play Integrity pozostaje; nowe App Attest sprawdza łańcuch Apple,
  nonce, aplikację, środowisko, klucz i licznik. Zużycie wyzwania oraz postęp
  licznika są transakcyjne między instancjami. Nowa ścieżka prowadzi do tego
  samego magazynu sesji i limitów.
- Subskrypcje: StoreKit 2, regularny miesięczny produkt, cena ze sklepu,
  App Store Server API, weryfikacja podpisów i Notifications V2. Właściciel
  oryginalnej transakcji jest stały, Sandbox/Production mają osobne rekordy,
  aktualność weryfikacji ma limit 15 minut z ponowieniem i cooldownem.
- Wspólne uprawnienie z obu sklepów daje 400 operacji łącznie. Status wskazuje
  sklep zakupu; aplikacja blokuje drugi zakup i nie otwiera niewłaściwego panelu
  zarządzania. Przy wyłączonej/niedostępnej ofercie dialog wyczerpania limitu
  nie odsyła do nieaktywnej subskrypcji.
- OpenAPI opisuje nowe endpointy i pola z zachowaniem istniejącej ścieżki
  Androida. Retencja i usuwanie konta obejmują nowe kolekcje. Powiadomienia
  Apple i Google mają oddzielne ograniczenia ruchu.
- Lokalizacje: nowe komunikaty iOS/konta/sklepu w 13 wariantach, polski fallback,
  dodatek prywatności iOS oraz lista kontroli prywatności przed wydaniem.

Szczegóły protokołów i konfiguracji:
[architektura](ios-architecture.pl.md),
[App Attest](../backend/docs/apple-app-attest.md),
[billing](../backend/docs/apple-billing.md),
[iOS](../mobile/ios/README.md),
[zakupy sandbox](../mobile/docs/apple_subscription_sandbox.md).

## Weryfikacja

Kontrole uruchomione z `mobile/`:

- `dart format --output=none --set-exit-if-changed lib test` — poprawne formatowanie.
- `flutter analyze --no-pub` — bez uwag.
- `flutter test --no-pub` — **530/530 testów przeszło**, bez pominięć.
- `flutter build apk --debug --no-pub` — **APK zbudowany poprawnie**;
  `mobile/build/app/outputs/flutter-apk/app-debug.apk`. To build kompilacyjny
  bez pliku konfiguracji usług, nie potwierdzenie działania produkcyjnego API.
  Gradle ostrzega o przyszłej zgodności pluginów z Built-in Kotlin;
  ostrzeżenie nie zablokowało kompilacji.

Z katalogu głównego:

- `dotnet test backend/Sedno.Backend.sln --no-restore -m:1 -nodeReuse:false
  -p:UseSharedCompilation=false` — **328/328 testów przeszło**:
  167 jednostkowych, 123 integracyjne i 38 testów narzędzi benchmarkowych.
- `git diff --check` — bez błędów białych znaków.
- Parsowanie konfiguracji iOS i OpenAPI YAML — bez błędów składni.
Testy automatyczne korzystają z kontrolowanego czasu, sieci, dostawców i danych
syntetycznych oraz jednorazowego emulatora Firestore, bez ruchu użytkowników.
Początkowe ograniczenie localhost w sandboxie wymagało uruchomienia runnerów
Flutter/.NET z rozszerzonymi uprawnieniami. Nie wyłączano zabezpieczeń backendu.

Zestaw widgetów obejmuje warianty Android/iOS, 13 języków, oba tryby i skalę
tekstu 1,0/2,5. Sprawdza cele dotykowe, opisy i kontrast; nie zastępuje VoiceOver
na fizycznym urządzeniu. Weryfikacja plików iOS obejmuje parsowanie plist,
entitlements, privacy manifests, XML/storyboardów oraz zasobów JSON i OpenAPI YAML.

Do projektu dodano dziewięć testów natywnych historii, instalacji i cyklu
odczytu. **Nie uruchomiono ich i nie skompilowano Swift/Xcode.** Nie zbudowano IPA
ani nie wykonano podpisywania. Niezależna próba weryfikatora .NET na publicznych
wektorach z rzeczywistego urządzenia potwierdziła atestację i assertion przy
kontrolowanym czasie certyfikatów; nie zastępuje odbioru naszej zarejestrowanej
aplikacji Apple. Nie dodawano do repozytorium cudzych danych urządzenia.

## Stan wydania i pozostałe kroki

`AppleAppAttest:Enabled`, `AppleBilling:Enabled` i flaga zakupów iOS pozostają
domyślnie wyłączone. Rzeczywiste ID Apple i klucze nie zostały wymyślone ani
utworzone. Nie wdrożono zmian do chmury, nie zmieniono produkcyjnych ustawień,
nie utworzono nowego backendu/bazy i nie wykonano publikacji.

Przed wydaniem nadal trzeba:

1. Uzupełnić informacje i dostępy z `missing-information.md`.
2. Skompilować iOS na Macu, wykonać XCTest i poprawić ewentualne błędy natywne.
3. Skonfigurować aplikację Firebase/Apple, podpisywanie, App Attest, OAuth,
   subskrypcję, App Store Server API i powiadomienia na istniejącej infrastrukturze.
4. Potwierdzić prawdziwe atestacje, modele mowy/głosy, zdjęcia, backup/reinstalację,
   VoiceOver, gesty i oba kierunki kont oraz usuwanie powiązanego konta na Androidzie.
5. Odebrać zakupy, przywracanie, odnowienia, wygaśnięcie, zwroty i dostęp
   do punktów sprawdzania unieważnień certyfikatów Apple. Próby StoreKit
   Configuration bez podpisów nie przyznają uprawnień w tej implementacji.
6. Wykonać audyt SDK/App Privacy i finalnych dokumentów prywatności, przygotować
   rzeczywiste zrzuty ekranu i materiały sklepu. Publiczna strona nie została
   zmieniona na podstawie samego przygotowania wersji iOS.
7. Zmierzyć koszty i opóźnienia weryfikacji, przygotować bezpieczny rollout,
   wycofanie oraz TestFlight przed publicznym uruchomieniem.

Prompty, ustawienia modelu, archiwalne benchmarki i struktura istniejącej
aplikacji pozostały zachowane. Lokalny kod i zielone testy nie stanowią
potwierdzenia gotowości iOS do publicznego udostępnienia.
