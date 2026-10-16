# Migracja na Responses default — 16.10.2026

Aplikacja korzysta z `OpenAiModelProvider` → `ResponsesClient`: `gpt-6-luna`,
`service_tier=default`, `reasoning.effort=none`, `store=false`, 4096 tokenów wyjścia,
timeout 8 s. Endpoint mobilny i schemat bazy pozostały bez zmian.

## Zmienione obszary

- `backend/src/Sedno.Infrastructure`: wspólny `ResponsesClient`, `SimplificationPrompt`,
  zasób `Prompts/simplify.pl.txt`, adapter i rejestracja dostawcy; usunięto kod agenta.
- `backend/src/Sedno.Api`: konfiguracja środowisk wybiera `openai`; logi zawierają
  etapy Responses. `Sedno.Application/SimplificationTimings.cs` nie zawiera etapów agenta.
- `backend/tools/Sedno.ModelBenchmark`: wspólny klient i prompt, przeniesiony katalog
  `Agents`, oddzielne sekrety oraz `--live --cleanup-agent`. Eksport syntetycznych
  tekstów i historyczne raporty zachowano.
- `backend/tests`: testy agenta przeniesiono do `Sedno.ModelBenchmark.Tests`;
  usunięto nieaktualne testy produkcyjnego routingu agenta. Testy jednostkowe i
  integracyjne Responses sprawdzają wspólny prompt, parametry, błędy i limity.
  Testowa konfiguracja jawnie wybiera mock bez używania klucza dewelopera.
- Zaktualizowano solution i referencje projektów, `AGENTS.md`, główny i backendowy
  README, README benchmarku oraz dokumenty odbioru modelu i prywatności.

Prompt przeniesiono bez zmiany aktualnej treści użytkownika, już z numerem działki
887/6. SHA-256: `31DA60C0D623E64C7FD6CEABFA9F69FADA2E8321CE839C8B8B37A2F21109DE02`.
Raporty poprzednich pomiarów mają własne historyczne hashe.

## Weryfikacja

- .NET: 53 testy jednostkowe aplikacji, 31 integracyjnych z PostgreSQL,
  38 testów benchmarkowego agenta — wszystkie przeszły.
- Flutter: `flutter analyze` bez problemów; 102 testy przeszły.
- `dart format --output=none --set-exit-if-changed lib test`: 61 plików, bez zmian.
- Formatowanie C# i `git diff --check`: poprawne.
- Jedno rzeczywiste wywołanie przez produkcyjny adapter i lokalną konfigurację:
  poprawny wynik, około 1777 ms; nie zapisano treści.
- Sprzątanie oznaczonych sesji skonfigurowanego agenta zakończyło się kodem 0.
  Ponowne sprawdzenie z osobnym magazynem sekretów benchmarku również przeszło.

Lokalny sekret `Model:Provider` ustawiono na `openai`, zachowano `OpenAI:ApiKey`.
`OpenAI:AgentId` i ustawienia czasu agenta przeniesiono do `sedno-model-benchmark`.
Sekrety nie są częścią repozytorium. Działający proces backendu wymaga restartu,
aby odczytać nowy kod i konfigurację. Nie wykonano zdalnego wdrożenia produkcyjnego.

Nie wykonano ręcznego przejścia Android → backend → OpenAI ani budowania APK.
Automatyczne testy mobilne obejmują dotychczasowy przepływ i kontrakt, a rzeczywisty
smoke test obejmuje produkcyjny adapter z OpenAI. NuGet zgłosił NU1900 z powodu
niedostępnego audytu podatności; kompilacja i testy korzystały z lokalnych pakietów.
