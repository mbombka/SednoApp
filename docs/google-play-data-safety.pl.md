# Sedno — przygotowane odpowiedzi Google Play Data Safety

Stan: 15 października 2026 r. Administrator: Mariusz Bąbka, Polska.
Adres administratora: **ul. Słowiańska 91, Modlniczka, Polska**.
Kontakt do danych i usuwania konta: **mariuszbabka0@gmail.com**.
Grupa docelowa potwierdzona przez administratora: **16+**.
Docelowy identyfikator aplikacji Android (`applicationId` i `namespace`):
**`io.github.mbombka.sedno`**. Dostępność w Google Play potwierdził administrator;
rejestracja tego pakietu w Firebase i konfiguracja certyfikatów wymagają sprawdzenia.

Dokument roboczy do wypełnienia formularza. „Kod” oznacza potwierdzenie w
repozytorium, „plan” — zadeklarowaną przyszłą konfigurację. Nie wysłano formularza.
Wersja produkcyjna ma obecnie wyłączony model i domyślnie wyłączone płatności;
poniżej uwzględniono też przygotowane funkcje konta i subskrypcji. Ostateczne
odpowiedzi muszą obejmować wszystkie faktycznie dystrybuowane konfiguracje.

## Odpowiedzi ogólne

| Pytanie / pole | Przygotowana odpowiedź |
| --- | --- |
| Czy aplikacja zbiera dane użytkownika? | **Tak** — identyfikator instalacji, dane sesji i żądań; przy logowaniu dane konta, przy zakupie dane subskrypcji; SDK też przesyłają dane |
| Czy wszystkie dane przesyłane są szyfrowane? | **Tak dla zamierzonej konfiguracji produkcyjnej**, po sprawdzeniu wydania i całej infrastruktury: klient wymaga HTTPS w release, usługi Google/OpenAI używają HTTPS; nie jest to szyfrowanie end-to-end |
| Czy użytkownik może poprosić o usunięcie konta? | **Tak** — Konto → Usuń konto; dodatkowo strona `/usun-konto` z kontaktem mailowym, po wdrożeniu |
| Adres usuwania konta | **[BRAK: rzeczywisty publiczny URL HTTPS]**. Adres musi działać bez aplikacji; repozytorium samo nie zapewnia opublikowanego linku |
| Polityka prywatności | **[BRAK: rzeczywisty publiczny URL HTTPS]**; przygotowany dokument: `privacy-policy-draft.pl.md` |
| Sposoby tworzenia konta | E-mail i hasło oraz OAuth przez Google; korzystanie jako gość bez tworzenia konta użytkownika |
| Niezależny audyt bezpieczeństwa / certyfikacja | Nie zaznaczać jako wykonane — brak dowodu takiego audytu; testy nie są certyfikacją |
| Reklamy / marketing | Brak integracji reklamowej i marketingowego profilowania w kodzie |

## Kategorie i cele — propozycja na podstawie przepływów kodu

Poniższa kwalifikacja do kategorii sklepu jest oceną tego projektu. Sprawdzić
nazwy pól w aktualnym formularzu. Cel „Analityka” obejmuje także metryki SDK;
nie oznacza, że dodano Firebase Analytics.

| Kategoria w formularzu | Co i skąd | Zbierane | Wymagane / opcjonalne | Cele |
| --- | --- | --- | --- | --- |
| Dane osobowe → Adres e-mail | Firebase Auth e-mail/hasło i Google Sign-In | Tak przy logowaniu | Opcjonalne: podstawowe korzystanie bez konta | Zarządzanie kontem; funkcje aplikacji |
| Dane osobowe → Identyfikatory użytkownika | UID Firebase, ID konta Sedno, identyfikatory sesji i powiązanie konta z zakupem | Tak | Konto opcjonalne; dane sesji gościa wymagane do żądań sieciowych | Zarządzanie kontem; funkcje; zapobieganie oszustwom, bezpieczeństwo i zgodność |
| Urządzenie lub inne identyfikatory | Losowy ID instalacji i jego HMAC; identyfikatory techniczne SDK | Tak | Własny ID wymagany przy korzystaniu z backendu; metryki OCR przy wyborze aparatu, bez osobnego przełącznika | Funkcje; bezpieczeństwo; analityka dla danych ML Kit |
| Aktywność w aplikacji → Interakcje z aplikacją | Identyfikatory, daty, statusy i dzienny licznik żądań; zdarzenia OCR u dostawcy | Tak | Wymagane w używanym przepływie; OCR można pominąć, wpisując tekst ręcznie | Funkcje; bezpieczeństwo; analityka SDK |
| Aktywność w aplikacji → Inne treści użytkowników | Tekst wysyłany do uproszczenia | Tak, gdy działa wysyłka; plan OpenAI rozszerza odbiorców | Wymagany do uproszczenia; użytkownik wybiera treść i moment wysłania | Funkcje aplikacji |
| Dane finansowe → Historia zakupów | Token i stan subskrypcji, data ważności, przypisanie do konta | Tak przy zakupie/odtworzeniu i weryfikacji | Opcjonalne: dostępna wersja darmowa | Funkcje; zarządzanie kontem; bezpieczeństwo zakupów |
| Informacje o aplikacji i jej działaniu → Diagnostyka / inne dane o działaniu aplikacji | ML Kit: urządzenie, wersje, opóźnienia, kody błędów i rozmiary operacji | Tak według dokumentacji SDK | Przy korzystaniu z OCR; brak własnego wyłącznika telemetrii | Analityka i diagnostyka SDK |
| Dane osobowe → Imię i nazwisko | Profil może trafić z Google do Firebase podczas logowania Google; backend Sedno nie zapisuje nazwy | **Do potwierdzenia na koncie testowym**; jeżeli Firebase otrzymuje nazwę — zadeklarować | Opcjonalne, związane z wyborem Google | Zarządzanie kontem |

Dla dwóch wierszy o identyfikatorach formularz może wymagać jednej wspólnej
odpowiedzi o opcjonalności. Ponieważ własny identyfikator instalacji jest
wymagany do żądań, nie deklarować całej kategorii jako dobrowolnej tylko dlatego,
że konto jest dobrowolne. Brak potrzeby logowania nie oznacza braku danych.

Kod nie pobiera lokalizacji i nie wyznacza jej z IP. Samo używanie IP do
zabezpieczeń nie uzasadnia zaznaczenia precyzyjnej lokalizacji. Należy jednak
sprawdzić, czy hosting lub SDK nie wyznaczają lokalizacji na własne potrzeby.

## Czego kod nie wysyła

| Kategoria | Ustalenie |
| --- | --- |
| Zdjęcia i filmy | Nie deklarować jako wysyłane przez przepływ OCR: zdjęcie zostaje na urządzeniu |
| Lokalna historia | Nie jest synchronizowana ani wysyłana; tekst wybrany do uproszczenia to osobny przepływ opisany wyżej |
| Numery kart i rachunków | Sedno nie otrzymuje ich od użytkownika; nie mylić z historią zakupów. Osobny proces Google Play ocenić według zasad sklepu |
| Kontakty, kalendarz, pliki audio, SMS, rejestr połączeń | Brak takich integracji i przepływów w kodzie |
| Dane o zdrowiu / niepełnosprawności | Brak formularza takich danych; przeznaczenie aplikacji nie oznacza ich zbierania. Dowolny tekst może jednak zawierać dane wrażliwe — nie zapewniać, że jest to technicznie niemożliwe |
| Zdjęcie profilowe | Brak wysyłania własnych zdjęć profilu przez Sedno; sprawdzić zakres danych Google/Firebase przed ostateczną deklaracją |

## Przetwarzanie efemeryczne i udostępnianie

Dane przesłane poza urządzenie należy ocenić w formularzu także wtedy, gdy są
używane tylko w pamięci. Pseudonimizacja nie zwalnia z deklaracji. Przekazanie
usługodawcy działającemu na polecenie administratora może korzystać z wyjątku od
„udostępniania”; nie oznacza braku „zbierania”.
[Definicje Google Play](https://support.google.com/googleplay/android-developer/answer/10787469?hl=pl).

- Własne metadane żądań, sesje, zakupy i skróty HMAC są zapisywane, więc nie są
  efemeryczne. Nie zaznaczać „tylko w pamięci” dla tych przepływów.
- Sam backend nie zapisuje tekstów, lecz przechowuje ich skróty HMAC. Rozdzielić
  treść od metadanych. Dla przyszłego OpenAI **nie zakładać efemeryczności**:
  standardowe logi bezpieczeństwa i ustawienia endpointu mogą utrzymywać treści.
- Nie ustalać zbiorczo „nic nie udostępniamy” bez sprawdzenia ról Google,
  OpenAI i hostingu. Dla każdej kategorii zaznaczyć „nieudostępniane” tylko wtedy,
  gdy faktyczny transfer spełnia definicję wyjątku lub nie występuje.
- Gmail do obsługi zewnętrznego mailto opisano w polityce. Nie deklarować na tej
  podstawie, że aplikacja czyta skrzynkę użytkownika lub wszystkie jego e-maile.

## Ustalenia o dostawcach

**ML Kit:** OCR działa lokalnie; SDK przesyła diagnostykę i metryki użycia.
Dlatego brak Firebase Analytics nie pozwala odpowiedzieć „nie zbieramy analityki”.
[Dokumentacja ML Kit](https://developers.google.com/ml-kit/android-data-disclosure).

**Firebase Authentication:** uwzględnić IP, metadane SDK i dane konta z wybranych
metod logowania. Nie deklarować numeru telefonu jako zbieranego tylko dlatego,
że Firebase obsługuje także SMS — Sedno tego logowania nie używa.
[Dokumentacja Firebase](https://firebase.google.com/docs/android/play-data-disclosure#authentication).

**Play Integrity:** uwzględnia dane żądania, aplikacji i urządzenia; jego własne
procesy Sklepu Play podlegają zasadom Google. Sedno korzysta z wyniku do ochrony
sesji gościa. Nie deklarować nieużywanych opcjonalnych kontroli innych aplikacji.
[Opis danych Play Integrity](https://developer.android.com/google/play/integrity/terms#data-safety).

**OpenAI:** aplikacja używa GPT-6 Luna (`gpt-6-luna`) przez Responses API z
`store=false`, `service_tier=default`, bez historii rozmowy. Agents API pozostaje
wyłącznie w narzędziu benchmarkowym dla testów syntetycznych. Domyślna konfiguracja
backendu wybiera Responses i wymaga klucza po stronie serwera. Wdrożenie produkcyjne
oraz retencję konta trzeba potwierdzić przed deklaracją w Google Play;
`store=false` nie gwarantuje zerowej retencji dostawcy.
[Zasady danych](https://developers.openai.com/api/docs/guides/your-data).

**Hosting — plan:** Firebase; backend wymaga osobnego środowiska dla ASP.NET
i bazy PostgreSQL. Usługi i regiony pozostają do wskazania; nie deklarować
Firestore, Realtime Database ani przechowywania wyłącznie w UE bez wdrożenia.

## Usuwanie i ostatnie kontrole wydania

- [x] Kod ma opcję usunięcia konta i powiązanych danych z backendu/Firebase.
- [x] W aplikacji wyjaśniono, że usunięcie konta nie anuluje subskrypcji.
- [x] Historia lokalna może być usuwana; wygasa po 7 dniach, bez kopii Androida.
- [x] Backend ma publiczną trasę `/usun-konto`, z kontaktem mailowym z konfiguracji.
- [ ] Ustawić `Privacy__DeletionEmail=mariuszbabka0@gmail.com`, wdrożyć stronę
  i politykę HTTPS; wpisać rzeczywiste adresy w Play Console.
- [x] Uzupełniono adres administratora i potwierdzono grupę docelową 16+.
- [ ] Wskazać kraje dystrybucji i skonfigurować grupy docelowe w Play Console;
  kod nie ma mechanizmu kontroli wieku.
- [x] Ustawiono `io.github.mbombka.sedno` jako `applicationId`, `namespace`
  i pakiet klasy startowej Androida.
- [ ] Dodać w Firebase aplikację Android `io.github.mbombka.sedno`, zarejestrować
  odciski certyfikatów i zaktualizować konfigurację Firebase/OAuth w wydaniu.
  Ustawić ten sam pakiet dla Play Integrity i Billing na backendzie.
- [ ] Przyjąć i wdrożyć plan retencji; obecnie część danych nie ma automatycznej
  daty usuwania. Nie wpisywać propozycji jako działającej funkcji.
- [ ] Sprawdzić zależności Androida i ruch wersji release: dokumentacja SDK
  opisuje wersje dostawców, a nie pomiar tego konkretnego pliku APK/AAB.
- [ ] Sprawdzić logi hostingu i proxy, pełny przepływ usuwania i obsługę maila
  od osoby bez aplikacji; nie żądać haseł ani tokenów w wiadomości.
- [ ] Potwierdzić „udostępnianie”, retencję i region OpenAI po zawarciu umów
  i wyborze rzeczywistych ustawień; odświeżyć deklaracje po zmianie usług.

[Wymagania usuwania kont](https://support.google.com/googleplay/android-developer/answer/13327111).
Plan wdrożenia: [privacy-operations-plan.pl.md](privacy-operations-plan.pl.md).
