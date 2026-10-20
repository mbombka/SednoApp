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
