# Co pozostało przed publikacją

Stan na 19.10.2026: backend działa w chmurze; aplikacja wymaga pełnych prób
na telefonie i przygotowania wydania w Google Play.

- [x] Przełączyć backend PostgreSQL → Firestore. Wdrożono 19.10.2026: 7 dokumentów
  testowych, indeksy READY, publiczne API oraz godzinowe sprzątanie działają.
  [Raport](docs/archiwum/firestore-deployment-2026-10-19.pl.md).
- [x] Trwale usunąć `sedno-postgres` i 4 stare kopie. Usunięto 19.10.2026 po
  jednoznacznej zgodzie właściciela; lista instancji SQL projektu jest pusta.
  Nowych backupów Firestore nie włączono zgodnie z decyzją właściciela.
- [ ] Opublikować przygotowaną politykę Firestore na osobnej domenie `sedno.xyz`;
  kopia dostępna przez API została już wdrożona.
- [ ] Powiązać projekt z Play Integrity w Play Console i sprawdzić aplikację
  zainstalowaną z kanału testowego, w tym upraszczanie i logowanie.
  Powiązanie projektu potwierdzone przez właściciela 19.10.2026; podpisany AAB gotowy.
  Pozostało przesłanie wydania do Google Play i test na telefonie.
  [Instrukcja pierwszego wydania testowego](mobile/docs/google_play_internal_test.md).
- [ ] Sprawdzić certyfikaty podpisu Androida w Firebase i przygotować podpisane wydanie AAB.
- [ ] Wykonać próby aparatu, OCR, TalkBack i powiększonego tekstu.
  Właściciel potwierdził działanie aplikacji i OCR na telefonie 19.10.2026.
  Po zmianie aparatu i kadrowania powtórzyć próby według
  [listy kontroli](mobile/docs/android_camera_ocr_manual_check.md).
- [ ] Przećwiczyć usuwanie konta i obsługę zgłoszeń e-mail.
  Backupy Firestore wyłączone decyzją właściciela; próbę odtwarzania zaplanować, jeśli zostaną włączone.
- [ ] Sprawdzić treść opublikowanej polityki, ustawienia dostawców i formularz Data Safety.
- [ ] Przed włączeniem płatności utworzyć produkt w Google Play, skonfigurować
  serwer i wykonać testy zakupów oraz powiadomień.
- [ ] Przed większym ruchem sprawdzić wydajność, koszty chmury i ograniczanie żądań
  za pośrednictwem Firebase Hosting.

Instrukcje poszczególnych kontroli: [spis dokumentów](docs/README.md).
Dawne prompty zadań i raporty: [archiwum](docs/archiwum/README.md).
