# Polityka prywatności Sedno

Wersja: 15 października 2026 r.

> Dokument uzupełniony na podstawie kodu. Pola **[DO PODANIA]** wymagają danych
> właściciela. Pola **[DO POTWIERDZENIA]** dotyczą decyzji organizacyjnych lub
> produkcji. Do ich uzupełnienia dokument pozostaje projektem. Nie stanowi
> potwierdzenia zgodności prawnej ani opisu niewdrożonych usług.

## 1. Administrator i kontakt

Administratorem danych związanych z korzystaniem z Sedno jest
**Mariusz Bąbka**, osoba fizyczna, Polska.
Adres korespondencyjny: **ul. Słowiańska 91, Modlniczka, Polska**.

W sprawach danych osobowych, realizacji praw i usunięcia konta napisz na
**mariuszbabka0@gmail.com**. Administrator nie wyznaczył inspektora ochrony danych.

Polityka jest dostępna pod adresem **[DO PODANIA: adres HTTPS polityki]**.
Strona zgłoszeń usunięcia konta: **[DO PODANIA: publiczny adres HTTPS `/usun-konto`]**.

## 2. Do czego służy Sedno

Sedno pomaga uprościć polskie teksty. Możesz wpisać lub wkleić tekst albo zrobić
zdjęcie i odczytać z niego tekst. Przed wysłaniem możesz go poprawić.
Do rozpoczęcia korzystania nie potrzebujesz konta. Logowanie przez Google lub
e-mail jest dobrowolne; konto jest potrzebne do korzystania z subskrypcji.

**Obecny stan wdrożenia:** adapter API OpenAI jest zaimplementowany, ale
konfiguracja produkcyjna domyślnie pozostawia uproszczanie wyłączone.
Nie potwierdzono uruchomienia usługi ani dostępu do modelu na koncie administratora. Demonstracyjny model działa
wyłącznie w środowisku deweloperskim. Przed uruchomieniem zewnętrznego AI
zaktualizujemy stan wdrożenia w tej polityce i aplikacji. Wybranym przez
administratora modelem jest OpenAI GPT-6 Luna (`gpt-6-luna`), przez API OpenAI.
[Oficjalna dokumentacja modelu](https://developers.openai.com/api/docs/models/gpt-6-luna).

AI może popełniać błędy. Sprawdź wynik, zanim go wykorzystasz. Sedno nie wymaga
podawania informacji o zdrowiu, niepełnosprawności ani innych danych wrażliwych.
Nie wysyłaj takich informacji ani danych innych osób, jeśli nie masz odpowiedniej
podstawy do ich przekazania. Samo korzystanie z aplikacji nie oznacza zgody na
przetwarzanie szczególnych kategorii danych.

## 3. Jakie dane przetwarzamy

### Tekst i wynik uproszczenia

Po wybraniu „Uprość” aplikacja wysyła tekst do backendu Sedno. Backend nie zapisuje
oryginału ani wyniku w bazie. Kod nie rejestruje ich w logach. Do obsługi żądania
używa treści w pamięci. Wynik trafia do aplikacji i lokalnej historii.

**AI po włączeniu konfiguracji:** tekst i instrukcja uproszczenia trafią
przez backend do API OpenAI, modelu GPT-6 Luna. Nie wyślemy zdjęcia ani całej
historii. Tryb bezpośrednich wywołań Responses API wysyła `store=false`, co nie
oznacza zerowej retencji po stronie dostawcy. Tryb zapisanego agenta (Agents API)
przechowuje treść i wynik w osobnej sesji OpenAI. Backend usuwa sesję w tle po
zakończeniu przetwarzania; przy przekroczeniu czasu lub przerwaniu zleca również
anulowanie pracy. W pamięci serwera pozostają tylko identyfikatory sesji oraz
stan ponawiania prób, bez tekstów i wyników. Nie zapisujemy tabeli kolejki.
Po restarcie serwer sprawdza listę sesji oznaczonych jako uproszczenia Sedno
u dostawcy i ponawia sprzątanie. Odzyskiwane sesje usuwa po upływie co najmniej
minuty od utworzenia. Nieudane próby ponawia z wydłużanym odstępem.
Awaria, zatrzymany backend lub niedostępność dostawcy mogą opóźnić usunięcie.
Nie gwarantuje to natychmiastowego fizycznego usunięcia; operator kontroluje
pozostałości, w tym starsze sesje bez oznaczenia Sedno.
Także utrata odpowiedzi na utworzenie sesji może pozostawić przesłany tekst
u dostawcy bez identyfikatora sesji znanego backendowi.
Obecność adaptera nie potwierdza uruchomienia integracji na serwerze.

OpenAI opisuje brak używania danych API do trenowania domyślnie. Standardowe
logi bezpieczeństwa mogą zawierać treści i być zachowywane do 30 dni, z wyjątkami
opisanymi przez dostawcę. Nie deklarujemy przetwarzania wyłącznie w pamięci po
stronie OpenAI. **[DO POTWIERDZENIA: podmiot umowny, region i ustawienia projektu,
retencja stanu wybranego endpointu, wyłączone udostępnianie danych do trenowania]**.
[Zasady danych API OpenAI](https://developers.openai.com/api/docs/guides/your-data).

### Zdjęcia, aparat i rozpoznawanie tekstu

Dostęp do aparatu służy wykonaniu zdjęcia do odczytu tekstu. Zdjęcie, kadrowanie
oraz OCR są przetwarzane na urządzeniu. Sedno nie wysyła zdjęć do backendu ani
nie ma endpointu do ich przesyłania. Po odczycie, anulowaniu lub błędzie kod
podejmuje próbę usunięcia roboczych kopii zdjęcia. Nie oznacza to usunięcia
odrębnej kopii zapisanej przez zewnętrzną aplikację aparatu.

Rozpoznawanie korzysta z Google ML Kit. Lokalny OCR nie oznacza braku połączeń
sieciowych SDK: Google opisuje wysyłanie metryk technicznych i użycia, bez
wysyłania obrazu ani odczytanej treści. [Zasady ML Kit](https://developers.google.com/ml-kit/terms).

### Historia i dane na urządzeniu

Historia zawiera oryginalny tekst, wynik, identyfikator i datę. Jest szyfrowana,
przechowywana wyłącznie na urządzeniu i wyłączona z kopii zapasowych Androida.
Wpisy wygasają po 7 dniach. Aplikacja nie pokazuje wygasłych wpisów i usuwa je
przy odczycie, uruchomieniu i wznowieniu. Jeśli aplikacja jest zamknięta, fizyczne
czyszczenie nastąpi przy kolejnym takim zdarzeniu.

Możesz usuwać wpisy w zakładce Historia. Wylogowanie i usunięcie konta przez
aplikację czyszczą historię na bieżącym urządzeniu. Android przechowuje również
zabezpieczone dane sesji i losowy identyfikator instalacji. Identyfikator
instalacji pozostaje po usunięciu konta; możesz usunąć go przez wyczyszczenie
danych aplikacji w ustawieniach Androida.

### Konto i logowanie

Firebase Authentication obsługuje konto e-mail/hasło albo logowanie Google.
Backend Sedno otrzymuje i zapisuje UID Firebase, sposób logowania i datę
utworzenia konta. Nie otrzymuje hasła konta Google ani hasła Firebase.
Dostawca logowania przetwarza dane potrzebne do uwierzytelnienia, w tym adres
e-mail, identyfikator konta i dane połączenia. Logowanie Google może przekazać
Firebase także dane profilu udostępnione przez Google; Sedno nie wyświetla ani
nie zapisuje w swojej bazie imienia i zdjęcia profilowego.

### Limity i ochrona usługi

Serwer zapisuje skrót HMAC identyfikatora instalacji, skróty poświadczeń sesji,
powiązanie instalacji z kontem, identyfikatory i statusy żądań, daty oraz skrót
HMAC tekstu. Skrót pomaga rozpoznać ponowienie tego samego żądania; nie jest
kopią tekstu. Dane te są pseudonimowe, a nie anonimowe. Łączenie instalacji
z kontem pozwala wspólnie rozliczać limit bez przyznawania nowego limitu za logowanie.

Adres IP jest używany przez backend do ograniczania liczby żądań. Nie jest
polem w bazie Sedno. Hosting, serwer pośredniczący lub dostawcy SDK mogą
przetwarzać go osobno. **[DO POTWIERDZENIA: zakres i retencja logów produkcyjnych]**.
Play Integrity służy sprawdzeniu autentyczności aplikacji i urządzenia oraz
ograniczaniu nadużyć. Nie przekazujemy do niego tekstu ani zdjęcia do uproszczenia.

### Subskrypcja i kontakt

Płatność obsługuje Google Play. Sedno nie zbiera numeru karty ani danych konta
bankowego. Backend zapisuje szyfrowany token zakupu, jego skrót, powiązanie z
kontem, stan i termin subskrypcji, czas ostatniej weryfikacji zakupu oraz ID obsłużonych powiadomień zakupowych.
Jeśli napiszesz do nas, dostawca poczty i administrator otrzymają adres nadawcy,
treść wiadomości oraz dane potrzebne do obsługi sprawy. Nie przesyłaj haseł,
tokenów, zdjęć ani tekstów do uproszczenia w zgłoszeniu.

### Dane techniczne SDK

ML Kit może wysyłać identyfikatory instalacji, informacje o urządzeniu i wersji
aplikacji, zdarzenia użycia OCR, kody błędów i pomiary wydajności. Nie ma w kodzie
własnego systemu reklamowego, Firebase Analytics ani Crashlytics. Nie oznacza
to wyłączenia diagnostyki dostawców. [Opis danych ML Kit](https://developers.google.com/ml-kit/android-data-disclosure).
Firebase opisuje ponadto zbieranie IP i metadanych przy logowaniu.
[Opis Firebase Authentication](https://firebase.google.com/docs/android/play-data-disclosure#authentication).

## 4. Cele i podstawy prawne

**Proponowane przypisanie dla administratora działającego w Polsce/EOG — do
potwierdzenia przed publikacją, wraz z regulaminem i oceną rzeczywistych usług:**

| Cel | Proponowana podstawa |
| --- | --- |
| Uproszczenie tekstu na żądanie, konto i obsługa subskrypcji | Art. 6 ust. 1 lit. b RODO — wykonanie umowy lub działania na żądanie użytkownika |
| Bezpieczeństwo, limity i zapobieganie nadużyciom | Art. 6 ust. 1 lit. f — uzasadniony interes ochrony usługi; wymaga oceny równowagi |
| Realizacja praw dotyczących danych | Art. 6 ust. 1 lit. c — wykonanie obowiązków administratora |
| Obsługa korespondencji i konieczna obrona roszczeń | Art. 6 ust. 1 lit. f, w niezbędnym zakresie |
| Obowiązki rozliczeniowe, jeżeli dotyczą administratora | Art. 6 ust. 1 lit. c; wskazać właściwe przepisy i okresy, jeśli mają zastosowanie |

Przed publikacją trzeba osobno ocenić podstawę diagnostyki SDK i dostępu do
informacji na urządzeniu, w tym ewentualną wymaganą zgodę. Uprawnienie aparatu
w Androidzie i komunikat o AI nie zastępują takiej analizy. Nie zakładamy zgody
na wszystkie operacje z powodu instalacji aplikacji.
[Podstawy przetwarzania — Komisja Europejska](https://commission.europa.eu/law/law-topic/data-protection/information-business-and-organisations/legal-grounds-processing-data_en).

Podanie tekstu i danych technicznych potrzebnych do żądania jest niezbędne do
jego obsługi. E-mail i logowanie są potrzebne tylko przy wyborze funkcji konta;
dane zakupu — przy subskrypcji. Możesz nie używać aparatu i wpisać tekst ręcznie.

## 5. Odbiorcy i przekazywanie danych poza EOG

Korzystamy z dostawców logowania, ochrony usługi, OCR i płatności Google oraz
**OpenAI (planowane API)** oraz Google w zakresie **Gmail** do korespondencji
pod adresem mariuszbabka0@gmail.com. Administrator wskazał Firebase jako docelową
platformę hostingu; **[DO POTWIERDZENIA: dokładne usługi, podmioty umowne i regiony
backendu ASP.NET oraz bazy PostgreSQL]**. Wybór marki Firebase nie potwierdza
miejsca przetwarzania ani uruchomienia bazy.
Dostęp mogą mieć upoważnione osoby obsługujące Sedno. Organom przekazujemy dane,
gdy wynika to z właściwego obowiązku prawnego. Nie mamy w kodzie funkcji
sprzedaży danych ani profilowania reklamowego.

Firebase Authentication działa w centrach danych w USA. Sam wybór hostingu
Sedno w UE nie wyklucza transferów poza EOG. Google Play, ML Kit i pozostali
dostawcy również wymagają oceny lokalizacji i warunków usług.
[Informacje o lokalizacji Firebase](https://firebase.google.com/support/privacy#data_storage_and_processing_locations).

**[DO POTWIERDZENIA: podmioty umowne Google i innych dostawców, ich role,
umowy powierzenia, państwa i właściwy mechanizm każdego transferu, np. decyzja
o adekwatności dla właściwego odbiorcy lub standardowe klauzule umowne oraz
sposób uzyskania kopii zabezpieczeń]**. Nie twierdzimy, że wszystkie dane
pozostają w Polsce lub EOG.

## 6. Jak długo przechowujemy dane

Poniższe okresy opisują kod Sedno, a nie nieznaną konfigurację hostingu.

| Dane | Obecny okres / sposób usunięcia |
| --- | --- |
| Oryginał i wynik na backendzie | Bez zapisu treści w bazie; użycie w pamięci do obsługi żądania |
| Lokalna historia | Wygaśnięcie po 7 dniach; czyszczenie przy odczycie, starcie i wznowieniu; możliwe wcześniejsze usunięcie |
| Robocze zdjęcia | Próba usunięcia po zakończeniu, anulowaniu lub błędzie OCR; brak gwarancji czyszczenia przy nagłym zatrzymaniu procesu |
| Metadane żądań i skróty HMAC tekstu | Starsze niż 8 dni usuwa proces wykonywany co godzinę, gdy backend pracuje |
| Sesja konta | Ważna 7 dni; sesja gościa — 90 dni; wygasłe rekordy usuwa proces godzinowy; możliwe wcześniejsze odwołanie |
| Niepowiązana tożsamość gościa | Usunięcie po przekroczeniu 90 dni od utworzenia, gdy nie ma już sesji ani żądań; może to nastąpić później niż w 90. dniu |
| Konto i powiązane instalacje | Do usunięcia konta; brak automatycznego usuwania nieaktywnych kont |
| Rekordy zakupów w bazie Sedno | Do usunięcia konta; brak automatycznego usuwania wygasłych zakupów |
| ID powiadomień Google Play | Brak wdrożonego automatycznego terminu usuwania; rekordy nie zawierają tokenu zakupu ani powiązania z kontem |
| Losowy ID instalacji na urządzeniu | Do wyczyszczenia danych aplikacji; nie jest usuwany przy usunięciu konta |

Firebase wskazuje, że IP logowania zachowuje przez kilka tygodni. Inne dane
uwierzytelnienia zachowuje do zlecenia usunięcia użytkownika, po czym usuwa je
z systemów aktywnych i kopii w ciągu 180 dni. Nie obiecujemy natychmiastowego
wymazania wszystkich kopii u dostawcy. [Retencja Firebase](https://firebase.google.com/support/privacy#data_processing_information).

**[DO POTWIERDZENIA: okresy poczty zgłoszeń, logów, kopii bazy i metryk dostawców;
zasady wyjątków prawnych oraz odtwarzania kopii z ponownym zastosowaniem usunięć]**.
Obecny kod nie ustala tych terminów. Ich przyjęcie musi odpowiadać rzeczywistym
ustawieniom i procesom; samo wpisanie okresu w polityce nie zmienia retencji.

## 7. Jak usunąć konto lub historię

W aplikacji wybierz **Konto → Usuń konto → Usuń konto i dane**. Po powodzeniu
backend usuwa tożsamość Firebase Sedno, wszystkie sesje konta, powiązane
identyfikatory instalacji, metadane żądań i rekordy zakupów. Aplikacja czyści
lokalną historię i sesję. Przy błędzie lokalnego magazynu konieczne może być
ponowienie czyszczenia. Nie usuwamy Twojego konta Google.

Bez aplikacji przejdź na stronę z punktu 1 i skorzystaj z adresu kontaktowego.
Wiadomość jest prośbą o usunięcie; nie usuwa automatycznie konta. Przed działaniem
weryfikujemy właściciela, ograniczając zakres wymaganych informacji do niezbędnego.
**[DO POTWIERDZENIA: operacyjny sposób weryfikacji i obsługi zgłoszeń]**.

Usunięcie przez stronę lub z innego urządzenia nie usuwa historii pozostającej
na pozostałych urządzeniach. Usuń ją lokalnie lub wyczyść dane aplikacji w
ustawieniach Androida. Nie możemy zdalnie odczytać ani wymazać tych lokalnych kopii.

**Usunięcie konta nie anuluje subskrypcji i nie zatrzymuje opłat Google Play.**
Otwórz **Google Play → Płatności i subskrypcje → Subskrypcje → Sedno → Anuluj
subskrypcję**. Dane transakcyjne przechowywane przez Google podlegają jego zasadom.
Nie zapewniamy automatycznego przeniesienia zakupu na nowe konto Sedno.

## 8. Twoje prawa

W zakresie wynikającym z RODO możesz żądać dostępu do danych, ich kopii,
sprostowania, usunięcia i ograniczenia przetwarzania. Prawo przenoszenia dotyczy
odpowiednich danych przetwarzanych automatycznie na podstawie umowy lub zgody.
Możesz wnieść sprzeciw wobec przetwarzania opartego na uzasadnionym interesie.
Jeżeli operacja opiera się na zgodzie, możesz ją wycofać bez wpływu na zgodność
wcześniejszego przetwarzania. Prawa podlegają warunkom i wyjątkom przepisów.

Napisz na adres z punktu 1. Odpowiadamy bez zbędnej zwłoki, co do zasady w ciągu
miesiąca od otrzymania żądania. Przy złożonej sprawie lub wielu żądaniach termin
może zostać przedłużony o dwa miesiące, z wyjaśnieniem w pierwszym miesiącu.
Masz prawo złożyć skargę do właściwego organu nadzorczego; w Polsce jest nim
Prezes Urzędu Ochrony Danych Osobowych: [uodo.gov.pl](https://uodo.gov.pl/).
[Informacja UODO o terminie odpowiedzi](https://uodo.gov.pl/pl/file/4145).

Sedno nie ma funkcji profilowania reklamowego. Automatyczna kontrola limitów
lub integralności może zablokować żądanie; w razie błędu napisz do administratora.
Nie przedstawiamy samego generowania uproszczenia jako decyzji o skutkach prawnych.

## 9. Wiek użytkowników i zmiany polityki

Aplikacja jest kierowana do osób w wieku **16 lat i więcej**: starszych
nastolatków, dorosłych i osób starszych. Nie jest kierowana do dzieci poniżej
16 lat. **[DO POTWIERDZENIA: kraje udostępnienia]**. Osoby w wieku 16–17 lat nadal są małoletnie. Sam wybór grupy
wiekowej w sklepie nie jest mechanizmem sprawdzania wieku. Obecny kod nie
sprawdza wieku ani nie obsługuje zgody opiekuna. Nie należy deklarować istnienia
takiego mechanizmu w sklepie.

Aktualizując usługę, uaktualnimy tę politykę i datę wersji. Przed uruchomieniem
nowego dostawcy lub innego celu przetwarzania zapewnimy odpowiednią informację
oraz, jeśli będzie wymagana, podstawę lub zgodę.
**[DO POTWIERDZENIA: sposób powiadamiania użytkowników o istotnych zmianach]**.


## Notatka wdrożeniowa — nie publikować jako części polityki

Propozycje retencji i obsługi zgłoszeń znajdują się w
[planie retencji i publikacji](privacy-operations-plan.pl.md). Są propozycjami,
a nie opisem już wdrożonego usuwania. Nie należy zastępować nimi tabeli obecnej
retencji bez wykonania odpowiednich zmian konfiguracji, procesów i kodu.
