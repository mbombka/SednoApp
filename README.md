# Sedno

Sedno to aplikacja na Androida, która upraszcza polskie teksty. Można wpisać
tekst, wkleić go lub odczytać ze zdjęcia. Zdjęcia pozostają na telefonie.
Uproszczenie przygotowuje AI, dlatego wynik trzeba sprawdzić.

## Obecny stan

Serwer uruchomiono 19.10.2026. Przed udostępnieniem aplikacji pozostają
[testy na telefonie i przygotowanie Google Play](Tasks.md). Płatności są wyłączone.

| Informacja | Wartość |
| --- | --- |
| Strona | [sedno.xyz](https://sedno.xyz) |
| Serwer API — adres do konfiguracji aplikacji | `https://sednoapp-79241-api.web.app` |
| Pakiet Android | `xyz.sedno.app` |
| Projekt Firebase | `sednoapp-79241` |

## Najważniejsze zasady

- Tekst: maksymalnie 4000 znaków; pustego tekstu nie można wysłać.
- Wersja darmowa: 5 uproszczeń dziennie, również bez konta. Reset o północy UTC.
- Przygotowana subskrypcja: 9,99 zł miesięcznie, 400 uproszczeń dziennie łącznie.
  Wymaga jeszcze uruchomienia i testów w Google Play.
- Historia: szyfrowana, tylko na telefonie, do 7 dni; wylogowanie ją usuwa.
- Tekst trafia przez serwer do OpenAI. Serwer Sedno nie zapisuje tekstu ani wyniku.

## Od czego zacząć

- [Uruchomienie aplikacji i testy](mobile/README.md).
- [Uruchomienie lokalnego serwera](backend/README.md).
- [Wdrożenie i utrzymanie serwera w chmurze](backend/deploy/firebase/README.pl.md).
- [Spis dokumentów, prywatność i publikacja](docs/README.md).

Kod aplikacji jest w `mobile/`, serwera w `backend/`, a opis API w
[contracts/openapi.yaml](contracts/openapi.yaml). Narzędzia pomocnicze są w `tools/`.
Zasady pracy nad kodem opisuje [AGENTS.md](AGENTS.md).
