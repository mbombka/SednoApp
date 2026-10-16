# Sedno — wybrane zasady i wdrożenie prywatności

16 października 2026 r. Administrator potwierdził dane i zlecił samodzielny wybór
brakujących zasad. Nie wymaga to ponownego zbierania danych właściciela.
Obywatelstwo nie jest potrzebne w publicznej informacji; wskazujemy Mariusza Bąbkę
jako osobę fizyczną. Brak firmy nie oznacza automatycznego zwolnienia z obowiązków
związanych z publiczną usługą, płatnościami czy danymi.

## Wybrane decyzje i stan

| Obszar | Decyzja | Stan |
| --- | --- | --- |
| Administrator | Mariusz Bąbka, ul. Słowiańska 91, Modlniczka, Polska; bez IOD | Potwierdzone przez właściciela |
| Kontakt | mariuszbabka0@gmail.com | Potwierdzony; Gmail wymaga obsługi i MFA |
| Rynek i wiek | Pierwszy rynek: Polska; 16+; 16–17 za zgodą opiekuna | Wybrano; ustawienia Play Console i warunki usługi do zastosowania |
| Informacje o prywatności | https://sedno.xyz/#prywatnosc | Podsumowanie odczytane przez HTTPS 16.10.2026; pełna polityka gotowa lokalnie i w aplikacji |
| Usuwanie | https://sedno.xyz/usun-konto | Treść i HTML gotowe lokalnie; backend ma publiczną trasę; publikacja niepotwierdzona |
| Strona dokumentów | Firebase Hosting, własna domena i HTTPS | Wybór; nie utworzono zasobów ani certyfikatu |
| Serwer | Google Cloud Run, europe-central2 (Warszawa) | Wybór; brak wdrożenia w tej zmianie |
| Baza | Cloud SQL for PostgreSQL, europe-central2; kopie w tym regionie | Wybór; brak instancji i konfiguracji kopii |
| AI | OpenAI Responses, gpt-6-luna, store=false, bez rozmów; standardowa retencja dostawcy | Kod gotowy; nie deklarujemy ZDR ani rezydencji UE bez kwalifikacji projektu |
| Diagnostyka SDK | Bez reklam i własnej analityki; ocena konkretnego APK oraz potrzeby zgody przed udostępnieniem OCR | Nie rozstrzygamy spełnienia wymagań prawnych samą treścią polityki |
| Zmiany polityki | Data wersji, strona prywatności i informacje do aktualizacji przed zmianą przetwarzania | Wybrany sposób komunikacji; publikacja jest czynnością administratora |

Cloud Run i Cloud SQL obsługują wybrany region:
[Cloud Run](https://docs.cloud.google.com/run/docs/locations),
[Cloud SQL](https://docs.cloud.google.com/sql/docs/postgres/locations).
Jest to wybór miejsca własnego backendu, a nie obietnica pozostawania wszystkich
danych w EOG. Firebase Authentication i globalni dostawcy mają osobne zasady.
Nie utworzono płatnych usług ani nie zmieniono kont Google/OpenAI.

## Retencja

| Dane | Przyjęta zasada | Realizacja |
| --- | --- | --- |
| Historia lokalna | 7 dni; ręczne usunięcie, wylogowanie | Istniejący kod; czyszczenie przy odczycie, starcie i wznowieniu |
| Metadane żądań | 8 dni; proces co godzinę | Istniejący kod; zapewnić jego pracę w produkcji |
| Sesje | Konto 7 dni, gość 90 dni | Istniejący kod; wygasłe rekordy usuwa proces godzinowy |
| Niepowiązani goście | Ponad 90 dni i brak sesji/żądań | Istniejący kod; nie obiecujemy usunięcia dokładnie w 90. dniu |
| Konta i rekordy zakupów | Do usunięcia konta | Pozostawiono rzeczywiste działanie; nie obiecujemy automatyki po nieaktywności |
| ID powiadomień zakupowych | Obecnie bez automatycznego terminu | Jawnie opisane w polityce; automatyczna retencja wymaga osobnego zadania |
| Logi własnego hostingu/proxy | Maksymalnie 30 dni, bez treści i poświadczeń | Wymaga konfiguracji każdego magazynu i eksportu przed startem |
| Kopie bazy | Maksymalnie 30 dni, rotacja i ponowne zastosowanie usunięć po odtworzeniu | Wymaga konfiguracji backupów i zabezpieczonego rejestru usunięć |
| Poczta zgłoszeń | 90 dni od zamknięcia sprawy | Ręczna kontrola miesięczna; usuwanie kopii, załączników i opróżnianie kosza |
| Minimalna ewidencja obsługi praw | 12 miesięcy; data, rodzaj żądania, wynik | Ograniczony dostęp; bez pełnej korespondencji, haseł i tokenów |

Terminy operacyjne wybrano jako zasady minimalizacji; nie są twierdzeniem,
że konkretny przepis zawsze wymaga tych okresów. Rzeczywisty wyjątek prawny
lub roszczenie wymaga określenia celu, zakresu i terminu. Nie zachowywać całej
korespondencji lub bazy „na wszelki wypadek”. Terminy Sedno nie zmieniają retencji
Google/OpenAI. Przed udostępnieniem usługi trzeba zastosować wybrane ustawienia,
a nie tylko opublikować dokument. Nie należy oznaczać poniższych prac jako
wykonanych bez dowodu w konfiguracji usług.

## Procedura zgłoszenia bez aplikacji

1. Skrzynkę sprawdzać w dni robocze. Cel organizacyjny: potwierdzenie odbioru
   w 3 dni robocze, prosta zweryfikowana sprawa w 7 dni. Wiążące terminy odpowiedzi
   wynikają z RODO, co do zasady miesiąc; ewentualne przedłużenie wyjaśnić w pierwszym miesiącu.
2. Ustalić cel żądania, e-mail konta i UID w Firebase przez uprawniony dostęp.
   Nie usuwać danych na podstawie samej wiadomości z podanym e-mailem ani nagłówka From.
3. Dla konta z potwierdzonym adresem e-mail wysłać nowe, odrębne potwierdzenie
   na adres zapisany i zweryfikowany w Firebase, nie na adres wskazany tylko w zgłoszeniu.
   Potwierdzenie powinno zawierać losowy jednorazowy identyfikator sprawy (co najmniej
   32 losowe bajty), wygasać po 24 godzinach i wymagać odesłania potwierdzenia zamiaru
   usunięcia. Nie jest to hasło ani kod logowania Google/Firebase. Przechowywać
   tylko zabezpieczony skrót do chwili weryfikacji lub wygaśnięcia, nie wpisywać do logów.
4. Gdy adres nie jest zweryfikowany, konto ma sporne powiązania lub istnieje podejrzenie
   przejęcia, nie polegać na samym dostępie do skrzynki. Potwierdzić kontrolę istniejącej
   metody logowania; można zaproponować ponowne logowanie w aplikacji, ale zgłoszenie
   bez aplikacji pozostaje otwarte. Dobrać minimalny inny dowód do konkretnej sprawy;
   nie żądać rutynowo dokumentu tożsamości, haseł, kodów 2FA lub tekstów użytkownika.
5. Uprawniony administrator wykonuje usunięcie tożsamości Firebase i powiązanych
   danych PostgreSQL z użyciem istniejącej logiki `AccountDeletionService`, która
   obsługuje blokady, kaskady i ponowienie po błędzie Firebase. Obsługę operatorską
   należy przygotować i przećwiczyć w środowisku testowym przed startem: obecna
   strona jest instrukcją kontaktu, nie automatycznym portalem ani narzędziem operatora.
   Nie udostępniać publicznego endpointu usuwającego konto na podstawie e-maila.
6. Sprawdzić, że usunięto sesje, powiązane instalacje, żądania i rekordy zakupów;
   zachować minimalny zapis wykonania oraz wpis potrzebny do ponowienia usunięcia
   po odtworzeniu kopii. Przy błędzie ponowić operację i poinformować użytkownika.
7. Potwierdzić wynik; przypomnieć, że historia na innych urządzeniach wymaga
   lokalnego usunięcia, a subskrypcję trzeba anulować osobno w Google Play.
8. Zamknąć sprawę, usunąć jednorazowy identyfikator weryfikacji i rozpocząć retencję
   90 dni korespondencji oraz 12 miesięcy minimalnej ewidencji. Nigdy nie kopiować
   zgłoszeń do narzędzi AI.

Ta procedura określa sposób pracy administratora. Nie uruchomiono wysyłki
potwierdzeń, panelu operatora ani automatyki pocztowej w tej zmianie.

## Uzasadnienie podstaw i warunki uruchomienia

Usługa, konto i subskrypcja: art. 6 ust. 1 lit. b RODO. Ochrona usługi i limity:
art. 6 ust. 1 lit. f. Obsługa praw: art. 6 ust. 1 lit. c i art. 12–22; minimalna
ewidencja ich wykonania służy rozliczalności. Nie dopisujemy nieustalonych
obowiązków podatkowych jako uniwersalnego powodu zatrzymywania danych. Sam brak
firmy nie rozstrzyga sposobu rozliczania subskrypcji.

Ocena interesu dla bezpieczeństwa: ograniczenie oszustw i współdzielenie limitu
między instalacjami są potrzebne do działania usługi. Mniej ingerującym rozwiązaniem
od treści w logach są keyed hashe, krótkie metadane, ograniczona retencja i brak
reklamowego łączenia danych. Ryzyko błędnego blokowania ogranicza kontakt
z administratorem i brak decyzji o skutkach prawnych. Właściciel powinien zachować
tę ocenę i ponawiać ją po zmianie celu, zakresu lub grupy odbiorców.
[Podstawy — Komisja Europejska](https://commission.europa.eu/law/law-topic/data-protection/information-business-and-organisations/legal-grounds-processing-data_en).

Diagnostyka ML Kit wymaga osobnej analizy konkretnej wersji SDK i reguł dostępu
do urządzenia, w tym polskiego Prawa komunikacji elektronicznej. Nie uznajemy jej
za dowolnie dozwoloną tylko na podstawie art. 6 ust. 1 lit. f. Jeśli jest wymagana
odrębna zgoda, produkcyjny OCR może zostać udostępniony dopiero po jej wdrożeniu
albo po zmianie narzędzia; wpisywanie tekstu pozostaje alternatywą. Nie dodano
pozornego przełącznika, który nie wyłącza rzeczywistej telemetrii SDK.
[Zakres danych ML Kit](https://developers.google.com/ml-kit/android-data-disclosure),
[art. 399 PKE](https://eli.gov.pl/api/acts/DU/2024/1221/text.html).

Przed produkcyjnym startem: zastosować właściwe umowy powierzenia, odnotować
rzeczywiste podmioty umowne i mechanizmy transferu, potwierdzić ustawienia OpenAI
(bez dobrowolnego udostępniania danych do treningu), opublikować HTTPS i ustawić
linki w Play Console, skonfigurować retencję i sprawdzić usuwanie oraz odtwarzanie
kopii. Standardowe warunki wskazują OpenAI Ireland Ltd. dla klienta z EOG oraz
Google Cloud Poland Sp. z o.o. dla standardowej umowy Cloud z polskim adresem
rozliczeniowym; należy sprawdzić własny formularz zamówienia i warunki każdej usługi.
Nie deklarujemy zawarcia umów, które nie zostały sprawdzone.
