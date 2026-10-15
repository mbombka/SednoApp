# Testy subskrypcji Google Play w środowisku testowym

Procedura wymaga urządzenia z Google Play, dostępu do Play Console i oddzielnego
backendu testowego. Testów z prawdziwym sklepem nie zastępują automatyczne testy
z atrapami. Nie przeprowadzono ich przez samo uruchomienie testów repozytorium.

## Przygotowanie

1. Zarejestruj pakiet `io.github.mbombka.sedno` w Google Play i dodaj aplikację
   Android z tym pakietem w projekcie Firebase. Skonfiguruj podpisywanie, odciski
   certyfikatów i ten sam pakiet w Play Integrity oraz backendzie
   (`PlayIntegrity__PackageName` i `Billing__PackageName`). Wgraj podpisany AAB na ścieżkę testów wewnętrznych.
2. Utwórz produkt subskrypcji, np. `sedno_monthly`: jeden aktywny, miesięczny plan
   odnawiany automatycznie, bez okresu próbnego i cen wprowadzających. Ustaw cenę
   w Polsce na 9,99 PLN. Inne kraje mogą zwracać inną walutę i cenę.
3. Dodaj konto Google do **testerów licencji** oraz do testerów ścieżki wewnętrznej.
   Zaakceptuj zaproszenie i zainstaluj aplikację z Google Play na tym koncie.
   Sama obecność na ścieżce testowej nie zapewnia płatności testowych. W oknie
   zakupu sprawdź, czy Google pokazuje testowy instrument płatniczy.
4. Skonfiguruj Firebase i backend zgodnie z [instrukcją backendu](../../backend/README.md#google-play-subscriptions).
   Zastosuj migracje bazy. Ustaw `Billing__Enabled=true`, pakiet, produkt, konto
   usługowe Publisher API, HTTPS audience i konto podpisujące push.
   Klucze Data Protection muszą przetrwać restart backendu.
5. Utwórz temat Pub/Sub dla RTDN, uprawnienia publikowania Google Play i
   uwierzytelnioną subskrypcję push do `/notifications/google-play`. Skonfiguruj
   ponowienia, dead letter i alerty. Wyślij test z Play Console: oczekiwane HTTP 204.
6. Uruchom przygotowaną wersję aplikacji z `BACKEND_BASE_URL`, konfiguracją
   Firebase/Integrity i `--dart-define=PLAY_SUBSCRIPTION_PRODUCT_ID=sedno_monthly`.
   Identyfikator musi odpowiadać `Billing__ProductId`. Zaloguj się na konto Sedno.
   Zakup i przywrócenie wymagają konta; upraszczanie w planie darmowym nadal działa
   bez logowania. Zdjęcia pozostają na urządzeniu.

## Scenariusze i wyniki

| Scenariusz | Czynności | Oczekiwany wynik |
| --- | --- | --- |
| Cena | Otwórz Konto na polskim koncie sklepu; porównaj z oknem zakupu. | Cena i waluta pochodzą z Play, okres to miesiąc. Nie ma ceny zastępczej. |
| Aktywna | Kup z instrumentem „zawsze zatwierdza”. | Backend sprawdza zakup i potwierdza go. Konto pokazuje aktywność; limit to 400 **łącznie**, z zachowaniem dzisiejszego użycia. |
| Potwierdzenie | Sprawdź zakup w zamówieniach po kilku minutach i po restarcie serwera. | Zakup pozostaje potwierdzony; token daje się odczytać po restarcie. Brak automatycznego zwrotu za brak potwierdzenia. |
| Oczekująca | Użyj testowej metody opóźnionej płatności; wybierz późniejsze zatwierdzenie. | Komunikat o oczekiwaniu, brak nowego dostępu i potwierdzenia przed opłaceniem. Po zatwierdzeniu dostęp jest weryfikowany na backendzie. |
| Odrzucona/anulowana płatność | Anuluj okno, użyj „zawsze odrzuca”, potem opóźnionej metody odrzucającej. | Brak płatnego dostępu; komunikat po polsku, możliwość ponowienia. |
| Przywrócenie | Zamknij aplikację, usuń jej dane lub zainstaluj ponownie; zaloguj się na **to samo konto Sedno** i konto Play; wybierz Przywróć zakupy. | Ten sam token zostaje ponownie zweryfikowany. Brak drugiej opłaty i nowej puli użyć. |
| Inne konto | Spróbuj przywrócić zakup na drugim koncie Sedno. | Backend odrzuca powiązanie z innym właścicielem. |
| Anulowana subskrypcja | Anuluj odnawianie w Google Play przed końcem okresu, odśwież Konto. | Dostęp utrzymuje się do `expiryTime`; samo anulowanie odnawiania go nie odbiera. |
| Wygasła | Poczekaj na koniec przyspieszonego okresu testowego po anulowaniu. | Backend i Start wracają do limitu 2, bez zerowania użycia. |
| Zwrot z odebraniem dostępu | W testowym zamówieniu wybierz zwrot i odebranie dostępu. | RTDN wywołuje ponowną weryfikację; gdy Play zwraca stan wygasły, znika limit 400. Odświeżenie działa także bez dostarczonego RTDN. |
| Zwrot bez odebrania dostępu | Wykonaj zwrot bez odwołania subskrypcji, jeśli opcja jest dostępna. | Dostęp odpowiada bieżącemu stanowi Play. Zwrot starego zamówienia nie odbiera nowego opłaconego okresu. |
| Powtórzone RTDN | W kontrolowanym narzędziu testowym z prawem do konta push wyślij dwa razy tę samą kopertę z tym samym messageId, także równolegle. | HTTP 204; jeden zapis przetworzenia, bez ponownego przyznania puli lub drugiej operacji zakupu. Nie kopiuj tokenów do logów. |
| Zmieniona kolejność RTDN | Po wygaśnięciu dostarcz opóźnione powiadomienie o odnowieniu. | Bieżący odczyt Play nadal wskazuje wygaśnięcie; stare zdarzenie nie przywraca dostępu. |
| Fałszywe RTDN | Wyślij kopertę bez podpisanego bearer lub z błędnym audience. | HTTP 401; brak zmiany uprawnień. |
| Awaria sieci | Odłącz sieć po zakupie przed weryfikacją; przywróć połączenie i zakupy. | Brak zaufania do samej odpowiedzi klienta; backend potwierdza po ponowieniu. Niepotwierdzony zakup wymaga szybkiego ponowienia. |
| Wznowienie i dostępność | Wróć do aplikacji po zmianie stanu w Play; sprawdź TalkBack i duży tekst. | Odświeżenie stanu, czytelne polskie opisy i przyciski; cena nie jest ucinana. |

U testerów licencji Google może zwrócić zakup już po 3 minutach bez potwierdzenia.
Czas odnowień i dostępne instrumenty zależą od konfiguracji; aktualne warianty
sprawdź w [dokumentacji testów Google Play](https://developer.android.com/google/play/billing/test).
Można użyć Play Billing Lab do przyspieszenia zmian stanu.

Zapisz wersję aplikacji/backendu, czas UTC, scenariusz, stan zamówienia i wynik.
Nie zapisuj tokenów, danych logowania, tekstów użytkownika ani zdjęć. Po testach
anuluj odnawianie i usuń dane testowe zgodnie z przyjętą polityką retencji.

Dokumentacja odniesienia: [cykl subskrypcji](https://developer.android.com/google/play/billing/lifecycle/subscriptions),
[RTDN](https://developer.android.com/google/play/billing/rtdn-reference),
[uwierzytelnienie Pub/Sub](https://docs.cloud.google.com/pubsub/docs/authenticate-push-subscriptions).
