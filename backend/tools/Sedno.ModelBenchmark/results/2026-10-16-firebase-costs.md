# Koszt modelu — kontrola migracji Firebase

16.10.2026. Nowy pomiar na wbudowanych syntetycznych tekstach, bez treści ruchu
aplikacji i bez eksportu tekstów. Polecenie:

```sh
dotnet run --project backend/tools/Sedno.ModelBenchmark -- --live --rounds 1
```

[Surowe metryki bez treści](2026-10-16-firebase.jsonl). Benchmark wykonał 8 płatnych
wywołań: po jednej rozgrzewce i trzech próbkach dla default oraz fast. Wszystkie
zakończyły się sukcesem. Produkcja nadal używa wyłącznie default. Prompt zachowany:
`31DA60C0D623E64C7FD6CEABFA9F69FADA2E8321CE839C8B8B37A2F21109DE02`.

Stawki bazowe produkcyjnego gpt-6-luna Standard potwierdzone w
[oficjalnej dokumentacji OpenAI](https://developers.openai.com/api/docs/models/gpt-6-luna):
0,10 USD / milion tokenów wejściowych, 0,50 USD / milion wyjściowych.

| Znaki wejścia | Tokeny wejścia | Tokeny wyjścia | Czas ms | Koszt bazowy USD |
| --- | ---: | ---: | ---: | ---: |
| 129 | 977 | 49 | 1771,16 | 0,00012220 |
| 1014 | 1209 | 61 | 1342,77 | 0,00015140 |
| 3951 | 2183 | 68 | 1952,95 | 0,00025230 |
| Razem bez rozgrzewki | 4369 | 178 | — | 0,00052590 |

Średnio 0,00017530 USD na uproszczenie; ekstrapolacja 1000 takich wywołań:
0,17530 USD. To wycena zmierzonych tokenów, nie pomiar 1000 wywołań ani faktura.
Mediana czasu tych trzech próbek to 1771,16 ms.

Default z rozgrzewką: 5346 tokenów wejścia i 225 wyjścia, bazowo 0,00064710 USD.
Eksperymentalny fast: 5346 wejścia i 219 wyjścia łącznie z rozgrzewką; zachowano
metryki do porównania, bez mieszania ich z produkcyjną średnią. Rzeczywisty koszt
całej sesji obejmuje również fast i należy go sprawdzić w rozliczeniu dostawcy.

Próbki są małe, a dłuższe teksty powtarzają zdania. Pomiar nie ocenia jakości
języka ani odporności modelu na prompt injection. Testy atrap potwierdzają
oddzielenie danych od instrukcji i niezmienność parametrów, nie gwarantują
zachowania rzeczywistego modelu dla każdego tekstu.

Wyliczenie nie uwzględnia odczytu/zapisu cache, dopłat za rezydencję regionalną,
podatków, kursów walut, opłat Play ani kosztów Firebase/Cloud Run/Cloud SQL.
Manifest z min. jedną instancją i CPU bez throttlingu ma stały koszt hostingu.
