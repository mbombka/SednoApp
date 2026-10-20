# Testy subskrypcji Google Play

Obsługę płatności włączono 20.10.2026 na istniejącym serwerze `sedno-api`
pod adresem `https://sednoapp-79241-api.web.app`, z dotychczasowym kontem
usługi i bazą `(default)`. Próby wykonuj na kontach testerów licencji i telefonie
z Google Play, przed udostępnieniem zakupów wszystkim użytkownikom.
Testy automatyczne z atrapami nie zastępują zakupów w sklepie.

[Stan wdrożenia i pozostałe ustawienia Play Console](../../docs/billing-deployment-2026-10-20.pl.md).
[Gotowy AAB 8](google_play_release_8.md) używa istniejącego serwera.

## Produkt skonfigurowany w Google Play

Właściciel potwierdził konfigurację 20.10.2026:

| Ustawienie | Wartość |
| --- | --- |
| Pakiet | `xyz.sedno.app` |
| Product ID | `subscription_full` |
| Base plan ID | `monthly` |
| Okres | miesiąc |
| Cena w Polsce | 9,99 PLN |
| Limit | 400 uproszczeń dziennie łącznie |

Domyślne identyfikatory aplikacji zapisano w
[`PlaySubscriptionConfiguration`](../lib/features/subscription/domain/play_subscription_configuration.dart).
Aplikacja wybiera plan `monthly` bez promocji, z miesięcznym okresem i automatycznym
odnawianiem. Cenę wyświetla z odpowiedzi Google Play, aby zgadzała się z oknem zakupu.
Przed testami potwierdź aktywność produktu i planu, dostępność w Polsce oraz brak
okresu próbnego i promocji. Utworzenie produktu nie oznacza włączenia płatności w Sedno.

## Przygotowanie

1. Sprawdź pakiet `xyz.sedno.app` w Google Play i Firebase `sednoapp-79241`,
   certyfikaty podpisu oraz Play Integrity. Wgraj podpisany AAB do testów wewnętrznych.
2. Użyj istniejącej subskrypcji `subscription_full` i planu `monthly`.
   Sprawdź automatyczne odnawianie, brak okresu próbnego i promocji oraz cenę 9,99 PLN.
3. Dodaj konto do testerów licencji i testów wewnętrznych, zaakceptuj zaproszenie
   i zainstaluj aplikację z Play. W oknie zakupu musi być widoczna metoda testowa.
4. Sprawdź [konfigurację istniejącego backendu](../../backend/README.md#subskrypcje-google-play).
   Klucze szyfrujące zakupy muszą przetrwać restart serwera.
5. Skonfiguruj powiadomienia Google Play (RTDN) przez uwierzytelniony Pub/Sub do
   `/notifications/google-play`, ponowienia i obsługę niedostarczonych wiadomości.
   Test z Play Console powinien otrzymać HTTP 204.
6. Na istniejącym `sedno-api` ustawiono `Billing__ProductId=subscription_full`
   i `Billing__Enabled=true`. Przy generowaniu kolejnych manifestów przekaż
   `--billing-product subscription_full`; `monthly` jest identyfikatorem planu, nie produktu.
7. Zbuduj aplikację z konfiguracją Firebase/Integrity i dotychczasowym adresem API
   oraz `--dart-define=PLAY_BILLING_ENABLED=true`. Domyślne identyfikatory to
   `PLAY_SUBSCRIPTION_PRODUCT_ID=subscription_full` i `PLAY_SUBSCRIPTION_BASE_PLAN_ID=monthly`;
   można je jawnie podać przez `--dart-define`. Bez flagi włączającej panel zakupów
   pozostaje wyłączony. Zaloguj się do Sedno — zakup i przywrócenie wymagają konta.

Do obecnych prób użyj przygotowanego `config/billing.local.json` i AAB 8.
Nie używaj odrzuconego pakietu 7, który wskazywał niewdrożony adres.

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
