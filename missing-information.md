# Sedno na iPhone — brakujące informacje i dostępy

Stan: 28.10.2026. Właściciel potwierdził brak Maca, iPhone'a i Apple Developer
Program. Poniższe braki nie blokują przygotowania kodu i testów z atrapami,
ale blokują odpowiednie etapy odbioru, podpisania i publikacji.
Nie wpisywać do tego pliku haseł, tokenów, kluczy prywatnych ani kodów logowania.

| Brak | Do czego potrzebny | Gdzie później skonfigurować |
| --- | --- | --- |
| Mac lub środowisko macOS z Xcode i CocoaPods | Kompilacja natywnego kodu, symulator, XCTest, archiwum IPA | Instrukcja `mobile/ios/README.md` |
| Rzeczywisty iPhone i testowane wersje iOS | App Attest, aparat/OCR, offline mowa, VoiceOver i zakupy | Macierz odbioru w raporcie iOS |
| Apple Developer Program i dostęp do App Store Connect | Capabilities, podpisywanie, TestFlight i App Store | Konto organizacji/osoby właściciela |
| Team ID / rzeczywisty App ID prefix | Weryfikacja App Attest; prefix sprawdzić w Apple, nie zakładać zgodności z Team ID dla starych aplikacji | `AppleAppAttest:TeamId`, lokalne xcconfig `DEVELOPMENT_TEAM` |
| Zarejestrowany Bundle ID | Podpis, Firebase, App Attest, App Store | `SEDNO_BUNDLE_IDENTIFIER`, `IOS_BUNDLE_ID`, `AppleAppAttest:BundleId`, `AppleBilling:BundleId` |
| Aplikacja iOS w istniejącym Firebase `sednoapp-79241` | Firebase Authentication | `FIREBASE_IOS_APP_ID`; wspólne project/API/sender ID |
| OAuth client ID iOS i odwrócony client ID | Logowanie Google i powrót do aplikacji | `GOOGLE_IOS_CLIENT_ID`, xcconfig `GOOGLE_REVERSED_CLIENT_ID` |
| Apple Services ID, domena i poprawny adres powrotu Firebase OAuth | Ponowne uwierzytelnienie Apple po zalogowaniu Google na Androidzie (np. usuwanie powiązanego konta) | Apple Developer i Firebase; odbiór arkusza przeglądarki na Androidzie |
| Włączony dostawca Apple w Firebase i konfiguracja Apple | Logowanie Apple, ukryty e-mail i odwołanie dostępu | Firebase Authentication, Apple Developer; sekrety poza Git |
| Potwierdzone możliwości App Attest i Sign in with Apple | Entitlements i profil provisioning | App ID i profil w Apple Developer |
| Numeryczny Apple app ID | Weryfikacja zakupów produkcyjnych | `AppleBilling:AppAppleId` |
| Produkt miesięczny i grupa subskrypcji w App Store Connect | Oferta 400 użyć/dzień; docelowo 9,99 PLN w Polsce | `APPLE_SUBSCRIPTION_PRODUCT_ID`, `AppleBilling:ProductId` |
| Cena Apple i konfiguracja odnowień | Cena wyświetlana ze sklepu, bez hardkodowania | App Store Connect; potwierdzić dostępny poziom ceny |
| Issuer ID, Key ID i klucz App Store Server API | Serwerowe sprawdzanie zakupów | `AppleBilling:IssuerId`, `KeyId`, `PrivateKeyPath`; klucz w istniejącym zarządzaniu sekretami |
| Zaufane certyfikaty główne Apple dla podpisów StoreKit | Weryfikacja łańcucha JWS i odwołania certyfikatów | `AppleBilling:RootCertificatePaths`, oficjalne Apple PKI; nie używać dowolnego certyfikatu z żądania |
| Konto Sandbox Apple, testerzy i konfiguracja powiadomień V2 | Zakup, odnowienie, zwrot, przywracanie i powiadomienia | App Store Connect, `/notifications/apple` na istniejącym backendzie |
| Odbiór prywatności SDK i materiałów sklepu | App Privacy, zasady AI i deklaracje wymaganych API | `docs/privacy-ios-release-checklist.pl.md` |

## Konfiguracja po uzyskaniu dostępu

1. Przeczytać `mobile/ios/README.md`, `backend/docs/apple-app-attest.md`
   i `backend/docs/apple-billing.md`. Sprawdzić aktualne wymagania Apple.
2. Uzupełnić lokalne pliki na podstawie szablonów. Nie kopiować Androidowego
   Firebase App ID do konfiguracji iOS; oba mają wskazywać ten sam projekt.
3. Backend ma domyślnie `AppleAppAttest:Enabled=false` i
   `AppleBilling:Enabled=false`. Płatności w aplikacji również są wyłączone.
   Nie włączać ich przez samo uzupełnienie przykładowych wartości.
4. Testy App Attest Development wymagają Development backendu;
   produkcyjny backend odrzuca dowody development. TestFlight używa App Attest
   production, natomiast zakupy TestFlight wymagają weryfikacji środowiska Sandbox.
   Zaplanować konfigurację i rollout przed jednoczesnym ruchem testowym i publicznym.
5. Po rzeczywistym odbiorze sporządzić raport z buildami i wynikami.
   Dopiero wtedy ustalić wdrożenie i publiczną dystrybucję. Brak wykonanej
   kompilacji na Macu oznacza, że natywna implementacja pozostaje niezweryfikowana.

Nie utworzono drugiego backendu ani bazy. Nie zmieniono konfiguracji produkcji,
nie zarejestrowano aplikacji u Apple i nie wykonano publikacji.
