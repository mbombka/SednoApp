# Sedno — strona wizytówka

Statyczna strona po polsku: HTML i CSS, bez instalacji, budowania i bazy danych.
Używa fontów systemowych, lokalnej ikony i lokalnych zrzutów ekranu. Nie ma JavaScriptu, formularzy,
logowania, analityki, reklam ani zasobów ładowanych z zewnętrznych serwerów.
To wizytówka projektu, a nie aplikacja ani jej backend; przykład uproszczenia nie korzysta z AI.

## Miejsce w monorepozytorium

Strona jest częścią repozytorium SednoApp w `website/SednoWebsite/`.
Korzysta ze wspólnej historii Git aplikacji i backendu; nie jest osobnym
repozytorium ani submodułem. Katalog `website/Content/` zawiera źródłowe grafiki
i zrzuty ekranu, których nie przesyłamy na hosting.

Poniższe ścieżki są względne do `website/SednoWebsite/`:

```text
README.md                  — instrukcje, nie wysyłamy na hosting
public/                    — cała strona gotowa do przesłania
├── index.html             — strona główna
├── styles.css             — wspólne style wszystkich stron
├── favicon.svg            — ikona
├── img/                   — zrzuty ekranu aplikacji (WebP, 600 px szerokości)
├── prywatnosc/
│   └── index.html         — pełna polityka prywatności
└── usun-konto/
    └── index.html         — instrukcja usunięcia konta
```

Wszystkie pliki strony edytujemy bezpośrednio w `public/`. To jedyna kopia
przeznaczona do publikacji; nie potrzeba generatora z repozytorium aplikacji.

## Podgląd lokalny

Otwórz `public/index.html` bezpośrednio w przeglądarce. Linki do podstron,
powroty i style używają ścieżek względnych, więc działają też bez serwera.
Linki wskazują jawnie `index.html`, aby przeglądarka otwierała dokument zamiast katalogu.
Adresy `/prywatnosc/` i `/usun-konto/` nadal działają na hostingu.

Opcjonalnie, jeśli masz lokalnie Python 3, z katalogu repozytorium uruchom:

```sh
python3 -m http.server 8000 --directory website/SednoWebsite/public
```

Otwórz `http://localhost:8000/`. Serwer zatrzymasz przez Ctrl+C.
Python służy tylko do opcjonalnego podglądu na komputerze; hosting go nie wymaga.

## Publikacja na OVH przez SFTP

1. Sprawdź w panelu OVH katalog przypisany do domeny (często `www`).
2. Zrób kopię istniejącej strony przed zastąpieniem plików.
3. Prześlij **całą zawartość `public/`** do katalogu domeny, zachowując podkatalogi.
   Sam folder `public` nie powinien pojawić się jako dodatkowy poziom na hostingu.
4. Sprawdź, czy plikiem startowym jest `index.html` i czy stary plik startowy nie ma pierwszeństwa.
5. Sprawdź certyfikat SSL i przekierowanie HTTP na HTTPS w konfiguracji hostingu.

Przykładowo: `public/index.html` trafia do `www/index.html`, a
`public/prywatnosc/index.html` do `www/prywatnosc/index.html`.
Nie przesyłaj README, katalogu `.git` ani innych plików spoza `public/`.
Nie trzeba instalować frameworków ani uruchamiać backendu.

Po przesłaniu sprawdź przez HTTPS:

- `https://sedno.xyz/` — strona główna, w tym sekcja `#prywatnosc`;
- `https://sedno.xyz/prywatnosc/` — pełna polityka;
- `https://sedno.xyz/usun-konto/` — usuwanie konta.

Podstrony korzystają ze standardowego pliku `index.html` w katalogu, bez routingu
aplikacji. Sprawdź też wygląd na telefonie, linki, nawigację klawiaturą i fokus.
Link mailowy powinien otworzyć program pocztowy z adresem `contact@sedno.xyz`
i tematem „Usunięcie konta Sedno”. Samo kliknięcie nie wysyła wiadomości ani nie usuwa konta.

**Zmiana plików w repozytorium nie publikuje strony.** Publikacja wymaga przesłania
ich na hosting. Instrukcja OVH: [publikacja strony](https://docs.ovhcloud.com/en/guides/web-cloud/web-hosting/hosting-how-to-get-my-website-online).

## Aktualizacja treści

Strona główna opisuje aplikację jako będącą w przygotowaniu. Po premierze zaktualizuj
ten komunikat i dodaj rzeczywisty link do Google Play.

Sekcja `#prywatnosc` zawiera podsumowanie i link do pełnego dokumentu.
Dokumenty dostarczył właściciel projektu. Zachowuj rozróżnienie działających funkcji
i planowanej konfiguracji; publikacja dokumentów nie wdraża opisanych w nich planów.
Przed publikacją sprawdź aktualność treści, dat i danych kontaktowych.
