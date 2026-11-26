# Co zajmuje czas podczas zimnego startu Sedna

Przy próbniku co 5 s Sedno zaczynało nasłuchiwać, a do potwierdzenia gotowości pozostawało jeszcze **4,26 s w medianie**. Przy próbniku co 1 s ten odcinek wyniósł **449 ms**. W obu przypadkach badaliśmy start serwerowej aplikacji Sedno.

## Co zmierzyliśmy

Wszystkie komórki z czasem podają medianę i P95. Dla Go czas do gotowości HTTP biegnie od pierwszego znacznika w programie aż do chwili, gdy gniazdo nasłuchuje. Dla Sedna serwer jest gotowy, gdy ASP.NET Core zgłosi `ApplicationStarted`.

| Próbnik | Program | Cloud Run → wejście do kontenera | Uruchomienie .NET → pierwsza linia Sedna | Sedno lub Go → gotowość HTTP | Gotowość HTTP → udany próbnik |
| --- | --- | ---: | ---: | ---: | ---: |
| 5 s | Sedno | 149 ms / 394 ms | 367 ms / 494 ms | 641 ms / 733 ms | 4,26 s / 4,43 s |
| 5 s | Go | 147 ms / 311 ms | — | 3 ms / 4 ms | 4,98 s / 4,99 s |
| 1 s | Sedno | 180 ms / 367 ms | 321 ms / 459 ms | 607 ms / 830 ms | 449 ms / 1,26 s |
| 1 s | Go | 190 ms / 360 ms | — | 3 ms / 7 ms | 980 ms / 987 ms |

| Próbnik | Program | Zimne starty | Pierwsza odpowiedź | Ciepła odpowiedź |
| --- | --- | ---: | ---: | ---: |
| 5 s | Sedno | 30 | 5,52 s / 5,74 s | 37 ms / 234 ms |
| 5 s | Go | 30 | 5,20 s / 5,36 s | 34 ms / 43 ms |
| 1 s | Sedno | 30 | 1,65 s / 2,67 s | 35 ms / 136 ms |
| 1 s | Go | 30 | 1,25 s / 1,41 s | 33 ms / 42 ms |

Pierwszy odcinek w tabeli jest przybliżeniem. Zaczyna się od logu Cloud Run o uruchamianiu instancji, a kończy przy pierwszym znaczniku programu w kontenerze. Obejmuje pracę platformy oraz dotarcie do kodu wejściowego. Wariant Sedno zapisuje też osobny znacznik bezpośrednio przed uruchomieniem procesu `dotnet`. Surowe wyniki zawierają moment dojścia pierwszego próbnika do gotowego serwera, co pozwala oddzielić oczekiwanie na próbnik od potwierdzenia odpowiedzi. Mediany obliczono dla każdego etapu osobno.

## Warunki

- Prywatne usługi Cloud Run w Warszawie używały identycznego obrazu `sha256:78f407c035c74716529c1cb88ec2e0fe8ab03b9e38fe851c20bbe14c31473eff`, 1 vCPU, 512 MiB, `min=0`, `max=1` i `concurrency=80`. Oba warianty działały bez Startup CPU Boost. Sedno opublikowano w IL na .NET 10. Model i Billing wyłączono w konfiguracji testowej. Tryb Go zwracał wyłącznie `200 OK` na `/health/live`.
- Operacyjny próbnik w chmurze sprawdzał `/health/live`. Każdą próbę powiązano z logami Cloud Run i znacznikami tej samej nowej instancji. Czas klienta rozpoczynał się po TLS. Do statystyk ciepłej odpowiedzi weszło 29 prób dla Sedna z próbnikiem 1 s i po 30 w pozostałych wariantach. Jedno ponowne żądanie trafiło na inną instancję. W samym logu Cloud Run i znaczniku wejścia obowiązują zegary dwóch warstw, dlatego ich różnicę traktujemy jako przybliżenie.
- Pierwszy odczyt `/health/ready` w osobnych lokalnych kontenerach z emulatorem Firestore miał medianę **278 ms** i P95 **459 ms** w 30 próbach. Pomiar zaczynał się wewnątrz obsługi endpointu po wstrzyknięciu zależności. Ten wynik opisuje lokalny emulator.
- Znaczniki dodano do kopii źródeł tworzonej wyłącznie do testu. Produkcja zachowała `min=1`. Po pomiarze usunięto cztery usługi testowe, pakiet obrazu i konto runtime. Przeszło 286 testów .NET. Serwer Go skompilował się i przeszedł próbę HTTP w Dockerze.

[Próbnik 5 s](../backend/tools/performance/results/2026-11-26-phases-p5.json) · [Próbnik 1 s](../backend/tools/performance/results/2026-11-26-phases-p1.json) · [Odczyt Firestore](../backend/tools/performance/results/2026-11-26-phases-firestore-emulator.json) · [Odtworzenie pomiarów](../backend/tools/performance/README.md)
