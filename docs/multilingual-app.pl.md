# Języki aplikacji Sedno

Aktualny kod rozszerzono do [13 wariantów językowych](multilingual-13-languages.pl.md).
Poniższy raport opisuje pierwotne przygotowanie PL i UK oraz ówczesne testy.

Na branchu `feature/multilingual-app` przygotowano polski i angielski (UK).
Jedna aplikacja, backend, baza i wspólne limity obsługują oba języki.

## Zachowanie

- Przy pierwszym uruchomieniu aplikacja wybiera pierwszy obsługiwany język
  z preferencji telefonu. Gdy żadnego nie obsługuje, wybiera polski.
- Menu użytkownika → Język pozwala wybrać polski, English (UK) albo język telefonu.
  Ręczny wybór jest przechowywany lokalnie w bezpiecznym magazynie.
- Wybrany język obejmuje interfejs, upraszczanie, poprawianie, dyktowanie,
  odczyt i wiadomości Firebase wysyłane z aplikacji.
- Wybierz język tekstu przed wysłaniem. To nie jest funkcja tłumaczenia między językami.
- Zmiana języka zachowuje edytor, oryginał, historię i użyty limit.
  Żądanie już rozpoczęte kończy się w języku wybranym w chwili wysłania.
- Angielski używa pisowni brytyjskiej i tagu mowy `en-GB`.
  Odczyt preferuje lokalny głos brytyjski, a przy jego braku może wybrać inny
  pobrany głos angielski. Głosy wymagające sieci są wykluczone.
- Mikrofon nadal wymaga Androida 13+ i odpowiedniego lokalnego modelu.
  Brak modelu lub głosu wyświetla komunikat w wybranym języku;
  nie uruchamia przetwarzania w chmurze.
- OCR pozostaje lokalny, z modelem pisma łacińskiego.
- Historia zapisuje język wyniku. Starsze wpisy bez tego pola oznaczają polski.
- W aplikacji dostępne są obie wersje polityki prywatności. Odnośniki do
  istniejącej strony, prywatności i usuwania konta prowadzą do polskich stron;
  angielska polityka jasno to opisuje. Strona marketingowa nie została przetłumaczona.

## Źródła tłumaczeń i promptów

Interfejs: `mobile/lib/l10n/app_pl.arb` i `app_en.arb`.
Klasy Dart tworzy `flutter gen-l10n`; konfiguracja jest w `mobile/l10n.yaml`.
Przekazuj tłumaczenia do ViewModeli i usług przez istniejące callbacki
`localizations`. Nie wprowadzaj globalnej zmiennej z bieżącym językiem.
Dane użytkownika i wyniki AI nie przechodzą przez katalog tłumaczeń.

Prompty są osobnymi zasobami w `backend/src/Sedno.Infrastructure/Prompts/`:
`simplify.pl.txt`, `correct.pl.txt`, `simplify.en-gb.txt`, `correct.en-gb.txt`.
Kod `en` w API wybiera wariant promptów `en-gb`; tag mowy i locale Androida
pozostają `en-GB`. Nazwy wariantów plików nie zmieniają zapisanych języków historii.
`SimplificationPrompt.ForLanguage` i `CorrectionPrompt.ForLanguage` wybierają
zasób. Dostęp przez `.Text` pozostaje polski, także dla dawnych benchmarków.
Polskie prompty zachowano bez zmian względem stanu na początku tej pracy.
Angielskie prompty mają własne przykłady; nie są potwierdzeniem odbioru jakościowego
przez rodzimych użytkowników języka ani grupę docelową.

Polityka: `docs/privacy-policy.pl.json` i `docs/privacy-policy.en.json`.
Polski generator pozostaje właścicielem dotychczasowych dokumentów publicznych.
`python3 tools/generate_privacy_translations.py` tworzy angielską politykę w Dart
oraz Markdown. Po generowaniu uruchom `dart format mobile/lib`.
Oba generatory mają opcję `--check`.

## API i kolejność wdrożenia

`POST /v1/simplifications` przyjmuje `language: pl | en` i zwraca język w wyniku.
Brak pola nadal oznacza `pl`. Nieobsługiwany język jest odrzucany przed rezerwacją
limitu, z kodem `invalid_language`. Język jest częścią zabezpieczonego odcisku
żądania; polskie odciski zachowują zgodność z poprzednią wersją.

Najpierw wdróż nowy backend, potem aplikację. Stary backend może zignorować nowe
pole; aplikacja odrzuca wynik oznaczony innym językiem i pozostawia tekst do edycji.
Backend wdrożono 23.10.2026; przygotowano AAB 16.
[Raport wdrożenia](backend-deployment-2026-10-23.pl.md). Aplikacji nie publikowano w Google Play.
Ustawienia produkcyjnego modelu, retencji, timeoutu i limitu tokenów są wspólne.

## Dodawanie następnego języka

1. Dodaj język do `features/shared/domain/app_language.dart`, jego locale do
   `app/app_language.dart` oraz nazwę w ekranie wyboru języka.
2. Przygotuj kompletny katalog ARB z tymi samymi kluczami i parametrami.
3. Dodaj dwa pliki promptów, ich wybór w klasach promptów, listę języków
   w `OpenAiModelProvider` i walidacji `SimplificationService` oraz kontrakt OpenAPI.
4. Dodaj źródło polityki prywatności i wpis w `LocalizedPrivacyPolicy`.
   Generator tłumaczeń polityki przyjmuje pliki kolejnych języków; jego nagłówki
   dokumentów wymagają wtedy dopasowania do tego języka.
5. Rozszerz listę dozwolonych tagów lokalnej mowy w Androidzie i sprawdź
   OCR, dostępność głosów, układ, odmiany komunikatów i potrzeby pisma RTL.
6. Dodaj syntetyczne testy języka, ponowień i wspólnego limitu. Oceń oba tryby
   z osobami znającymi język i potrzeby odbiorców, a funkcje lokalne na telefonie.

## Kontrole przed udostępnieniem

Oprócz testów automatycznych sprawdź na urządzeniu: angielski OCR, dyktowanie
z modelem i bez niego, lokalny odczyt z głosem i bez niego, wiadomości weryfikacji
oraz resetu hasła w Firebase, cenę subskrypcji z Google Play i powrót do oryginału.
Wymagane są również ocena językowa promptów i odbiór z grupą docelową.

## Wyniki weryfikacji — 23.10.2026

- `dart format lib test`: wykonano; końcowe sprawdzenie nie wymaga zmian.
- `flutter analyze --no-pub`: brak problemów.
- `flutter test --no-pub`: 261 testów zakończonych powodzeniem.
  Obejmuje oba języki i tryby, skalę tekstu 1,0 i 2,5, kontrast, etykiety,
  cele dotykowe, wybór języka, walidację, zgodność katalogów i format kanałów mowy.
- `dotnet test --no-restore -m:1`: 111 testów jednostkowych, 99 integracyjnych
  i 38 testów narzędzia benchmarkowego zakończonych powodzeniem.
  Integracje użyły emulatora Firestore w kontenerze i syntetycznego modelu.
- `JAVA_HOME=/opt/android-studio/jbr ./gradlew :app:compileDebugKotlin`:
  `BUILD SUCCESSFUL`. Podpisany AAB 16 zbudowano następnie w ramach wdrożenia.
- Oba generatory polityki prywatności: `--check` potwierdza zgodność źródeł.
- Potwierdzono, że polski prompt upraszczania jest identyczny ze stanem na początku
  tej pracy, obejmującym wcześniejsze lokalne zmiany właściciela.

Nie wykonywano wywołań rzeczywistego modelu, zakupów, wysyłania wiadomości
Firebase ani prób na fizycznym telefonie. Testy nie zastępują oceny jakości
językowej wyników AI. Backend wdrożono w kolejnym kroku, opisanym w raporcie z 23.10.2026; aplikacji nie publikowano w Google Play.

## Główne zmienione pliki

- Lokalizacja i konfiguracja: `mobile/l10n.yaml`, `mobile/pubspec.yaml`,
  `mobile/pubspec.lock`, `mobile/lib/l10n/`, `mobile/lib/app/app.dart`,
  `app_language.dart`, `language_screen.dart`, `mobile/lib/main.dart`.
- Ekrany i komunikaty: pliki w `mobile/lib/features/*/presentation/`,
  usługi mowy i odczytu, `firebase_account_repository.dart`,
  `backend_session_gateway.dart` i `development_mocks.dart`.
- Metadane języka: `features/shared/domain/app_language.dart`,
  `simplification_result.dart` i `simplification_view_model.dart`.
- Backend: `Contracts.cs`, `SimplificationService.cs`, `OpenAiModelProvider.cs`,
  `SimplificationPrompt.cs`, `CorrectionPrompt.cs`, `Providers.cs`,
  `Sedno.Infrastructure.csproj`, dwa nowe prompty `.en.txt` i `contracts/openapi.yaml`.
- Prywatność: polskie i angielskie źródła JSON, wygenerowane dokumenty i modele
  Dart, `localized_privacy_policy.dart`, `tools/generate_privacy_translations.py`.
  Polski generator odświeżył też istniejące strony prywatności i usuwania konta.
- Testy: `mobile/test/l10n/language_test.dart`, `flutter_test_config.dart`,
  testy dostępności i nawigacji, test kanału odczytu oraz nowe `LanguageTests.cs`
  w projektach jednostkowym i integracyjnym backendu.
- Instrukcje: `AGENTS.md`, README aplikacji i backendu oraz ten dokument.

W repozytorium już przed rozpoczęciem były lokalne zmiany w innych plikach.
Zachowano je; ta lista opisuje zakres prac nad wersją angielską.
