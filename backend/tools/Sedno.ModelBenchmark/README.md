# Pomiar czasu i kosztów AI

Narzędzie porównuje Responses `default` i `fast`; opcjonalnie także zapisanego
agenta. Działa niezależnie od aplikacji, bez bazy i limitów Sedno.
**Rzeczywiste wywołania OpenAI są płatne.** Bez `--live` pokazuje tylko pomoc.

## Uruchomienie

Z katalogu głównego projektu, z kluczem `OpenAI:ApiKey` w lokalnym magazynie
`sedno-backend-dev` lub zmiennej `OpenAI__ApiKey`:

```sh
dotnet run --project backend/tools/Sedno.ModelBenchmark -- --live --rounds 5
```

Każdy wariant ma rozgrzewkę oraz 3 syntetyczne próbki na rundę. Raport JSONL na
standardowym wyjściu zawiera czas, status i zużycie tokenów bez treści tekstów.
Rozgrzewka nie wchodzi do podsumowania. Mediana i p95 obejmują tylko sukcesy;
mała próbka nie daje miarodajnej prognozy szybkości ani kosztów całej aplikacji.

Eksport **wyłącznie wbudowanych próbek syntetycznych** i ich odpowiedzi:

```sh
dotnet run --project backend/tools/Sedno.ModelBenchmark -- --live --rounds 5 --text-report /tmp/sedno-pomiar.md
```

`--text-report` dopisuje raport po zakończeniu serii. Nie eksportuj ruchu użytkowników.
Wspólny [prompt](../../src/Sedno.Infrastructure/Prompts/simplify.pl.txt) i `ResponsesClient`
są używane także przez aplikację. Domyślnie: `gpt-6-luna`, effort `none`, 4096 tokenów,
8 sekund i `store=false`. Ten ostatni parametr nie oznacza zerowej retencji dostawcy.
Opcje `--model`, `--effort` i `--prompt` służą do oddzielnych eksperymentów.

## Agent i usuwanie sesji

Dodaj `--agent`, aby uwzględnić agenta w porównaniu. Ustaw jego `OpenAI:AgentId`
w magazynie `sedno-model-benchmark`; ma on pierwszeństwo przed `sedno-backend-dev`,
a zmienne środowiskowe przed oboma. Potwierdź zgodność promptu i modelu w Platform.
Kod agenta jest używany wyłącznie przez to narzędzie.

Przed wyłączeniem starego wdrożenia agenta zatrzymaj nowe żądania, poczekaj na
zakończenie trwających i uruchom z tym samym kluczem oraz identyfikatorem agenta:

```sh
dotnet run --project backend/tools/Sedno.ModelBenchmark -- --live --cleanup-agent
```

Wymagany wynik: kod 0. Przy błędzie ponów sprzątanie; młode sesje mogą wymagać
odczekania. Stare sesje bez oznaczenia Sedno sprawdź osobno u dostawcy.
Kod 1 oznacza błąd pomiaru lub sprzątania, 2 — konfiguracji, 130 — przerwanie.

## Zachowane pomiary

- [Porównanie z 16.10.2026](results/2026-10-16.md).
- [Koszt porównania](results/2026-10-16-costs.md).
- [Dodatkowy pomiar przed Firebase](results/2026-10-16-firebase-costs.md).

Stawki i wyniki dotyczą daty pomiaru; nie są bieżącym rachunkiem.
[Sprawdzenie jakości uproszczeń](../../../docs/model-acceptance.pl.md).
