# Co pozostało przed publikacją

Stan na 20.10.2026: obsługę płatności wdrożono na istniejącym `sedno-api`;
podpisany AAB 8 z panelem zakupów jest gotowy. Pozostają ustawienia Play Console,
próby zakupów na telefonie i kontrole przed publikacją.

## Zakończone i zaakceptowane

- [x] Przełączyć backend PostgreSQL → Firestore. Wdrożono 19.10.2026: 7 dokumentów
  testowych, indeksy READY, publiczne API oraz godzinowe sprzątanie działają.
  [Raport](docs/archiwum/firestore-deployment-2026-10-19.pl.md).
- [x] Trwale usunąć `sedno-postgres` i 4 stare kopie. Usunięto 19.10.2026 po
  jednoznacznej zgodzie właściciela; lista instancji SQL projektu jest pusta.
  Nowych backupów Firestore nie włączono zgodnie z decyzją właściciela.
- [x] Powiązać projekt z Play Integrity w Play Console — potwierdzenie właściciela
  z 19.10.2026. Test instalacji z Google Play pozostaje osobnym zadaniem.
- [x] Przygotować podpisane wydanie AAB 6 (`0.1.0+6`).
  [Raport i pliki](mobile/docs/google_play_release_6.md).
- [x] Zaakceptować nawigację przez menu użytkownika oraz kopiowanie wyniku przez
  zaznaczenie tekstu i menu systemowe, bez osobnego przycisku „Kopiuj”.
  Właściciel potwierdził docelowy wygląd 20.10.2026; zaktualizowano AGENTS i README.
- [x] Ujednolicić dokumenty prywatności i treść w aplikacji dla odbiorców od 13 lat.
  Zmiana na podstawie decyzji właściciela z 20.10.2026; publikacja pozostaje poniżej.
- [x] Uruchomić usuwanie konta przez e-mail — działanie potwierdzone przez
  właściciela 20.10.2026. [Procedura utrzymania](docs/privacy-operations-plan.pl.md).
- [x] Sprawdzić tworzenie i usuwanie konta z aplikacji oraz dostarczanie wiadomości
  e-mail — działanie potwierdzone przez właściciela 20.10.2026.
- [x] Uszczelnić walidację ustawień modelu: dokładnie 4096 tokenów wyjściowych
  i timeout 8 sekund. Inne wartości blokują uruchomienie backendu.
  Wdrożono 20.10.2026 z obsługą płatności.

## Odbiór i publikacja

- [x] Sprawdzić publiczną politykę na `sedno.xyz`: 20.10.2026 potwierdzono
  zapis o osobach 13–17 lat w opublikowanej wersji z 19.10.2026.
- [x] Ujednolicić datę 20.10.2026 i jawny zapis „od 13. roku życia” w lokalnych
  plikach polityki i strony usuwania konta w repozytorium `SednoWebsite/SednoWebsite/public/`.
- [ ] Przesłać dwa poprawione pliki HTML na hosting OVH przez SFTP i potwierdzić
  opublikowaną wersję z 20.10.2026. Właściciel prześle pliki samodzielnie.
- [x] Wdrożyć aktualną kopię polityki osadzoną w API — publiczna kontrola
  20.10.2026 potwierdziła wiek 13+ i wersję 20.10.2026.
- [x] Przygotować wydanie aplikacji z polityką 13+ i panelem zakupów.
  [Podpisany AAB 8](mobile/docs/google_play_release_8.md) wskazuje dotychczasowy serwer.
- [x] Sprawdzić certyfikaty klucza podpisywania Google Play (SHA-1 i SHA-256)
  w Firebase; certyfikat przesyłania jest osobnym certyfikatem.
- [x] Przesłać aktualny AAB do Google Play i sprawdzić instalację z kanału testowego:
  Play Integrity, upraszczanie, logowanie Google i e-mail, zachowanie limitu gościa.
  [Instrukcja pierwszego wydania testowego](mobile/docs/google_play_internal_test.md).
- [x] Sprawdzić reset hasła, powrót do aplikacji oraz ponowne logowanie.
  Tworzenie i usuwanie konta oraz dostarczanie poczty są już potwierdzone powyżej.
- [x] Wykonać próby aparatu, OCR, TalkBack i powiększonego tekstu.
  Właściciel potwierdził działanie aplikacji i OCR na telefonie 19.10.2026.
  Po zmianie aparatu i kadrowania powtórzyć próby według
  [listy kontroli](mobile/docs/android_camera_ocr_manual_check.md).
- [x] Dokończyć odbiór na telefonie: historia, wylogowanie,X
  limity 5 dziennie i reset według czasu serwera o 00:00 UTC.
- [x] Sprawdzić jakość rzeczywistych uproszczeń, błędy, brak sieci, timeout
  i zachowanie limitu po nieudanym żądaniu. [Próbki i kryteria](docs/model-acceptance.pl.md).
- [ ] Sprawdzić treść opublikowanej polityki, ustawienia dostawców i diagnostykę SDK;
  uzupełnić Data Safety, grupę odbiorców 13+ oraz materiały i deklaracje Google Play.

## Pozostałe poprawki i uruchomienie płatności

- [ ] Dopasować komunikat po wyczerpaniu limitu do dostępności płatności;
  odsyłać do subskrypcji tylko wtedy, gdy panel zakupów jest dostępny.
  Przy wyłączonym panelu pokazać informację o wykorzystanym limicie i terminie
  jego odnowienia, bez odsyłania do niedostępnej subskrypcji.
- [x] Utworzyć produkt Google Play `subscription_full`, miesięczny plan `monthly`,
  cena 9,99 PLN — konfiguracja potwierdzona przez właściciela 20.10.2026.
- [x] Zapisać produkt w konfiguracji aplikacji i backendu oraz wybierać w aplikacji
  plan `monthly` bez promocji. Płatności pozostają domyślnie wyłączone.
- [x] Skonfigurować płatności na istniejącym `sedno-api`, z istniejącym kontem
  serwera i bazą `(default)`. Wdrożono trwały pierścień kluczy i uwierzytelnione RTDN
  z ponowieniami i dead-letter. Syntetyczne powiadomienie przez Pub/Sub: HTTP 204.
  [Raport wdrożenia](docs/billing-deployment-2026-10-20.pl.md).
- [x] Wskazać konto testera (konto Google właściciela) — właściciel potwierdził, że jest
  już dodane jako konto testowe.
- [X] Potwierdzić lub uzupełnić w Play Console uprawnienia istniejącego konta
  `sedno-api@sednoapp-79241.iam.gserviceaccount.com`: dane finansowe i zarządzanie
  zamówieniami/subskrypcjami. Obecna autoryzacja operatora do Play API zwraca
  `ACCESS_TOKEN_SCOPE_INSUFFICIENT`; nie potwierdzono zmiany tych uprawnień.
- [x] W Play Console ustawić temat RTDN
  `projects/sednoapp-79241/topics/sedno-billing-rtdn-test` i wysłać test z panelu.
  Test z Play Console 20.10.2026: HTTP 204.
- [X] Przesłać AAB 8 do kanału wewnętrznego, zainstalować go na koncie testera
  i wykonać rzeczywiste testy zakupów, przywracania, wygaśnięcia i limitu 400.
  [Konfiguracja i lista prób](mobile/docs/google_play_subscription_sandbox.md).
- [x] Uporządkować nieużywane zasoby odrzuconego osobnego środowiska opisane
  w raporcie wdrożenia. Usunięto je 20.10.2026 razem z sekretami `sedno-postgres*`.
  Baza `(default)` ma włączoną ochronę przed usunięciem.
- [ ] Przed większym ruchem sprawdzić wydajność, koszty chmury i ograniczanie żądań
  za pośrednictwem Firebase Hosting.

Backupy/PITR Firestore pozostają wyłączone zgodnie z decyzją właściciela.
Próbę odtwarzania zaplanować, jeśli zostaną włączone.

Instrukcje poszczególnych kontroli: [spis dokumentów](docs/README.md).
Dawne prompty zadań i raporty: [archiwum](docs/archiwum/README.md).

## Zadania po audycie bezpieczeństwa — punkty 1–4

Każde zadanie obejmuje naprawę, testy i opis wyniku. Przed pracą przeczytaj
`AGENTS.md` oraz sprawdź aktualny kod i konfigurację. Korzystaj z istniejącego
`sedno-api`, jego konta usługi i bazy `(default)`. Nie zapisuj tokenów ani treści
użytkowników w logach. Nie oznaczaj kontroli produkcyjnej jako wykonanej na
podstawie samych testów lokalnych.

Uzgodniony wariant dla zadań 2–4: ogranicz dodatkowe opóźnienia i zużycie
bezpłatnych pul Blaze. Nie dodawaj nowych usług (w szczególności Memorystore,
Cloud Armor, Cloud Functions), bazy ani harmonogramu. Porównaj czas odpowiedzi
i liczbę operacji Firestore przed i po zmianie; pozostanie w bezpłatnej puli
wymaga sprawdzenia rzeczywistego zużycia, nie wynika z samego projektu rozwiązania.

### 1. Zamknąć publiczny dostęp do starych wersji backendu

- [x] **Wykonano 20.10.2026:** zamknięto pięć starych adresów, wdrożono
  `sedno-api-00010-wj5` i odrzucanie dawnych sesji kont; API i Hosting działają.
  [Rewizje, kontrole produkcyjne i testy](docs/backend-access-2026-10-20.pl.md).
- **Problem:** stare rewizje Cloud Run mają własne publiczne adresy.
  Rewizja `sedno-api-00005-5g5` nie wymaga potwierdzenia e-maila, a używa tej
  samej bazy i klucza sesji co aktualna wersja.
- **Zrób:** sprawdź obecne rewizje, tagi i przypięcie Firebase Hosting. Usuń
  publiczne drogi dostępu do wersji bez aktualnych zabezpieczeń. Zachowaj
  działanie aktualnego API i Hosting. Samo ustawienie 100% ruchu na nową
  rewizję nie wystarcza. Zabezpiecz kolejne wdrożenia przed pozostawianiem
  takich adresów. Uwzględnij wcześniej wystawione sesje niepotwierdzonych kont.
- **Gotowe, gdy:** stare adresy nie obsługują API; aktualne API działa;
  niepotwierdzony użytkownik e-mail nie uzyskuje dostępu do konta przez stare
  ani nowe endpointy. Zapisz sprawdzone rewizje i wyniki kontroli.
- **Gdzie zacząć:** `backend/deploy/firebase/deploy.sh`,
  `backend/src/Sedno.Infrastructure/GuestStore.cs`, konfiguracja Cloud Run.

### 2. Unieważniać sesje Sedna po odebraniu dostępu w Firebase

- [x] **Problem:** własny token Sedna działa do 7 dni także po resecie hasła,
  blokadzie konta lub odwołaniu sesji Firebase. Pozwala również usunąć konto
  bez ponownego potwierdzenia tożsamości.
- **Zrób:** sprawdzaj status konta i odwołanie uwierzytelnienia Firebase przy
  tworzeniu oraz używaniu sesji Sedna. Samo sprawdzenie podpisu i daty ważności
  JWT nie wystarcza. Przy logowaniu wykonaj aktualną kontrolę. Przy używaniu
  sesji przechowuj wynik kontroli konta w pamięci instancji maksymalnie 5 minut
  od sprawdzenia, bez przedłużania tego czasu przy odczycie. Odświeżaj dopiero
  przy kolejnym żądaniu; łącz równoczesne kontrole tego samego konta. Nie zapisuj
  każdej kontroli w Firestore i nie odpytuj nieaktywnych kont. Po wygaśnięciu
  cache błąd Firebase nie może przedłużać starej zgody na dostęp.
  Akceptujemy do 5 minut opóźnienia odebrania dostępu i osobny cache każdej instancji.
  Usunięcie konta ma wymagać kontroli bez cache i świeżego uwierzytelnienia Firebase
  tego samego użytkownika; samo odświeżenie ID tokenu nie oznacza ponownego
  logowania. Dostosuj aplikację do ponownego logowania i odrzucenia starej sesji.
- **Gotowe, gdy:** testy obejmują reset hasła, blokadę/usunięcie użytkownika,
  odwołanie sesji i próbę ponownego użycia starego tokenu. Usunięcie konta
  odrzuca stary token oraz świeży token innego użytkownika. Testy z kontrolowanym
  czasem potwierdzają granicę 5 minut, brak zbędnych wywołań przy trafieniu w cache
  i brak dostępu po jego wygaśnięciu, gdy Firebase jest niedostępne.
- **Gdzie zacząć:** `GuestStore.cs`, `FirebaseTokenVerifier.cs`,
  `AccountDeletionService.cs`, endpoint `DELETE /v1/account`,
  `mobile/lib/features/account/data/`.

- **Wykonane 20.10.2026:** kontrola Firebase, cache do 5 minut, ponowne
  uwierzytelnienie przy usuwaniu konta i obsługa odrzucenia sesji w aplikacji.
  Testy przeszły; backend wdrożono 21.10.2026 jako `sedno-api-00011-bfh`,
  a zmiany aplikacji są w podpisanym AAB 11. Pozostaje odbiór na telefonie.
  [Opis i wyniki testów](docs/firebase-session-revocation-2026-10-20.pl.md).

### 3. Ograniczyć ważność nieodświeżonej weryfikacji subskrypcji

- [x] **Problem:** backend przyznaje płatny limit do zapisanego `ExpiresAt`,
  nawet gdy Google Play wcześniej odebrało zakup, a powiadomienie RTDN nie dotarło.
- **Zrób:** wprowadź maksymalnie 15-minutową ważność weryfikacji, nie dłuższą
  niż ważność zakupu. Wykorzystaj istniejący zapis zakupu. Starszą weryfikację
  odświeżaj na serwerze przy najbliższym żądaniu wymagającym płatnego dostępu,
  niezależnie od otwarcia panelu subskrypcji w aplikacji. Nie odpytuj okresowo
  nieaktywnych użytkowników. Łącz równoczesne próby odświeżenia, również między
  instancjami, wykorzystując istniejące mechanizmy; po uzyskaniu blokady ponownie
  sprawdź świeżość zapisu. Ogranicz ponowienia po awarii Google, aby każde kolejne
  żądanie nie uruchamiało nowej próby. Zachowaj RTDN jako główną drogę szybkiej
  aktualizacji statusu. Nie wywołuj Google w ponawianej transakcji
  Firestore. Jeśli weryfikacja jest przeterminowana i nie można jej odświeżyć,
  stosuj limit darmowy bez zerowania wykorzystania. Sprawdź aktualne RTDN
  i obsługę niedostarczonych wiadomości; nie zakładaj, że ustawienia z audytu
  nadal są aktualne.
- **Gotowe, gdy:** test z utraconym RTDN i odebranym zakupem nie utrzymuje
  płatnego limitu po upływie okna weryfikacji. Aktywna subskrypcja odświeża się
  poprawnie, a awaria Google nie zeruje liczników ani nie przedłuża starej zgody.
  Świeży zapis nie powoduje dodatkowego wywołania Google ani zapisu w Firestore;
  równoczesne żądania nie powielają odświeżenia.
- **Gdzie zacząć:** `backend/src/Sedno.Infrastructure/SubscriptionService.cs`,
  `PlayBillingClient.cs`, `backend/tests/Sedno.IntegrationTests/SubscriptionApiTests.cs`.

- **Wykonane lokalnie 21.10.2026:** okno 15 minut, odświeżanie na żądanie
  z blokadą między instancjami, limit czasu 2 sekundy i minutowa przerwa po błędzie.
  Liczniki pozostają zachowane. Sprawdzono bieżące RTDN i dead-letter w chmurze.
  Wdrożono 21.10.2026 jako `sedno-api-00011-bfh`; końcowe 235 testów backendu
  przeszło. Testowy RTDN przez istniejący Pub/Sub otrzymał 204.
  [Opis zmiany i kontroli RTDN](docs/subscription-verification-2026-10-21.pl.md).

### 4. Naprawić ograniczanie ruchu za Firebase Hosting i Cloud Run

- **Wdrożono 21.10.2026 — `sedno-api-00011-bfh`:** osobne liczniki ważnych sesji gości i kont,
  niezależny limit RTDN, bez magazynu zewnętrznego. Właściciel zaakceptował
  wspólny limit przed sesją za proxy Hosting przy zachowaniu bezpośredniego
  Cloud Run. Kontrole nowej rewizji przez Hosting, Cloud Run i bieżący tag
  przeszły. Współbieżność ustawiono na 80. Wszystkie 235 testów backendu przeszły, w tym
  12 nowych. [Zmiana, testy i ograniczenia kontroli produkcyjnej](docs/traffic-limiting-2026-10-21.pl.md).

- [x] **Problem:** limiter używa `RemoteIpAddress`, który za proxy może oznaczać
  wspólny adres pośrednika. Jeden klient może wtedy wyczerpać limit innych
  użytkowników.
- **Zrób:** ustal rzeczywisty łańcuch proxy dla Hosting i bezpośredniego Cloud Run.
  Zastosuj bezpieczny sposób identyfikacji klienta. Pozostaw limiter ruchu
  w pamięci każdej instancji, bez liczników Firestore i zewnętrznego magazynu.
  Akceptujemy przybliżony limit łączny: przy trzech instancjach może wynosić
  około trzykrotności limitu jednej instancji. Dzienne limity uproszczeń 5/400
  pozostają wspólne i transakcyjne — nie przenoś ich do pamięci.
  Nie ufaj dowolnemu `X-Forwarded-For` podanemu przez klienta.
  Uwzględnij ruch bez sesji i ruch uwierzytelniony. Oddziel ograniczenia RTDN
  od publicznego API, zachowując weryfikację podpisu powiadomień.
- **Gotowe, gdy:** testy potwierdzają izolację limitów różnych klientów,
  brak obejścia przez podrobione nagłówki i działanie lokalnego limitu każdej instancji.
  Opisz przybliżenie limitu łącznego i reset lokalnych liczników po restarcie.
  Sam limiter nie wykonuje operacji Firestore ani dodatkowych wywołań sieciowych.
  Wyczerpanie limitu publicznego API nie blokuje prawidłowych RTDN.
  Potwierdź zachowanie obu dróg dostępu bez przeciążania produkcji.
- **Gdzie zacząć:** `backend/src/Sedno.Api/Program.cs`,
  `backend/src/Sedno.Api/CloudRunHosting.cs`, konfiguracja Hosting i Cloud Run.

## Tryby „Uprość” i „Popraw” — 22.10.2026

Lista implementacji, wyniki testów i próby na telefonie:
[popraw-zadania.md](docs/popraw-zadania.md).
