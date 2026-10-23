# Sedno

Sedno to aplikacja na Androida, która upraszcza i poprawia polskie teksty. Można wpisać
tekst, wkleić go, odczytać ze zdjęcia lub podyktować (Android 13+ z lokalnym
modelem języka polskiego). Zdjęcia i dźwięk pozostają na telefonie.
Wynik przygotowuje AI, dlatego trzeba go sprawdzić. Przełącznik nad przyciskiem
wybiera „Uprość” lub „Popraw”. Oba tryby korzystają ze wspólnego limitu dziennego.
Wynik zastępuje tekst w edytorze; jego nagłówek i systemowy Wstecz przywracają
oryginał. Gumka, zmiana trybu i rozpoczęcie nagrywania lub zdjęcia czyszczą pole.
[Lista zadań i opis nowego trybu](docs/popraw-zadania.md).

## Obecny stan

Serwer uruchomiono 19.10.2026. Przed udostępnieniem aplikacji pozostają
[pozostałe kontrole i przygotowanie Google Play](Tasks.md).
Obsługę płatności włączono na istniejącym serwerze do testów; zakupów nie odebrano
jeszcze na telefonie. Przygotowano [podpisany AAB 13](mobile/docs/google_play_release_13.md)
z wynikiem w edytorze, mniejszą gumką i usuwaniem całej historii.
Zawiera też tryb Popraw, lokalny odczyt tekstu i obsługę dostępu testerskiego.
Backend z aktualnymi promptami wdrożono 22.10.2026 jako `sedno-api-00012-9j4`,
ze współbieżnością 80 żądań na instancję.
[Raport wdrożenia](docs/backend-deployment-2026-10-22.pl.md).
Obsługę usuwania konta przez e-mail właściciel potwierdził 20.10.2026.

Backend przełączono na Firestore 19.10.2026. API i godzinowe sprzątanie działają.
Starą instancję Cloud SQL i wszystkie cztery kopie zapasowe usunięto 19.10.2026.
[Stan wdrożenia](backend/deploy/firebase/README.pl.md).

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
