# Sedno

20.11.2026 wdrożono **sedno-api-00016-ll9** z obsługą pakietu 1000 użyć.
Podpisany [AAB 1.0.0 (20)](mobile/build/releases/sedno-1.0.0-20.aab)
korzysta z publicznego adresu API i zawiera obsługę zakupów Google Play.

Sedno to aplikacja na Androida, która upraszcza i poprawia teksty w obsługiwanych językach. Można wpisać
tekst, wkleić go, odczytać ze zdjęcia lub podyktować (Android 13+ z lokalnym
modelem wybranego języka). Zdjęcia i dźwięk pozostają na telefonie.
Wynik przygotowuje AI, dlatego trzeba go sprawdzić. Przełącznik nad przyciskiem
wybiera „Uprość” lub „Popraw”. Oba tryby korzystają ze wspólnej puli użyć.
Wynik zastępuje tekst w edytorze; jego nagłówek i systemowy Wstecz przywracają
oryginał. Gumka, zmiana trybu i rozpoczęcie nagrywania lub zdjęcia czyszczą pole.
[Lista zadań i opis nowego trybu](docs/popraw-zadania.md).

Kod rozszerzono do [13 wariantów językowych](docs/multilingual-13-languages.pl.md),
w tym portugalskiego z Portugalii i norweskiego Bokmål. Backend z obsługą tych języków jest wdrożony; przygotowano nowy AAB.

## Obecny stan

Serwer uruchomiono 19.10.2026. Przed udostępnieniem aplikacji pozostają
[pozostałe kontrole i przygotowanie Google Play](Tasks.md).
Backend, Firebase Hosting API i zadanie sprzątania korzystają z wydania z
20.11.2026. Przed publicznym wydaniem pozostaje zakup testowy przez Google Play
na telefonie. [Instrukcja prób](mobile/docs/google_play_subscription_sandbox.md).
Obsługę usuwania konta przez e-mail właściciel potwierdził 20.10.2026.

Backend przełączono na Firestore 19.10.2026. API i godzinowe sprzątanie działają.
Starą instancję Cloud SQL i wszystkie cztery kopie zapasowe usunięto 19.10.2026.
[Stan wdrożenia](backend/deploy/firebase/README.pl.md).

26.11.2026 wdrożono domyślny test startowy TCP na porcie 8080 w rewizji
`sedno-api-tcp-20261126`. `/health/ready` sprawdza Firestore podczas weryfikacji
wdrożenia. Minimum instancji usługi Cloud Run wynosi 0.

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
  Serwer jest skonfigurowany; pozostają ustawienia Play Console i testy zakupów.
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
