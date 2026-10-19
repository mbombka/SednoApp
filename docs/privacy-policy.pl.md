# Polityka prywatności Sedno

Wersja: 19 października 2026 r.

## Administrator i kontakt

Administrator: Mariusz Bąbka, osoba fizyczna, ul. Słowiańska 91, Modlniczka, Polska. Kontakt w sprawach prywatności i usunięcia konta: contact@sedno.xyz. Administrator nie wyznaczył inspektora ochrony danych.

Polityka dotyczy aplikacji Sedno i obsługi jej użytkowników. Pierwszym wybranym rynkiem jest Polska. Aplikacja jest przeznaczona dla osób od 16. roku życia. Osoby w wieku 16–17 lat powinny korzystać z niej za zgodą rodzica lub opiekuna. Aplikacja nie sprawdza wieku ani nie zbiera daty urodzenia.

Informacje o prywatności na stronie: https://sedno.xyz/#prywatnosc. Strona zawiera krótkie podsumowanie; pełna treść zasad jest dostępna na tym ekranie. Instrukcja usunięcia konta jest dostępna pod adresem https://sedno.xyz/usun-konto. Serwer działa od 19 października 2026 r.; płatności Google Play pozostają wyłączone do zakończenia konfiguracji i testów.

## Tekst i sztuczna inteligencja

Twój tekst trafi przez serwer Sedno do dostawcy AI — OpenAI, aby go uprościć. Nie wpisuj danych, których nie chcesz przekazywać. Zdjęcia zostają na urządzeniu. AI może popełniać błędy. Sprawdź wynik.

Po wybraniu „Uprość” tekst jest przesyłany przez serwer Sedno do OpenAI Responses API. Wynik wraca do aplikacji. Serwer Sedno używa treści do obsługi żądania, ale nie zapisuje oryginału ani wyniku w bazie ani w logach. Nie przekazujemy całej historii ani zdjęć.

Wyłączenie zapisu odpowiedzi w API nie oznacza braku retencji u dostawcy. OpenAI domyślnie nie używa danych API do trenowania modeli. Logi bezpieczeństwa mogą zawierać treści do 30 dni, z wyjątkami określonymi przez dostawcę. Mechanizmy cache mogą przechowywać stan przejściowy. Nie deklarujemy zerowej retencji ani przetwarzania OpenAI wyłącznie w Unii Europejskiej.

Nie przesyłaj danych o zdrowiu, niepełnosprawności ani innych szczególnie chronionych informacji. Przed wysłaniem usuń zbędne dane osobowe i dane innych osób. Korzystanie z Sedno nie oznacza zgody na przetwarzanie wszystkich kategorii danych.

## Usuwanie konta i danych

Usuniemy konto Sedno, jego dane na serwerze i lokalną historię na tym urządzeniu. Tej czynności nie można cofnąć. Usunięcie konta nie anuluje subskrypcji. Aby zatrzymać opłaty, otwórz Google Play → Płatności i subskrypcje → Subskrypcje → Sedno → Anuluj subskrypcję.

W aplikacji wybierz Konto → Usuń konto → Usuń konto i dane. Po powodzeniu usuwamy tożsamość Sedno w Firebase, sesje konta, powiązane instalacje, metadane żądań oraz rekordy zakupów w bazie Sedno. Nie usuwamy Twojego konta Google.

Bez aplikacji napisz na contact@sedno.xyz z tematem „Usunięcie konta Sedno”. Podaj e-mail używany do logowania. Nie wysyłaj hasła, kodów logowania, tokenów, dokumentu tożsamości, zdjęć ani tekstów do uproszczenia. Samo wysłanie wiadomości nie usuwa konta. Przed usunięciem potwierdzimy, że kontrolujesz konto; w razie wątpliwości poprosimy tylko o dodatkowe informacje niezbędne do weryfikacji.

Usunięcie konta przez e-mail lub na innym urządzeniu nie usuwa historii na pozostałych urządzeniach. Usuń ją w Historii albo wyczyść dane aplikacji w ustawieniach Androida. Nie mamy zdalnego dostępu do lokalnej historii. Zakupy i dane zachowane przez Google podlegają zasadom Google.

## Zdjęcia i historia na urządzeniu

Zdjęcia, kadrowanie i rozpoznawanie tekstu odbywają się na urządzeniu. Sedno nie wysyła zdjęć do serwera ani dostawcy AI. Rozpoznany tekst trafia od razu do uproszczenia. Po błędzie lub anulowaniu możesz go poprawić. Po odczycie, anulowaniu lub błędzie aplikacja podejmuje próbę usunięcia kopii roboczych zdjęcia; nagłe zatrzymanie procesu może przerwać czyszczenie. Osobne kopie zapisane przez aplikację aparatu pozostają pod Twoją kontrolą.

Historia zawiera oryginał, uproszczenie i datę. Jest szyfrowana, lokalna i wyłączona z kopii zapasowych Androida. Wpis wygasa po 7 dniach. Wygasłe wpisy nie są wyświetlane; czyszczenie następuje przy odczycie, uruchomieniu i wznowieniu aplikacji. Gdy aplikacja jest zamknięta, usunięcie następuje przy następnym takim zdarzeniu. Możesz usunąć wpisy wcześniej. Wylogowanie czyści lokalną historię.

Urządzenie przechowuje też zabezpieczoną sesję i losowy identyfikator instalacji. Samo usunięcie konta nie usuwa tego losowego identyfikatora z urządzenia. Usuniesz go, czyszcząc dane aplikacji w Androidzie.

## Konto, limity i subskrypcja

Możesz zacząć bez konta. Firebase Authentication obsługuje dobrowolne logowanie Google albo e-mail i hasło. Sedno zapisuje identyfikator UID Firebase, sposób logowania i datę utworzenia konta. Serwer Sedno nie otrzymuje hasła Google ani Firebase. Google może przetwarzać e-mail, dane profilu, adres IP i dane połączenia potrzebne do logowania.

Do ochrony usługi i rozliczania limitów zapisujemy pseudonimowe dane instalacji, sesji i żądań, ich daty, statusy oraz skrót HMAC tekstu. Skrót nie jest kopią tekstu. Identyfikator instalacji jest pseudonimowy, a nie anonimowy. Logowanie nie przyznaje nowego darmowego limitu. Adres IP służy ograniczaniu liczby żądań; nie jest polem bazy Sedno, ale może być przetwarzany przez dostawców infrastruktury. Google Play Integrity sprawdza autentyczność aplikacji i urządzenia, bez otrzymywania tekstu ani zdjęcia.

Google Play obsługuje płatność i subskrypcję. Sedno nie otrzymuje numeru karty ani danych konta bankowego. Baza Sedno przechowuje szyfrowany token zakupu, jego skrót, powiązanie z kontem, stan i termin uprawnienia oraz dane weryfikacji. Osobne identyfikatory powiadomień zakupowych zapobiegają powtórnej obsłudze zdarzeń.

## Dostawcy i dane techniczne

OpenAI obsługuje uproszczenie tekstu przez API. Dla standardowej umowy klienta z Polski podmiotem umownym wskazanym w warunkach OpenAI jest OpenAI Ireland Ltd. Dostawca przetwarza treść na potrzeby wykonania usługi oraz dane niezbędne do bezpieczeństwa zgodnie ze swoimi warunkami.

Google obsługuje Firebase Authentication, Google Sign-In, ML Kit, Play Integrity i Google Play. Google Ireland Limited i Google LLC uczestniczą w świadczeniu usług zgodnie z warunkami odpowiednich produktów. OVHcloud obsługuje pocztę administratora w domenie sedno.xyz.

ML Kit rozpoznaje tekst na urządzeniu. SDK może przekazywać Google metryki techniczne i użycia, na przykład identyfikatory instalacji, model urządzenia, wersję aplikacji, błędy i czas działania. Lokalny OCR nie oznacza braku takiej komunikacji. Zdjęcie i rozpoznana treść nie są częścią tej telemetrii. Nie integrujemy reklam, Firebase Analytics ani Crashlytics.

Infrastruktura Sedno: Google Cloud Run dla serwera, Cloud Firestore Standard w regionie europe-central2 (Warszawa) oraz Firebase Hosting udostępniający API i dokumenty. Według standardowych warunków Google Cloud dla polskiego adresu rozliczeniowego podmiotem umownym jest Google Cloud Poland Sp. z o.o. Serwer działa od 19 października 2026 r. Ta wersja informacji jest przeznaczona do publikacji wraz z migracją bazy do Firestore. Uruchomienie zasobów nie potwierdza zawarcia wszystkich wymaganych umów ani zakończenia kontroli przed publikacją aplikacji.

## Cele i podstawy przetwarzania

Uproszczenie tekstu na Twoje żądanie, prowadzenie konta i obsługa uprawnienia do subskrypcji: art. 6 ust. 1 lit. b RODO — wykonanie umowy o usługę lub działania podejmowane na Twoje żądanie.

Bezpieczeństwo, przeciwdziałanie nadużyciom i rozliczanie limitów: art. 6 ust. 1 lit. f RODO — uzasadniony interes ochrony usługi. Ograniczamy dane do niezbędnych metadanych i nie wykorzystujemy ich do reklamy. Możesz zgłosić sprzeciw, który ocenimy w odniesieniu do konkretnej sytuacji.

Odpowiedzi na zwykłe pytania i niezbędna obsługa problemów: art. 6 ust. 1 lit. f RODO — kontakt i zapewnienie działania usługi. Realizacja praw dotyczących danych: art. 6 ust. 1 lit. c w związku z art. 12–22 RODO. Minimalny zapis obsługi żądania służy wykazaniu jego wykonania na podstawie art. 5 ust. 2 i art. 24 RODO.

Nie traktujemy instalacji, komunikatu o AI ani uprawnienia aparatu jako zgody na dowolne przetwarzanie. Ocena, czy konkretna diagnostyka SDK wymaga odrębnej zgody na dostęp do urządzenia, musi poprzedzić udostępnienie tej funkcji w produkcji. Sama ta polityka nie zastępuje mechanizmu wymaganej zgody.

Tekst i niezbędne dane techniczne są potrzebne do wykonania uproszczenia. Konto i dane zakupu są potrzebne tylko przy korzystaniu z odpowiednich funkcji. Aparat jest opcjonalny — możesz wpisać lub wkleić tekst. Sedno nie korzysta z profilowania reklamowego ani nie podejmuje decyzji o skutkach prawnych na podstawie treści uproszczenia. Błędną blokadę limitu lub ochrony usługi możesz zgłosić administratorowi.

## Dane poza Europejskim Obszarem Gospodarczym

Usługi Google i OpenAI mogą przetwarzać dane poza EOG, w tym w USA. Firebase Authentication korzysta z infrastruktury w USA. Umieszczenie bazy Sedno w Warszawie nie oznacza, że wszystkie dane pozostają w Polsce lub EOG.

Przed uruchomieniem produkcji wymagane jest zastosowanie warunków powierzenia oraz właściwych zabezpieczeń transferu. Dostawcy opisują standardowe klauzule umowne i decyzje o adekwatności dla objętych nimi odbiorców. Nie deklarujemy, że samo korzystanie z marki Google lub OpenAI zapewnia konkretny mechanizm dla każdego transferu. Informacje o warunkach i kopię stosowanych zabezpieczeń możesz uzyskać u administratora. Publiczne warunki dostawców podano na końcu dokumentu.

## Retencja w aplikacji i bazie Sedno

Tekst i wynik na serwerze Sedno: bez zapisu treści, użycie w pamięci do obsługi żądania. Lokalna historia: 7 dni, z czyszczeniem opisanym wyżej. Metadane żądań i skróty HMAC tekstu: starsze niż 8 dni usuwa osobne zadanie uruchamiane co godzinę, niezależnie od ruchu w aplikacji. Dzienne liczniki i rezerwacje limitów są przechowywane do 8 dni.

Sesja konta jest ważna 7 dni, a gościa 90 dni; wygasłe sesje usuwa to samo godzinowe zadanie. Wygasła sesja nie daje dostępu, również przed fizycznym usunięciem rekordu. Niepowiązana tożsamość gościa starsza niż 90 dni jest usuwana, gdy nie ma już sesji ani żądań. Może to nastąpić później niż w 90. dniu.

Konto i powiązane instalacje oraz rekordy zakupów Sedno: do usunięcia konta. Obecna aplikacja nie usuwa automatycznie nieaktywnych kont ani wygasłych rekordów zakupów. Techniczne identyfikatory powiadomień Google Play nie mają obecnie automatycznego terminu usunięcia; nie zawierają tokenu zakupu ani powiązania z kontem. Nie przypisujemy tym danym niewdrożonych terminów.

## Wybrane zasady retencji operacyjnej

Dla wdrożenia produkcyjnego przyjmujemy: logi techniczne i kopie bazy do 30 dni; korespondencja do 90 dni od zamknięcia sprawy; minimalne potwierdzenie obsługi praw do 12 miesięcy od zamknięcia. W potwierdzeniu pozostają tylko data, rodzaj żądania i wynik, bez pełnej korespondencji. Są to przyjęte zasady organizacyjne. Dla głównego magazynu logów ustawiono 30 dni. Kopie poprzedniej bazy SQL nie obejmują Firestore. Nowe kopie i odtwarzanie wymagają osobnej konfiguracji; nie deklarujemy, że są automatycznie włączone. Przy ich włączeniu obowiązuje górna granica 30 dni. Pozostałe magazyny, eksporty oraz zasady obsługi poczty wymagają osobnej kontroli i zastosowania przed publikacją aplikacji.

Kopie są przeznaczone do odtwarzania po awarii, nie do bieżącego korzystania z usuniętych kont. Przy odtworzeniu trzeba ponownie zastosować usunięcia przed udostępnieniem danych. Dla konkretnego obowiązku prawnego lub sporu można zachować tylko niezbędne dane na czas wynikający z tego obowiązku lub sprawy; nie przedłużamy całej retencji bez potrzeby.

Własne terminy Sedno nie zmieniają okresów dostawców. Firebase opisuje retencję IP logowania przez kilka tygodni, a innych danych uwierzytelnienia do zlecenia usunięcia użytkownika, po którym usuwanie z systemów aktywnych i kopii może trwać do 180 dni. Retencję OpenAI opisano w części o AI; dane płatnicze i metryki Google podlegają zasadom odpowiednich usług.

## Twoje prawa i kontakt

W zakresie wynikającym z RODO możesz żądać dostępu do danych i ich kopii, sprostowania, usunięcia, ograniczenia przetwarzania oraz przeniesienia odpowiednich danych. Możesz wnieść sprzeciw wobec przetwarzania opartego na uzasadnionym interesie. Jeśli operacja opiera się na zgodzie, możesz ją wycofać bez wpływu na wcześniejsze przetwarzanie. Prawa podlegają warunkom i wyjątkom przepisów.

Napisz na contact@sedno.xyz. Odpowiadamy bez zbędnej zwłoki, co do zasady w ciągu miesiąca od otrzymania żądania. W przypadkach przewidzianych przez RODO termin można przedłużyć o dwa miesiące; o przyczynie poinformujemy w pierwszym miesiącu. W razie uzasadnionych wątpliwości dotyczących tożsamości poprosimy o niezbędne potwierdzenie, bez rutynowego żądania dokumentu tożsamości.

Możesz złożyć skargę do Prezesa Urzędu Ochrony Danych Osobowych: https://uodo.gov.pl. Zwykła wiadomość dotycząca danych nie wymaga podawania tekstów, które upraszczasz.

## Zmiany polityki

Każda wersja ma datę. Istotne zmiany ogłosimy na stronie prywatności i w informacjach do aktualizacji aplikacji przed rozpoczęciem nowego przetwarzania. Gdy zmiana wymaga zgody, sama aktualizacja dokumentu jej nie zastępuje. Zmiana dostawcy, celu lub retencji wymaga aktualizacji informacji i rzeczywistej konfiguracji usługi.

## Źródła i warunki dostawców

- [Podstawy przetwarzania — Komisja Europejska](https://commission.europa.eu/law/law-topic/data-protection/information-business-and-organisations/legal-grounds-processing-data_en)
- [Zasady danych OpenAI API](https://developers.openai.com/api/docs/guides/your-data)
- [Umowa usług OpenAI](https://openai.com/policies/services-agreement/)
- [Prywatność Firebase](https://firebase.google.com/support/privacy)
- [Dane techniczne ML Kit](https://developers.google.com/ml-kit/android-data-disclosure)
- [Podmioty umowne Google Cloud](https://cloud.google.com/terms/google-entity)
- [Warunki przetwarzania Google Cloud](https://cloud.google.com/terms/data-processing-addendum)
- [Zasady transferów Google](https://policies.google.com/privacy/frameworks?hl=pl)
