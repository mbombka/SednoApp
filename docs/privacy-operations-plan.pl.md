# Sedno — proponowane zasady retencji i obsługi prywatności

Stan: 15 października 2026 r. Przygotowane dla Mariusza Bąbki na jego prośbę.
Kontakt: mariuszbabka0@gmail.com. **To plan do przyjęcia i wdrożenia, nie opis
obecnej konfiguracji. W tej zmianie nie ustawiono usług ani zadań usuwających.**

## Ustalone dane i pozostałe decyzje

| Obszar | Ustalenie |
| --- | --- |
| Administrator | Mariusz Bąbka, osoba fizyczna, Polska; bez wyznaczonego IOD |
| Kontakt prywatność/usuwanie | mariuszbabka0@gmail.com, poczta Gmail |
| Adres administratora | ul. Słowiańska 91, Modlniczka, Polska |
| AI | Wybrane OpenAI GPT-6 Luna, ID API `gpt-6-luna`; adapter istnieje; domyślnie wyłączony, wymaga klucza i odbioru jakości |
| Platforma | Zadeklarowane Firebase; dokładne usługi, region i baza nieustalone |
| Grupa docelowa | Potwierdzone 16+: starsi nastolatkowie i dorośli |
| Rynek | Polski język aplikacji potwierdzony; kraje dystrybucji jeszcze nie wskazane |
| Publiczne strony | Administrator nie ma domeny; adres opublikowanej strony nadal nieznany |
| Pakiet Android | `io.github.mbombka.sedno` w projekcie; dostępność w Google Play potwierdzona przez administratora; rejestracja nowej aplikacji Android w Firebase i certyfikaty do sprawdzenia |

Osoba fizyczna może być wskazana w informacji jako administrator; sam brak
firmy nie rozstrzyga obowiązków związanych z publiczną aplikacją i subskrypcjami.
Nie zakładamy zwolnienia z obowiązków tylko z powodu prywatnego statusu właściciela.

## Proponowana infrastruktura, bez uruchamiania usług

Firebase Hosting może obsłużyć publiczne dokumenty i przekazywać żądania do
Cloud Run. Backend ASP.NET można przygotować jako kontener dla Cloud Run.
PostgreSQL wymaga osobnej usługi; nie zmieniamy go na Firestore. Wybór dostawcy
bazy, regionów i kosztów pozostaje decyzją wdrożeniową. Nie utworzono zasobów.
[Firebase Hosting i Cloud Run](https://firebase.google.com/docs/hosting/cloud-run).

Cel lokalizacji: backend, baza i jej kopie w wybranym regionie UE, z ustawieniami
sprawdzonymi w panelach. To nie gwarantuje pozostawania wszystkich danych w EOG:
Firebase Auth ma własne lokalizacje, a Google i OpenAI własne warunki.

Dla OpenAI: nie włączać dobrowolnego udostępniania danych do trenowania;
przy implementacji sprawdzić retencję endpointu, cache i projektu. Wyłączenie
zapisu odpowiedzi przez `store: false` samo nie oznacza zerowej retencji wszystkich
systemów. Nie obiecywać ZDR ani rezydencji UE bez potwierdzenia ich dostępności
na koncie i prawidłowej konfiguracji.
Tryb `openai-agent` korzysta z Agents API i nie ma ustawienia `store=false`:
treść i wynik trafiają do sesji. Backend zleca usunięcie w bloku `finally`, z
limitem 3 sekund i maksymalnie dwiema próbami. Przy błędzie pozostawia ostrzeżenie
bez danych treści i sesji. Po awarii procesu lub błędzie usunięcia operator musi
sprawdzić i usunąć pozostałe sesje w dedykowanym projekcie; kod nie ma trwałej
kolejki usuwania ani automatycznego uzgadniania pozostawionych sesji.
[Zasady danych OpenAI API](https://developers.openai.com/api/docs/guides/your-data).

## Proponowane okresy

Okresy są decyzjami minimalizacji danych dla tej aplikacji, a nie twierdzeniem,
że konkretny przepis narzuca podaną liczbę dni. Wyjątki trzeba udokumentować.

| Dane | Propozycja | Co trzeba wdrożyć |
| --- | --- | --- |
| Lokalna historia | Pozostawić 7 dni | Mechanizm już jest; sprawdzać na Androidzie |
| Metadane żądań | Pozostawić 8 dni i czyszczenie godzinowe | Mechanizm jest; zapewnić działanie także przy skalowaniu/wyłączaniu backendu |
| Sesje | Pozostawić 7 dni dla kont i 90 dla gości | Mechanizm jest; monitorować proces czyszczenia |
| Nieaktywne konta | Usuwać po 24 miesiącach nieaktywności; powiadomienie 30 dni wcześniej, jeżeli jest dostępny bezpieczny kontakt | Brak automatyki i daty ostatniej aktywności; wymaga osobnego zadania i poinformowania użytkownika |
| Wygasłe rekordy zakupów | Usuwać 90 dni po potwierdzonym końcu uprawnienia; wcześniej przy usunięciu konta | Nowy proces, ponowna weryfikacja stanu Google przed usunięciem; nie usuwać aktywnego zakupu z powodu samej starej daty w bazie |
| ID powiadomień Pub/Sub | 30 dni od przetworzenia | Dodać czyszczenie i sprawdzić maksymalny okres ponowień transportu; nie usuwać identyfikatorów potrzebnych do obsługi faktycznych ponowień |
| Logi techniczne Sedno/proxy | 30 dni; bez treści, poświadczeń i pełnych URL dostawcy zawierających tokeny | Ustawić retencję każdego magazynu, także eksportów; zminimalizować IP i identyfikatory |
| Kopie PostgreSQL | Rotacja do 30 dni; usunięcie po wygaśnięciu kopii, bez zwykłego przywracania skasowanych kont do usługi | Ustawić backupy i ewidencję usunięć do ponownego zastosowania po odtworzeniu; zabezpieczyć ją i usuwać po wygaśnięciu właściwych kopii |
| Zgłoszenia Gmail | 90 dni od zamknięcia sprawy | Ręczna kontrola raz w miesiącu lub automat; usuwać także załączniki i kopie robocze, opróżniać kosz |
| Minimalne potwierdzenie obsługi praw | 12 miesięcy od zamknięcia: data, rodzaj żądania i wynik, bez hasła, tokenu czy pełnej korespondencji | Osobna ograniczona ewidencja, dostęp tylko administratora; potwierdzić potrzebę i podstawę przed przyjęciem |

Jeśli sprawa wymaga zachowania dowodów dla konkretnego roszczenia lub obowiązku
prawnego, określić osobno zakres, podstawę i termin; nie przedłużać całej retencji
„na wszelki wypadek”. Własne terminy nie zmieniają okresów u Google/OpenAI.
Nie wprowadzać do polityki publicznej powyższych terminów jako obowiązujących,
dopóki nie zostaną faktycznie skonfigurowane.

## Obsługa żądań przez Gmail — proponowana procedura

1. Sprawdzać skrzynkę w dni robocze. Przyjąć cel potwierdzenia otrzymania w ciągu
   3 dni roboczych; nie jest to termin zaprogramowany w aplikacji.
2. Wyjaśnić, jakie konto i dane obejmuje żądanie. Nie żądać zdjęć dokumentów,
   hasła, kodu logowania, tokenu ani tekstów do uproszczenia jako standardowej weryfikacji.
3. Zweryfikować właściciela konta. Preferować usunięcie po zalogowaniu w aplikacji;
   osoba bez aplikacji musi mieć rzeczywistą alternatywę. Sam podany e-mail nie
   wystarcza. Potrzebny jest oddzielny, bezpieczny proces potwierdzenia kontroli
   nad metodą logowania; kod nie ma jeszcze portalu ani narzędzia operatorskiego.
4. Po weryfikacji wykonać tę samą operację usuwania Firebase i danych PostgreSQL,
   z autoryzowanym dostępem operatora. Nie tworzyć publicznego endpointu usuwającego
   konto z samego e-maila. Przygotować i przetestować procedurę operatorską przed startem.
5. Potwierdzić wykonanie lub wyjaśnić błąd/uzasadniony wyjątek. Poinformować o
   lokalnej historii na pozostałych urządzeniach oraz osobnym anulowaniu subskrypcji.
6. Pilnować odpowiedzi w terminach z polityki. Cel operacyjny: zakończyć prostą,
   zweryfikowaną sprawę w 7 dni; nie jest to obietnica natychmiastowego wymazania
   kopii u dostawców. Gdy brakuje weryfikacji, komunikować to bez zbędnej zwłoki.
7. Po zamknięciu stosować powyższą retencję poczty i minimalnej ewidencji.

Zabezpieczyć Gmail silnym uwierzytelnieniem wieloskładnikowym, nie udostępniać
skrzynki innym osobom, wyłączyć niepotrzebne przekazywanie wiadomości i nie
wklejać zgłoszeń do narzędzi AI. Dla większej skali rozważyć osobny adres domenowy;
nie zmienia to wskazanego obecnie adresu kontaktowego.

## Wiek i opis sklepu

Administrator wybrał **16+**. Docelowe grupy w Play Console: „16–17” i „18 i więcej”, o ile
odpowiadają faktycznym rynkom i zasadom sklepu. Wybór 16+ nie gwarantuje wyłączenia
obowiązków dotyczących małoletnich w każdym kraju. Gdy celem są wyłącznie dorośli,
należy wybrać 18+. Nie utożsamiać wieku zgody na dane z pełnoletnością, uprawnieniem
do zawarcia umowy/subskrypcji ani klasyfikacją treści PEGI/IARC.
[Grupa docelowa Google Play](https://support.google.com/googleplay/android-developer/answer/9867159?hl=en).

Opis i grafiki powinny odpowiadać zadeklarowanej grupie. Aplikacja nie ma kontroli
wieku. Nie publikować zdania, że młodsi technicznie nie mogą z niej korzystać.
Nie zbierać daty urodzenia bez potrzeby tylko po to, by uzupełnić dokumentację.

## Kolejność przed publikacją

1. Ustalić publiczne adresy stron i kraje dystrybucji. Adres administratora
   oraz wiek 16+ są już potwierdzone. Zarejestrować docelowy pakiet `io.github.mbombka.sedno` w Firebase i sprawdzić
   certyfikaty, konfigurację OAuth oraz wartości pakietu w backendzie.
2. Wybrać dokładne usługi/regiony i sprawdzić umowy oraz mechanizmy transferów.
3. Potwierdzić podstawy prawne i ocenę diagnostyki SDK, w tym potrzebę zgody;
   przyjąć właściwe zasady wraz z regulaminem.
4. Wdrożyć retencję i obsługę żądań bez aplikacji, w tym narzędzie/procedurę operatora.
5. Uruchomić AI dopiero z właściwą informacją o dostawcy i retencji; przetestować
   brak tekstów i sekretów w logach wszystkich warstw.
6. Zaktualizować ekran prywatności i stronę usuwania, które nadal mają robocze
   informacje z zadania 11; opublikować dokumenty i wtedy wysłać Data Safety.
