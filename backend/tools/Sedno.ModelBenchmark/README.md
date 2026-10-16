# Porównanie Responses API i agenta

[Wyniki rzeczywistego pomiaru z 16.10.2026](results/2026-10-16.md):
mediana agent 4,84 s, Responses default 1,51 s, Responses fast 1,21 s.

Eksperyment uruchamiany ręcznie. Nie zmienia dostawcy modelu w aplikacji,
nie uruchamia serwera HTTP, nie wymaga PostgreSQL i nie zużywa limitu Sedno.
Wywołania OpenAI są płatne. Zwykłe `dotnet test` używa atrap sieci.

Z katalogu repozytorium:

```sh
dotnet run --project backend/tools/Sedno.ModelBenchmark -- --live --agent --rounds 5
```

Klucz `OpenAI:ApiKey` jest współdzielony z aplikacją przez sekrety
`sedno-backend-dev`. Ustawienia agenta (`OpenAI:AgentId`, opcjonalnie
`OpenAI:TimeoutSeconds`) przechowuj osobno w `sedno-model-benchmark`:
`dotnet user-secrets set "OpenAI:AgentId" "agent_..." --id sedno-model-benchmark`.
Narzędzie odczytuje najpierw sekrety aplikacji, potem benchmarku, a na końcu
zmienne środowiskowe (`OpenAI__ApiKey`, `OpenAI__AgentId`).
Nie podawaj klucza w argumentach polecenia. Bez `--live` program pokazuje pomoc
i nie wysyła żądań. Bez `--agent` testuje tylko dwa warianty Responses.

Domyślne ustawienia to `--model gpt-6-luna --effort none`.
Oba warianty używają tego samego modelu, promptu, limitu 4096 tokenów wyjściowych,
`store=false` i niezależnych wiadomości bez `conversation`/`previous_response_id`.
Różnią się wyłącznie `service_tier`: `default` i `fast`.
[Fast mode](https://developers.openai.com/api/docs/guides/fast-mode) może zwrócić
`priority` jako faktycznie użyty tryb; raport zapisuje `trybOtrzymany`.
`store=false` nie oznacza wyłączenia wszystkich zasad retencji dostawcy.

Prompt znajduje się w [wspólnym pliku simplify.pl.txt](../../src/Sedno.Infrastructure/Prompts/simplify.pl.txt), jest
osadzony w programie podczas kompilacji i podlega wersjonowaniu w Git.
To prompt przekazany przez użytkownika do porównania z zapisanym agentem.
Migracja zachowała aktualny plik użytkownika, z poprawionym numerem działki 887/6.
Historyczne raporty zachowują wcześniejsze hashe; nowy prompt ma hash
`31DA60C0D623E64C7FD6CEABFA9F69FADA2E8321CE839C8B8B37A2F21109DE02`.
Można wskazać inny plik przez `--prompt ścieżka`; raport zawiera SHA-256 użytej treści.
Narzędzie nie aktualizuje konfiguracji zapisanego agenta. Przed porównaniem należy
potwierdzić zgodność modelu, reasoning i promptu w Platform.

Każdy wariant ma jedno wywołanie rozgrzewkowe, wyłączone z podsumowania.
Następnie wykonuje 3 syntetyczne próbki różnej długości na rundę (1–20 rund).
Kolejność wariantów rotuje, żądania są sekwencyjne, klient HTTP jest współdzielony
między wariantami Responses. Dla 5 rund i 3 wariantów to 48 wywołań.
Próbki średnia i długa powtarzają zdania, więc nie zastępują reprezentatywnego
korpusu tekstów. Cache i zmienne obciążenie dostawcy mogą wpływać na wynik.

JSONL na stdout zawiera czas do gotowego, zweryfikowanego tekstu, długości,
status, HTTP i liczbę tokenów dla Responses. Agent używa istniejącego
`OpenAiAgentProvider` z katalogu `Agents` i zwraca wynik przy final answer, jak dawny backend.
Nie mierzymy czasu do pierwszego tokenu ani pełnego czasu mobilnej aplikacji,
bazy i autoryzacji. Limit 8 sekund odpowiada obecnym adapterom.
Błędy i timeouty są liczone oddzielnie; mediana i p95 dotyczą tylko sukcesów.
Mała próbka nie daje stabilnego p95. Porównuj także poszczególne próbki i długości
wyników — krótszy wynik może być szybszy, ale mniej kompletny.

Domyślnie nie zapisujemy treści wejść ani odpowiedzi. Na wyraźne życzenie można
wyeksportować wbudowane syntetyczne próbki i ich wyniki do tabeli Markdown:

```sh
dotnet run --project backend/tools/Sedno.ModelBenchmark -- --live --agent --rounds 5 --text-report backend/tools/Sedno.ModelBenchmark/results/2026-10-16.md
```

Opcja `--text-report` dopisuje nową sekcję do istniejącego pliku, z podsumowaniem
i wszystkimi wywołaniami (także rozgrzewką). Nie zmienia logów JSONL ani zachowania
aplikacji. Raport powstaje po zakończeniu serii; przerwanie programu może utracić
odpowiedzi przechowywane dotąd w pamięci. Nie zapisujemy sekretów ani identyfikatorów sesji.
Agent korzysta z istniejącego mechanizmu sprzątania, w tym odzyskiwania starych
sesji Sedno tego agenta. Najlepiej testować na dedykowanym agencie deweloperskim.
Po serii program czeka do 30 sekund na sprzątanie. Jeżeli go nie potwierdzi,
zwraca błąd i zaleca uruchomienie `--live --cleanup-agent` z tym samym agentem, by ponowić usuwanie.
Brak automatycznych ponowień generowania. Kod wyjścia: 0 sukces, 1 błędy pomiarów
lub sprzątania, 2 błąd konfiguracji, 130 przerwanie.

Decyzja o migracji wymaga powtarzalnej poprawy czasu bez wzrostu liczby błędów
oraz osobnego sprawdzenia zachowania sensu, liczb i przeczeń. Aplikacja używa Responses default. Narzędzie nie zmienia jej konfiguracji.

## Wspólny kod i sprzątanie migracji

Responses używa `Sedno.Infrastructure.ResponsesClient`, tego samego transportu,
walidacji i diagnostyki co aplikacja. Wspólny prompt jest osadzony w Infrastructure.
Opcje `--model`, `--effort`, `--prompt` nadal pozwalają eksperymentować bez zmiany
produkcyjnej listy dopuszczonych ustawień. Testy agenta są w `Sedno.ModelBenchmark.Tests`.

Samo sprzątanie bez generowania tekstów:

```sh
dotnet run --project backend/tools/Sedno.ModelBenchmark -- --live --cleanup-agent
```

Zatrzymaj wcześniej ruch starego backendu agenta. Polecenie czeka do 55 sekund
na odzyskanie i usunięcie oznaczonych sesji skonfigurowanego agenta; wynik 0
potwierdza opróżnienie kolejki i zakończenie odzyskiwania. Młode sesje mogą wymagać
kolejnego uruchomienia. Stare sesje bez oznaczenia Sedno wymagają osobnej kontroli.
