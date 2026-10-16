# Dokumenty do publikacji na sedno.xyz

Działający adres informacji o prywatności podany przez właściciela:
`https://sedno.xyz/#prywatnosc`. Fragment `#prywatnosc` wskazuje sekcję strony
głównej, nie oddzielną trasę HTTP. Odczyt 16.10.2026 potwierdził krótkie
podsumowanie o zdjęciach, AI i historii; nie obejmuje pełnej polityki.

Gotowe pliki:

- `prywatnosc/index.html`: pełna polityka. Włącz jej treść do istniejącej sekcji
  albo opublikuj dokument i dodaj do niego link w tej sekcji. Samo skopiowanie
  katalogu nie aktualizuje fragmentu istniejącej strony głównej.
- `usun-konto/index.html`: planowany adres `https://sedno.xyz/usun-konto`.
  Opublikuj plik z obsługą `index.html` dla tej ścieżki i sprawdź kontakt mailowy.

Przed zgłoszeniem w Play Console sprawdź pełną politykę i usuwanie przez HTTPS
bez logowania. Ta zmiana nie publikuje plików ani nie zmienia hostingu i DNS.

Pliki nie wymagają JavaScript, plików cookie, zewnętrznych fontów ani analityki.
Logi hostingu i konfigurację retencji opisuje `../privacy-operations-plan.pl.md`.
Nie edytuj wygenerowanych plików osobno: źródło to `../privacy-policy.pl.json`.
Z katalogu repozytorium uruchom `python3 tools/generate_privacy_policy.py`,
a następnie ten sam program z `--check`.

Backend również udostępnia `/prywatnosc` i `/usun-konto`; jego uruchomienie
nie zmienia automatycznie treści publicznej domeny.
