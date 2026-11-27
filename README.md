# Sedno

Sedno to aplikacja na Androida, która upraszcza i poprawia teksty w obsługiwanych językach. Można wpisać
tekst, wkleić go, odczytać ze zdjęcia lub podyktować (Android 13+ z lokalnym
modelem wybranego języka). Zdjęcia i dźwięk pozostają na telefonie.
Wynik przygotowuje AI, dlatego trzeba go sprawdzić. Przełącznik nad przyciskiem
wybiera „Uprość” lub „Popraw”. Oba tryby korzystają ze wspólnej puli użyć.
Wynik zastępuje tekst w edytorze; jego nagłówek i systemowy Wstecz przywracają
oryginał. Gumka, zmiana trybu i rozpoczęcie nagrywania lub zdjęcia czyszczą pole.
[Lista zadań i opis nowego trybu](docs/popraw-zadania.md).

Sedno obsługuje [13 wariantów językowych](docs/multilingual-13-languages.pl.md),
w tym portugalski z Portugalii i norweski Bokmål.

## Obecny stan

Od 27.11.2026 cały ruch API obsługuje backend Go. Właściciel potwierdził
upraszczanie na telefonie po przełączeniu. [Stan produkcji](backend/deploy/firebase/README.pl.md#stan-produkcji).

Wydanie Android 1.0.0 (20) zawiera obsługę subskrypcji i pakietu 1 000 użyć.
Zakup i przywrócenie subskrypcji przez Google Play wymagają prób na telefonie
przed publiczną publikacją. [Lista prac przed publikacją](Tasks.md).

| Informacja | Wartość |
| --- | --- |
| Strona | [sedno.xyz](https://sedno.xyz) |
| Serwer API — adres do konfiguracji aplikacji | `https://sednoapp-79241-api.web.app` |
| Pakiet Android | `xyz.sedno.app` |
| Projekt Firebase | `sednoapp-79241` |

## Najważniejsze zasady

- Aplikacja jest przeznaczona dla osób od 13 lat; osoby w wieku 13–17 lat
  powinny korzystać z niej za zgodą rodzica lub opiekuna.
- Menu użytkownika prowadzi do Start, Historii, Konta, informacji o aplikacji
  i prywatności. Wynik można zaznaczyć i skopiować przez menu systemowe.
- Tekst: maksymalnie 4000 znaków; pustego tekstu nie można wysłać.
- Wersja darmowa: 5 uproszczeń dziennie, również bez konta. Reset o północy UTC.
- Przygotowana subskrypcja: 9,99 zł miesięcznie, 400 uproszczeń dziennie łącznie.
  Produkt Google Play `subscription_full`, plan `monthly` są skonfigurowane.
  [Instrukcja prób zakupów](mobile/docs/google_play_subscription_sandbox.md).
- Pakiet: jednorazowy zakup 1000 użyć za 4,99 zł w Polsce. Cenę dla danego rynku
  pokazuje Google Play. Produkt `simplifications_1000` wymaga konta Sedno.
  Najpierw zużywa się pakiet, potem obowiązuje limit dzienny danego konta.
- Historia: szyfrowana, tylko na telefonie, do 7 dni; wylogowanie ją usuwa.
- Tekst trafia przez serwer do OpenAI. Serwer Sedno nie zapisuje tekstu ani wyniku.

## Od czego zacząć

- [Uruchomienie aplikacji i testy](mobile/README.md).
- [Uruchomienie lokalnego serwera](backend/README.md).
- [Wdrożenie i utrzymanie serwera w chmurze](backend/deploy/firebase/README.pl.md).
- [Spis dokumentów, prywatność i publikacja](docs/README.md).
- [Strona internetowa — podgląd i publikacja](website/SednoWebsite/README.md).

Kod aplikacji jest w `mobile/`, serwera w `backend/`, a opis API w
[contracts/openapi.yaml](contracts/openapi.yaml). Narzędzia pomocnicze są w `tools/`.
Strona jest w `website/SednoWebsite/`, a jej źródłowe grafiki w `website/Content/`.
Aplikacja, backend i strona tworzą jedno monorepozytorium ze wspólną historią Git.
Zasady pracy nad kodem opisuje [AGENTS.md](AGENTS.md).

## Dostęp dla testerów

[Instrukcja czasowego dostępu testerskiego i skryptu administracyjnego](docs/tester-access.pl.md).
