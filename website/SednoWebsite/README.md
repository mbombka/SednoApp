# Sedno — strona internetowa

Statyczna strona w 13 wariantach językowych, zgodnych z aplikacją. Zachowuje
wspólny wygląd i pięć instrukcji obrazkowych. Nie wymaga JavaScriptu, serwera
aplikacji, instalowania bibliotek ani bazy danych. Korzysta z fontów systemowych
oraz lokalnych grafik SVG. Nie ma analityki, reklam ani zewnętrznych zasobów.
Przykłady są poglądowe i nie wywołują AI.

## Źródła i generowanie

Wszystkie polecenia wykonuj z katalogu głównego SednoApp. Wystarcza Python 3
z biblioteką standardową:

```sh
python3 tools/generate_website.py
python3 tools/generate_website.py --check
python3 -m unittest tools/tests/test_generate_website.py -v
```

| Plik lub katalog | Przeznaczenie |
| --- | --- |
| `locales.json` | Lista wariantów i mapowanie na języki aplikacji |
| `locales/*.json` | Tłumaczenia tekstów strony oraz przykłady w danym języku |
| `templates/home.html` | Wspólny układ strony głównej |
| `templates/paper.svg` | Wspólna grafika kartki z aparatu |
| `public/styles.css` | Wspólne style, edytowane bezpośrednio |
| `../../tools/generate_website.py` | Generator stron, instrukcji, dokumentów i grafik |
| `../../mobile/lib/l10n/app_*.arb` | Źródło rzeczywistych nazw przycisków i nagłówków aplikacji |
| `../../docs/privacy-policy.*.json` | Wersjonowane źródła pełnych polityk prywatności |
| `public/` | Wszystkie pliki gotowe do skopiowania na hosting |

Nie edytuj wygenerowanych plików HTML ani `kartka-z-tekstem.<język>.svg` ręcznie.
Po zmianie tłumaczeń aplikacji, tekstów strony, szablonu lub polityki uruchom
generator strony. `--check` wykrywa nieaktualne artefakty i nie zapisuje plików.
Generator sprawdza kompletność katalogów; technicznym językiem zapasowym jest
polski. Wszystkie publikowane katalogi mają pełny zestaw tłumaczeń.

Grafiki ekranów powstają w HTML/CSS ze wspólnego kodu, ale każdy język ma
własne napisy z aplikacji i przykłady. Każdy ma również osobne SVG kartki z tekstem
i jej podglądu z ramką zaznaczenia. Ramka skaluje się razem ze zdjęciem.
Ekrany mają wspólne wymiary, również po powiększeniu tekstu. Zdjęcie pokazano
w czterech krokach: otwarcie aparatu, „Zrób zdjęcie”, zaznaczenie tekstu i wynik.
Mowę oraz odczyt przedstawiają statyczne fale dźwiękowe. Tłumaczenia i przykłady
wymagają odbioru przez osoby znające dany język i potrzeby odbiorców.

## Adresy

Polski pozostaje domyślny pod `/`. Dostępny jest również przez `/pl/`.
Pozostałe wersje mają katalogi: `/en/` (UK), `/en-us/`, `/fr/`, `/de/`, `/it/`,
`/es/`, `/pt/` (Portugalia), `/sk/`, `/cs/`, `/ro/`, `/nb/` (Bokmål), `/sv/`.
Mapowanie na tagi językowe znajduje się w `locales.json`; nie jest mapowaniem kodów API.

Każdy katalog zawiera:

```text
index.html                 — strona główna z lokalnymi instrukcjami
privacy/index.html         — pełna polityka w danym języku
delete-account/index.html  — usuwanie konta w danym języku
```

Przełącznik języka używa `details` i zwykłych linków. Działa bez JavaScriptu,
z klawiaturą i po otwarciu lokalnych plików. Zachowuje rodzaj strony: polityka
prowadzi do polityki, a usuwanie konta do usuwania konta. Strona nie wymusza
przekierowania na podstawie języka przeglądarki. Nie używa ciasteczek ani pamięci
lokalnej. Nazwy języków są podane w ich własnym języku.

Stare adresy `/prywatnosc/`, `/usun-konto/` i kotwice strony głównej pozostają
aktywne. Polskie aliasy i `/pl/` mają adresy kanoniczne, a wszystkie wersje mają
odnośniki `hreflang`. `sitemap.xml` zawiera kanoniczne adresy 13 wersji i dokumentów.

Pełne polityki pochodzą z tych samych JSON-ów co treść aplikacji. Wariant USA
korzysta z istniejącego angielskiego dokumentu, tak jak aplikacja. Wzmianki
w dokumentach o polskich adresach odnoszą się do dostępnych polskich wersji.
Generator polskiej polityki nadal aktualizuje dokumenty backendu oraz stare
polskie adresy strony, korzystając z tego samego renderowania co generator strony.
Dokumenty backendu mają prostszy układ HTML, lecz wspólne źródło treści.

## Podgląd

Otwórz `public/index.html` lub np. `public/de/index.html` w przeglądarce.
Linki i zasoby są względne, więc działają też bez serwera.
Opcjonalnie:

```sh
python3 -m http.server 8000 --directory website/SednoWebsite/public
```

Otwórz `http://localhost:8000/`. Sprawdź przełącznik języka, linki do dokumentów,
układ na telefonie, fokus klawiatury i powiększenie tekstu.

## Publikacja na OVH przez SFTP

Prześlij **całą zawartość `public/`** do katalogu przypisanego domenie w OVH
(np. `www`), zachowując podkatalogi. Folder `public` nie powinien tworzyć
kolejnego poziomu na hostingu. Nie przesyłaj szablonów, tłumaczeń źródłowych,
README, narzędzi ani `.git`. Nie jest potrzebne budowanie strony na hostingu.
Nie przygotowujemy dodatkowych paczek.

Przed zastąpieniem plików zachowaj kopię dotychczasowej strony. Sprawdź HTTPS,
przekierowanie z HTTP, plik startowy i przykładowe adresy:

- `https://sedno.xyz/`
- `https://sedno.xyz/en/` oraz `https://sedno.xyz/en-us/`
- `https://sedno.xyz/de/privacy/`
- `https://sedno.xyz/fr/delete-account/`
- stare adresy `https://sedno.xyz/prywatnosc/` i `https://sedno.xyz/usun-konto/`.

Link do usunięcia konta otwiera program pocztowy z adresem `contact@sedno.xyz`
i przetłumaczonym tematem. Samo kliknięcie nie wysyła wiadomości ani nie usuwa konta.

**Edycja repozytorium nie publikuje strony.** Wgranie backendu też nie aktualizuje
hostingu OVH. Strona nadal informuje o fazie testów; po premierze zaktualizuj
komunikaty we wszystkich katalogach i dodaj rzeczywisty link Google Play.

## Weryfikacja wersji wielojęzycznej — 23.10.2026

Testy generatora obejmują zgodność z listą języków aplikacji, napisy przycisków,
lokalne grafiki, pełne treści polityk, adresy językowe, przełączanie dokumentów,
kotwice i zasoby. Wszystkie 26 testów narzędzi Python przeszło.
Kontrole generatora strony oraz obu generatorów polityk przeszły.

W Firefoxie sprawdzono 39 scenariuszy: każdy język przy szerokości 1440 px,
390 px oraz 320 px z tekstem 200%. Automatyczna kontrola wymiarów wykryła
początkowe przepełnienia dłuższych przykładów; po dopasowaniu wspólnych
przycisków i wysokości ekranów wszystkie scenariusze przeszły. Sprawdzono też
wizualnie stronę, grafiki i rozwinięty przełącznik. Te kontrole nie zastępują
odbioru tłumaczeń przez osoby znające dany język ani testu opublikowanej domeny.
W tym kroku nie publikowano strony, nie zmieniano aplikacji ani backendu.
