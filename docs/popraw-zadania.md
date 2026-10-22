# Tryby „Uprość” i „Popraw” — 22.10.2026

Makieta: [Przelaczanie.png](Przelaczanie.png).

## Lista zadań

- [x] Dodać tryb do żądania API; zachować domyślne upraszczanie dla starszych aplikacji, wspólny limit i rozróżnienie żądań przy ponowieniach.
- [x] Dodać osobny, osadzony prompt poprawiania bez zmiany promptu upraszczania i ustawień produkcyjnego modelu.
- [x] Wprowadzić przełącznik zgodny z makietą, zmienne opisy i ukrywanie aparatu w trybie „Popraw”. Zachować wpisany tekst.
- [x] Dodać lokalny odczyt tekstu po polsku pod przyciskiem głośnika; zatrzymywać go po opuszczeniu ekranu i zmianie trybu.
- [x] Rozróżnić wyniki obu trybów i zachować ten wybór w szyfrowanej historii, z obsługą starszych wpisów.
- [x] Dodać testy logiki, interfejsu i API oraz uruchomić formatowanie, analizę i testy.
- [x] Opisać zachowanie i ograniczenia weryfikacji; przygotować listę prób na telefonie.

## Zachowanie

Strzałki nad przyciskiem przełączają tryby. Zmieniają się nagłówek,
przycisk, opisy dostępności i ekran wyniku. W „Popraw” znika aparat,
a mikrofon zastępuje odczyt tekstu wpisanego w pole. Głośnik nie uruchamia AI
ani nie zużywa dziennego limitu. Zatrzymanie, zmiana trybu, otwarcie menu,
wysłanie tekstu oraz przejście do tła kończą odczyt. Brak lokalnego polskiego
głosu powoduje czytelny komunikat.

Poprawianie usuwa błędy językowe i zachowuje sens, liczby, godziny oraz pytania;
nie odpowiada na pytania zawarte w tekście. Dotychczasowy prompt uproszczeń
pozostaje bez zmian. Oba tryby mają wspólne limity 5/400 dziennie,
limit 4000 znaków, informację o AI i zasady retencji historii.

Najpierw należy wdrożyć backend z obsługą `mode=correct`, potem aplikację.
API potwierdza tryb w wyniku. Aplikacja odrzuca odpowiedź starego serwera,
który zignorował nowy tryb, zamiast nazwać uproszczenie poprawionym tekstem.
Stary serwer może wcześniej naliczyć takie żądanie do limitu, dlatego
kolejność wdrażania jest istotna. Nie potrzeba nowych usług ani migracji bazy.
Backend z aktualnymi promptami wdrożono 22.10.2026 jako `sedno-api-00012-9j4`.
Przygotowano podpisany AAB 12. Publicznej strony z polityką nie publikowano.
[Raport wdrożenia](backend-deployment-2026-10-22.pl.md).

## Zmienione pliki

- Backend: `Contracts.cs`, `SimplificationService.cs`, `OpenAiModelProvider.cs`,
  `Providers.cs`, plik projektu Infrastructure oraz nowe
  [CorrectionPrompt.cs](../backend/src/Sedno.Infrastructure/CorrectionPrompt.cs) i
  [correct.pl.txt](../backend/src/Sedno.Infrastructure/Prompts/correct.pl.txt).
- Kontrakt: [openapi.yaml](../contracts/openapi.yaml), opcjonalne `mode` w żądaniu
  i potwierdzenie w wyniku; starsze żądania nadal upraszczają tekst.
- Aplikacja: `app.dart`, `home_screen.dart`, `text_input_view_model.dart`,
  nowe `text_mode.dart`, modele żądań i wyników, repozytorium HTTP,
  ViewModel wysyłania, ekran wyniku i historii oraz makiety Development.
- Odczyt: nowy moduł `features/speech_output/`,
  `LocalTextPlaybackController.kt`, rejestracja w `MainActivity.kt`
  i deklaracja usługi TTS w manifeście Androida. Bez nowych zależności.
- Testy: wybór promptu, API, HTTP, ponowienia po zmianie trybu, interfejs,
  historia, kanał odczytu, jego zatrzymywanie i błędy, dostępność obu trybów
  przy skali tekstu 1 i 2,5. Testowa mowa tworzy Future w zegarze testu widgetu;
  test powrotu z tła odtwarza pełną sekwencję stanów Androida.
- Dokumenty: główny README, README aplikacji i backendu, Tasks.md,
  źródło informacji o prywatności i wygenerowane pliki Dart, Markdown oraz HTML.
  Lokalna wersja polityki: 22.10.2026.

## Weryfikacja

- `dart format lib test` — wykonano.
- `flutter analyze` — bez uwag.
- `flutter test` — 204 testy przeszły, w tym dostępność obu trybów przy skali 1 i 2,5.
- `dotnet test backend/Sedno.Backend.sln --no-restore` — 237 testów przeszło:
  106 jednostkowych, 93 integracyjne z emulatorem Firestore i 38 narzędzi pomiarowych.
- `python3 tools/generate_privacy_policy.py --check` — dokumenty spójne.
- `JAVA_HOME=/opt/android-studio/jbr ./gradlew :app:compileDebugKotlin :app:testDebugUnitTest`
  — kompilacja Kotlin i testy Androida przeszły (`BUILD SUCCESSFUL`).
  Gradle zgłasza ostrzeżenia o przestarzałych ustawieniach i zależnościach.
- Po zmianie daty lokalnej polityki dodatkowo przeszło 10 testów ekranów
  prywatności i informacji o aplikacji; generator ponownie potwierdził spójność.

Testy nie wywoływały rzeczywistego modelu ani produkcyjnej bazy.
Po kontroli braku miejsca zbudowano APK debug; AAB nie budowano. Obsługa odczytu wymaga próby z silnikiem TTS
na prawdziwym telefonie; atrapy potwierdzają przepływ aplikacji.

## Odbiór na telefonie i wdrożenie

- [x] Wdrożyć backend przed aplikacją — rewizja `sedno-api-00012-9j4`.
- [ ] Sprawdzić poprawianie rzeczywistym modelem.
- [ ] Sprawdzić przełącznik, zachowanie tekstu i ukrycie aparatu zgodnie z makietą.
- [ ] Sprawdzić polski odczyt w trybie samolotowym, zatrzymywanie, menu i powrót z tła.
- [ ] Sprawdzić brak zainstalowanego polskiego głosu i komunikat o błędzie.
- [ ] Sprawdzić TalkBack, powiększony tekst, długi tekst, błąd sieci i zachowanie pola po błędzie.
- [ ] Ocenić korektę na przykładach: literówki, interpunkcja, poprawny tekst,
  przeczenia, pytania, liczby, daty, godziny i polecenia umieszczone w treści.
- [ ] Opublikować zaktualizowaną politykę wraz z udostępnieniem funkcji.

## Kontrola kompilacji po braku miejsca — 22.10.2026

- Ponowne `dotnet build backend/Sedno.Backend.sln --no-restore` zakończone
  powodzeniem: 0 ostrzeżeń, 0 błędów.
- Pełne `flutter build apk --debug --dart-define-from-file=config/firebase.local.json`
  zakończone powodzeniem. APK: `mobile/build/app/outputs/flutter-apk/app-debug.apk`,
  190,6 MiB. Sprawdzono integralność ZIP oraz obecność manifestu, DEX i biblioteki arm64.
  `apksigner verify` potwierdził poprawność podpisu APK.
- SHA-256 APK: `c850ff7e0d8c31b923637eb5217741a307f137a970b7b2d9ff8c8a0c7f0d4f4d`.
- Po kompilacji pozostało około 6,1 GB wolnego miejsca. Nie usuwano plików projektu.
- Android zgłasza ostrzeżenia dotyczące przyszłej zgodności pluginów
  `firebase_auth` i `firebase_core` z mechanizmem Built-in Kotlin; nie przerwały budowania.
- To kontrola kompilacji debug; nie wykonano publikacji ani testu instalacji na telefonie.
