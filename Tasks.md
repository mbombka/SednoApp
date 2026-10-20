# Co pozostało przed publikacją

Stan na 20.10.2026: backend działa w chmurze, podpisany AAB wydania 6 jest gotowy.
Pozostają odbiór aplikacji z Google Play, kontrole przed publikacją i uruchomienie płatności.

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

## Odbiór i publikacja

- [ ] Opublikować aktualną politykę 13+ na domenie `sedno.xyz` oraz wdrożyć
  jej kopię osadzoną w API. Pliki lokalne zostały ujednolicone; nie potwierdzono
  publikacji tej wersji na serwerach.
- [ ] Przygotować kolejne wydanie aplikacji z aktualną polityką 13+.
  Gotowy AAB 6 powstał przed tą zmianą; kolejny numer wydania musi wynosić co najmniej 7.
- [ ] Sprawdzić certyfikaty klucza podpisywania Google Play (SHA-1 i SHA-256)
  w Firebase; certyfikat przesyłania jest osobnym certyfikatem.
- [ ] Przesłać aktualny AAB do Google Play i sprawdzić instalację z kanału testowego:
  Play Integrity, upraszczanie, logowanie Google i e-mail, zachowanie limitu gościa.
  [Instrukcja pierwszego wydania testowego](mobile/docs/google_play_internal_test.md).
- [ ] Sprawdzić prawdziwe wiadomości potwierdzające e-mail i resetujące hasło,
  powrót do aplikacji oraz ponowne logowanie.
- [ ] Wykonać próby aparatu, OCR, TalkBack i powiększonego tekstu.
  Właściciel potwierdził działanie aplikacji i OCR na telefonie 19.10.2026.
  Po zmianie aparatu i kadrowania powtórzyć próby według
  [listy kontroli](mobile/docs/android_camera_ocr_manual_check.md).
- [ ] Dokończyć odbiór na telefonie: historia, wylogowanie i usuwanie konta
  z aplikacji, limity 5 dziennie i reset według czasu serwera o 00:00 UTC.
- [ ] Sprawdzić jakość rzeczywistych uproszczeń, błędy, brak sieci, timeout
  i zachowanie limitu po nieudanym żądaniu. [Próbki i kryteria](docs/model-acceptance.pl.md).
- [ ] Sprawdzić treść opublikowanej polityki, ustawienia dostawców i diagnostykę SDK;
  uzupełnić Data Safety, grupę odbiorców 13+ oraz materiały i deklaracje Google Play.

## Pozostałe poprawki i uruchomienie płatności

- [ ] Dopasować komunikat po wyczerpaniu limitu do dostępności płatności;
  obecnie odsyła do subskrypcji także wtedy, gdy oferta jest wyłączona.
- [ ] Uszczelnić walidację ustawień modelu produkcyjnego zgodnie z AGENTS:
  4096 tokenów wyjściowych i timeout 8 sekund.
- [ ] Przed włączeniem płatności utworzyć produkt w Google Play, skonfigurować
  serwer i wykonać testy zakupów oraz powiadomień.
- [ ] Przed większym ruchem sprawdzić wydajność, koszty chmury i ograniczanie żądań
  za pośrednictwem Firebase Hosting.

Backupy/PITR Firestore pozostają wyłączone zgodnie z decyzją właściciela.
Próbę odtwarzania zaplanować, jeśli zostaną włączone.

Instrukcje poszczególnych kontroli: [spis dokumentów](docs/README.md).
Dawne prompty zadań i raporty: [archiwum](docs/archiwum/README.md).
