# Sedno — raport integracji modelu

15 października 2026 r. Wykonano adapter i automatyczną weryfikację. Pełny odbiór
zadania 12 pozostaje otwarty: brak próby prawdziwego API, pomiaru kosztów i ręcznego
audytu dostępności na Androidzie. Nie wdrożono usług produkcyjnych.

## Zmiany

| Pliki | Zakres |
| --- | --- |
| `backend/src/Sedno.Infrastructure/OpenAiModelProvider.cs` | Adapter Responses API, instrukcja uproszczeń, walidacja konfiguracji, limit czasu, bezpieczne błędy, ograniczenie odpowiedzi. |
| `backend/src/Sedno.Infrastructure/ModelRegistration.cs` | Rejestracja przez DI, wybór jawnego dostawcy, wyłączenie loggerów HTTP i przekierowań. |
| `backend/src/Sedno.Api/Program.cs` | Użycie rejestracji adaptera. |
| `backend/src/Sedno.Api/appsettings.json` | Domyślny model i ograniczenia; bez klucza. |
| `backend/tests/Sedno.UnitTests/OpenAiModelTests.cs` | Testy żądań i oddzielenia danych od instrukcji, błędów, limitów, odmów, czasu, anulowania i konfiguracji. |
| `backend/tests/Sedno.IntegrationTests/OpenAiApiTests.cs` | Rzeczywisty adapter z imitacją HTTP i prawdziwym PostgreSQL: sukces, idempotencja, błędy HTTP, timeout, niepełna odpowiedź, zwalnianie limitu, brak treści i kluczy w logach. |
| `mobile/lib/features/simplification/data/http_simplification_repository.dart` | 30 sekund oczekiwania zamiast 8; backend ogranicza wywołanie modelu do 20 sekund domyślnie, maksymalnie 25. |
| `mobile/lib/features/privacy/presentation/privacy_screen.dart` | Nazwanie OpenAI w informacji przed wysłaniem i aktualizacja stanu integracji. |
| `mobile/test/features/home/presentation/home_screen_test.dart` | Sprawdzenie nazwy dostawcy przed pierwszym wysłaniem. |
| `mobile/test/features/privacy/presentation/privacy_screen_test.dart` | Mały ekran, powiększenie tekstu 250%, przewijanie informacji. |
| `README.md`, `backend/README.md` | Stan integracji i instrukcja lokalnej konfiguracji klucza przez user-secrets. |
| `docs/privacy-policy-draft.pl.md`, `docs/privacy-operations-plan.pl.md`, `docs/google-play-data-safety.pl.md` | Rozróżnienie zaimplementowanego adaptera i niepotwierdzonego wdrożenia. |
| `docs/model-acceptance.pl.md` | Sztuczne przypadki odbioru jakości, procedura pomiaru kosztów i ręcznego sprawdzenia Androida. |
| `docs/task-12-report.pl.md` | Ten raport. |

## Weryfikacja

- Punkt wyjścia: analiza Flutter bez problemów, 92 testy Flutter, 24 jednostkowe
  i 21 integracyjnych backendu przeszły.
- `dart format lib test`: 59 plików, bez zmian formatowania.
- `flutter analyze`: bez problemów.
- Końcowe `flutter test`: 93 testy przeszły.
- Końcowe `dotnet test Sedno.Backend.sln`: 43 jednostkowe i 24 integracyjne
  przeszły; PostgreSQL uruchamiany przez Testcontainers.
- `flutter build apk --debug`: sukces; plik
  `mobile/build/app/outputs/flutter-apk/app-debug.apk`.
- `git diff --check`: bez błędów.

Nowy test prywatności wymagał poprawienia sprawdzania widoczności: przy czcionce
250% akapit jest wyższy niż ekran, więc jego środek może leżeć poza ekranem.
Test sprawdza teraz przecięcie akapitu z obszarem widoku i możliwość przewijania.

## Ograniczenia i dalszy odbiór

Nie wykonano płatnych wywołań OpenAI ani nie ustawiono klucza. Dostępność modelu
potwierdzono w [oficjalnej dokumentacji](https://developers.openai.com/api/docs/models/gpt-6-luna),
a nie na koncie właściciela. Konfiguracja produkcyjna nadal domyślnie wyłącza AI.
Uruchomienie opisano w `backend/README.md`, sekcja OpenAI simplification.

Testy sprawdzają strukturę ochrony przed poleceniami w tekście, a nie skuteczność
prawdziwego modelu. Jakość, zachowanie znaczenia i odporność wymagają prób
z `docs/model-acceptance.pl.md`. Koszt podany tam jest szacunkiem, nie pomiarem.

Android SDK jest dostępny, ale nie wykryto telefonu ani uruchomionego emulatora.
Nie sprawdzono ręcznie aparatu/OCR, TalkBack ani logowania i zakupów na urządzeniu.
Testy widgetów nie stanowią pełnego audytu WCAG. APK jest kompilacją debug,
bez skonfigurowania produkcyjnych usług i bez podpisu wydawniczego.
Kompilacja zgłasza ostrzeżenie o użyciu starszego sposobu integracji Kotlin przez
wtyczki Firebase; nie blokuje ono obecnej kompilacji.
