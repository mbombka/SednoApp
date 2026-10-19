# Testy subskrypcji Google Play

Płatności są obecnie wyłączone. Wykonaj te próby przed ich włączeniem,
na oddzielnym backendzie testowym i telefonie z Google Play.
Testy automatyczne z atrapami nie zastępują zakupów w sklepie.

## Przygotowanie

1. Sprawdź pakiet `xyz.sedno.app` w Google Play i Firebase `sednoapp-79241`,
   certyfikaty podpisu oraz Play Integrity. Wgraj podpisany AAB do testów wewnętrznych.
2. Utwórz subskrypcję z jednym miesięcznym planem odnawianym automatycznie,
   bez okresu próbnego i promocji. Docelowa cena w Polsce: 9,99 zł.
3. Dodaj konto do testerów licencji i testów wewnętrznych, zaakceptuj zaproszenie
   i zainstaluj aplikację z Play. W oknie zakupu musi być widoczna metoda testowa.
4. Zastosuj migracje i [konfigurację płatności backendu](../../backend/README.md#subskrypcje-google-play).
   Klucze szyfrujące zakupy muszą przetrwać restart serwera.
5. Skonfiguruj powiadomienia Google Play (RTDN) przez uwierzytelniony Pub/Sub do
   `/notifications/google-play`, ponowienia i obsługę niedostarczonych wiadomości.
   Test z Play Console powinien otrzymać HTTP 204.
6. Ustaw w aplikacji `PLAY_SUBSCRIPTION_PRODUCT_ID` taki sam jak serwerowy
   `Billing__ProductId`, wraz z adresem backendu i konfiguracją Firebase/Integrity.
   Zaloguj się do Sedno — zakup i przywrócenie wymagają konta.

## Co sprawdzić

| Próba | Oczekiwany wynik |
| --- | --- |
| Cena | Cena i waluta zgadzają się z oknem Google Play; okres to miesiąc |
| Zakup zatwierdzony | Serwer weryfikuje i potwierdza zakup; limit 400 łącznie, bez zerowania użycia |
| Restart serwera | Zakup pozostaje potwierdzony; zapisany token daje się odszyfrować |
| Płatność oczekująca | Brak płatnego dostępu i potwierdzenia do czasu opłacenia |
| Płatność odrzucona lub anulowana | Brak dostępu, polski komunikat i możliwość ponowienia |
| Przywrócenie po reinstalacji | To samo konto Sedno i Play odzyskuje zakup bez drugiej opłaty i nowej puli |
| Przywrócenie na innym koncie Sedno | Serwer odrzuca zmianę właściciela zakupu |
| Anulowanie odnawiania | Dostęp pozostaje do końca opłaconego okresu |
| Wygaśnięcie | Powrót do limitu 5 bez zerowania dzisiejszego użycia |
| Zwrot z odebraniem dostępu | Gdy Google potwierdzi wygaśnięcie, znika limit 400; sprawdź także odświeżenie bez RTDN |
| Zwrot bez odebrania dostępu | Dostęp zgodny z bieżącym stanem Google; zwrot starego zamówienia nie odbiera nowego okresu |
| Powtórzone RTDN, także równoległe | Ta sama wiadomość przetworzona raz, HTTP 204, bez dodatkowej puli |
| Opóźnione RTDN o odnowieniu po wygaśnięciu | Stare zdarzenie nie przywraca dostępu; decyduje aktualny stan Google |
| Fałszywe RTDN | Bez poprawnego podpisu lub odbiorcy: HTTP 401, brak zmiany dostępu |
| Brak sieci po zakupie | Dostęp dopiero po weryfikacji serwera; przywrócenie pozwala ponowić weryfikację |
| Powrót do aplikacji | Stan odświeżony; cena i opisy czytelne z TalkBack i dużym tekstem |

Do zmian stanu używaj testowych metod płatności i narzędzi Google Play.
Czasy odnowień oraz automatycznego zwrotu sprawdź w
[dokumentacji testów](https://developer.android.com/google/play/billing/test).
Niepotwierdzony zakup wymaga szybkiego ponowienia weryfikacji.

Zapisz wersję aplikacji i serwera, czas UTC, scenariusz oraz wynik, bez tokenów,
danych logowania, tekstów i zdjęć. Po próbach anuluj odnawianie i usuń dane testowe.
