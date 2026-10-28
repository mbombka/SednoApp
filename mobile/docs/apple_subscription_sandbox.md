# Subskrypcja iOS — konfiguracja i odbiór

Implementacja korzysta z tego samego `sedno-api`, konta usługi i Firestore
`(default)` co Android. Nie tworzyć oddzielnego backendu ani bazy.
Obsługa Apple jest domyślnie wyłączona. Ten dokument nie potwierdza zakupu
na urządzeniu ani gotowości do publicznej publikacji.

## Konfiguracja właściciela

1. Utworzyć w App Store Connect miesięczną subskrypcję odnawialną; jej rzeczywisty
   identyfikator przekazać jako `APPLE_SUBSCRIPTION_PRODUCT_ID` w aplikacji oraz
   `AppleBilling:ProductId` na serwerze. Cena jest pobierana ze sklepu.
2. Ustawić `APPLE_BILLING_ENABLED=true` dopiero dla buildu testującego zakupy.
3. Skonfigurować na istniejącym serwerze `AppleBilling:Enabled=true`, `BundleId`,
   `ProductId`, `AppAppleId`, `Environment` (`Sandbox` do testów), `IssuerId`,
   `KeyId`, `PrivateKeyPath` i `RootCertificatePaths`.
   Klucz `.p8` przechowywać w Secret Manager i montować tylko na serwerze;
   nigdy w aplikacji, repozytorium ani logach. Pliki zaufanych certyfikatów głównych
   pobrać z Apple PKI i zweryfikować przed konfiguracją. Nie ufać certyfikatowi
   głównemu przesłanemu przez klienta w `x5c`.
4. Skonfigurować powiadomienia App Store Server Notifications **V2** na
   `https://sednoapp-79241-api.web.app/notifications/apple` w odpowiednim środowisku.
5. Zapewnić serwerowi HTTPS do App Store Server API oraz punktów OCSP/CRL Apple.
   Weryfikacja łańcucha wymaga aktualnego stanu unieważnień; awaria weryfikacji
   nie przedłuża płatnego dostępu.

Każdy zakup jest związany przez StoreKit `appAccountToken` z UUID zwróconym
przez `/v1/subscription/apple`. Nie używać w nim identyfikatora Firebase ani
wiązania Google Play. Oryginalny identyfikator transakcji ma jednego właściciela;
zmiana konta w aplikacji nie przenosi zakupu automatycznie.

## Co sprawdzić na fizycznym iPhonie / TestFlight

- Zalogowanie i cena miesięczna zwrócona przez sklep dla regionu konta.
- Zakup, anulowanie arkusza zakupu, oczekujący zakup (Ask to Buy), awaria sieci.
- Transakcja jest kończona dopiero po poprawnej weryfikacji serwera. Nieudana
  weryfikacja pozostawia możliwość ponownego dostarczenia transakcji przez StoreKit.
- Przywrócenie po reinstalacji na tym samym koncie; inne konto nie przejmuje zakupu.
- Odnowienie, wyłączenie automatycznego odnawiania, wygaśnięcie, grace period,
  billing retry, zwrot/unieważnienie i przywrócenie po wygaśnięciu.
- Powiadomienia testowe V2, duplikaty i zdarzenia w innej kolejności.
- Zablokowany App Store Server API/powiadomienia: po 15 minutach bez aktualnej
  weryfikacji wygasa pamięć uprawnienia, bez resetu dotychczasowego zużycia.
- Konto z Google Play zachowuje uprawnienie na iOS; konto z Apple na Androidzie.
  Dwie aktywne subskrypcje dają nadal 400 operacji łącznie, nie 800.
- Dostęp testerski zachowuje własny termin i zasady.
- Usunięcie konta usuwa jego metadane Apple; wylogowanie czyści lokalną historię.
- Zarządzanie subskrypcją otwiera odpowiedni sklep; subskrypcja kupiona w drugim
  sklepie nie zachęca do kolejnego zakupu.

Do testów lokalnych logiki używać atrap sieci w testach. Serwer celowo nie akceptuje
niepodpisanych transakcji StoreKit Configuration/Xcode jako podstawy uprawnień.
Przejście `Sandbox` → `Production` wymaga jawnej zmiany konfiguracji i ponownego
odbioru. Pamięć zakupów oddziela te środowiska.

## Źródła techniczne

- [App Store Server API](https://developer.apple.com/documentation/appstoreserverapi)
- [Get All Subscription Statuses](https://developer.apple.com/documentation/appstoreserverapi/get-all-subscription-statuses)
- [Apple Server Library — weryfikacja JWS](https://github.com/apple/app-store-server-library-node/blob/main/jws_verification.ts)
- [Apple PKI](https://www.apple.com/certificateauthority/)
