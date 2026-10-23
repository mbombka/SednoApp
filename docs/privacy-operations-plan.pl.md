# Prywatność — obsługa i przechowywanie danych

Pełne zasady i dane administratora: [polityka prywatności](privacy-policy.pl.md).
Kontakt do zgłoszeń: **contact@sedno.xyz**. Pierwszy rynek: Polska, odbiorcy 13+.
Osoby w wieku 13–17 lat powinny korzystać z aplikacji za zgodą rodzica lub opiekuna.
Usuwanie konta przez e-mail działa — potwierdzenie właściciela z 20.10.2026.

Backend działa od 19.10.2026 w Warszawie; tego dnia produkcję przełączono na Firestore.
Płatności włączono na istniejącym API do testów; test zakupów na telefonie pozostaje do wykonania. Właściciel zrezygnował z backupów nowej bazy na obecnym etapie.
[Konfiguracja serwera](../backend/deploy/firebase/README.pl.md).
Google i OpenAI mają własne zasady przetwarzania; region bazy nie oznacza,
że wszystkie dane pozostają w Polsce lub UE.

## Jak długo przechowujemy dane

| Dane | Okres i sposób usuwania |
| --- | --- |
| Tekst i wynik na serwerze Sedno | Bez zapisu treści w bazie i logach |
| Zdjęcia i dźwięk | Przetwarzanie lokalne; bez wysyłania zdjęć i nagrań, bez zapisu nagrania mowy |
| Odczyt na głos | Lokalny polski głos bez internetu; bez wysyłania tekstu do usługi odczytu |
| Historia na telefonie | 7 dni; czyszczenie przy odczycie, starcie, wznowieniu i wylogowaniu; także ręczne |
| Metadane żądań | 8 dni; osobne zadanie Cloud Run uruchamiane co godzinę |
| Dzienne liczniki i rezerwacje | Do 8 dni; to samo zadanie; rezerwacja przestaje obciążać limit po 5 minutach |
| Dzierżawy operacji konta | 2 minuty; zwalnianie po operacji, porzucone rekordy usuwa zadanie godzinowe |
| Sesje | Konto: 7 dni; gość: 90 dni; wygasłe rekordy usuwa zadanie godzinowe |
| Niepowiązani goście | Po 90 dniach, gdy nie mają już sesji ani żądań |
| Konto i rekordy zakupów | Do usunięcia konta; brak automatycznego usuwania nieaktywnych kont |
| Identyfikatory powiadomień zakupowych | Brak automatycznego terminu; bez tokenu i powiązania z kontem |
| Cloud Logging `_Default` | 30 dni; pozostałe magazyny i eksporty trzeba kontrolować osobno |
| Kopie bazy | Instancję SQL i wszystkie 4 stare kopie usunięto 19.10.2026. Backupy/PITR Firestore pozostają wyłączone zgodnie z decyzją właściciela; ich ewentualne wdrożenie wymaga konfiguracji i testu, z retencją do 30 dni |
| Korespondencja zgłoszeń | Przyjęta zasada: 90 dni od zamknięcia; ręczna kontrola co miesiąc |
| Minimalny zapis obsługi praw | Przyjęta zasada: 12 miesięcy, tylko data, rodzaj żądania i wynik |

Ustawienia głównego magazynu logów potwierdzono przy poprzednim wdrożeniu.
Usunięcie starego SQL i jego kopii potwierdzono 19.10.2026; nie wykonano nowej kopii.
Do obsługi poczty i rejestru usunięć stosuj powyższe zasady retencji. Po odtworzeniu
bazy ponownie zastosuj usunięcia przed przywróceniem dostępu użytkownikom.
Nie wykonano jeszcze próby odtwarzania.

## Zgłoszenie usunięcia konta bez aplikacji

1. Sprawdzaj skrzynkę w dni robocze. Przyjęty cel: potwierdzenie odbioru do
   3 dni roboczych, prosta zweryfikowana sprawa do 7 dni. Terminy wynikające
   z praw użytkownika są opisane w polityce.
2. Ustal konto przez uprawniony dostęp do Firebase. Sam adres wpisany w wiadomości
   lub pole nadawcy nie potwierdzają własności konta.
3. Dla zweryfikowanego adresu wyślij osobne potwierdzenie na adres zapisany
   w Firebase. Użyj jednorazowego identyfikatora sprawy z co najmniej 32 losowych
   bajtów, ważnego 24 godziny; przechowuj tylko zabezpieczony skrót i usuń po weryfikacji.
4. Przy niezweryfikowanym adresie lub podejrzeniu przejęcia potwierdź kontrolę
   istniejącej metody logowania. Dobierz minimalny dowód do sprawy. Nie żądaj
   haseł, kodów logowania, tokenów, zdjęć ani tekstów użytkownika.
5. Po weryfikacji wykonaj usunięcie przez przygotowaną obsługę operatorską,
   korzystającą z `AccountDeletionService`. Obejmuje Firebase, sesje, instalacje,
   metadane i rekordy zakupów. Strona z e-mailem służy do zgłoszenia sprawy;
   wykonanie usunięcia następuje po weryfikacji właściciela konta.
6. Sprawdź wynik, zapisz minimum potrzebne do wykazania wykonania i ponowienia
   usunięcia po odtworzeniu kopii. Przy błędzie ponów operację.
7. Potwierdź zakończenie. Przypomnij o osobnym anulowaniu subskrypcji w Google Play
   i lokalnym usunięciu historii na pozostałych urządzeniach.

Nie przekazuj korespondencji do AI. Zabezpiecz skrzynkę MFA i ogranicz dostęp
operatorów. Nie usuwaj konta na podstawie samego zgłoszenia e-mail.

## Kontrole przed publikacją

- Potwierdź umowy, podmioty dostawców i warunki przekazywania danych poza EOG.
- Sprawdź ustawienia retencji i udostępniania danych na koncie OpenAI;
  `store=false` nie gwarantuje zerowej retencji.
- Oceń diagnostykę ML Kit w wydaniu aplikacji i potrzebę zgody; brak Firebase
  Analytics nie oznacza braku telemetrii SDK.
- Porównaj opublikowane strony z polityką, sprawdź usuwanie konta i kopie bazy.
- Uzupełnij [formularz Data Safety](google-play-data-safety.pl.md) według rzeczywistego wydania.

Podstawy przetwarzania, prawa użytkownika i źródła dostawców pozostają w pełnej
polityce. Zmiana dostawcy lub przechowywania danych wymaga aktualizacji treści
oraz ustawień usługi przed rozpoczęciem nowego przetwarzania.
