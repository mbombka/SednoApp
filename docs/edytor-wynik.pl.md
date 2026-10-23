# Wynik w edytorze

Po operacji Uprość lub Popraw wynik zastępuje tekst w tym samym polu.
Pozostaje edytowalny i można go zaznaczyć oraz skopiować menu systemowym.
Nagłówek zmienia się na „Uproszczony tekst” albo „Poprawiony tekst”.
Dotknięcie nagłówka przywraca tekst wysłany w ostatniej udanej operacji,
bez wywołania AI i bez dodatkowego zużycia limitu.

Systemowy Wstecz działa tak samo. Otwarty nad edytorem ekran menu lub dialog
zamyka się najpierw; dopiero Wstecz w edytorze przywraca oryginał. Po przywróceniu
oryginału kolejne Wstecz działa zgodnie z nawigacją aplikacji.
Przywrócenie jest blokowane podczas ponownego wysyłania tekstu do AI.
Po kolejnej udanej operacji zapamiętany zostaje oryginał właśnie tej operacji.
Edytowanie wyniku nie usuwa możliwości przywrócenia oryginału.

Przycisk z gumką jest po prawej stronie przełącznika trybu, na tej samej wysokości,
z takim samym stylem, mniejszą ikoną o rozmiarze 28 dp i obszarem dotyku minimum 48 dp.
Opis dla TalkBack: „Wyczyść tekst”. Gumka usuwa tekst, zapamiętany oryginał
oraz błąd walidacji i zatrzymuje odczyt głosowy. Nie usuwa lokalnej historii.

Zmiana trybu oraz rozpoczęcie nagrywania lub zdjęcia również usuwają tekst
i możliwość przywrócenia poprzedniego oryginału. Po anulowaniu lub błędzie
pozyskiwania tekstu pole pozostaje puste. Rozpoznany tekst zastępuje pole i nadal
podlega walidacji, limitowi oraz informacji o przetwarzaniu przez AI.
Po błędzie AI lub anulowaniu informacji o AI rozpoznany tekst zostaje w polu.
Gumka, przełącznik trybu i pozostałe działania edycyjne są zablokowane podczas
wysyłania, OCR lub nagrywania. Przycisk mikrofonu nadal umożliwia anulowanie nagrywania.

Każda udana operacja jest zapisywana w dotychczasowej szyfrowanej historii
z jej oryginałem i wynikiem. Przywracanie i czyszczenie edytora nie zmieniają historii.
Po wylogowaniu lub usunięciu konta zapamiętany w edytorze oryginał jest usuwany
razem z tekstem i dotychczasową lokalną historią.

## Zakres

- Nowy `EditorResultViewModel` przechowuje jeden krok przywrócenia i blokadę
  podczas wysyłania, wspólny dla edytora i nagłówka aplikacji.
- `HomeScreen`, `TextInputViewModel` i `app.dart` wyświetlają wynik w edytorze,
  obsługują nagłówek/Wstecz, czyszczenie i synchronizację tekstu do kolejnej operacji.
- `EraserIcon` rysuje wektorową ikonę gumki w kolorze aktualnego przycisku.
- Usunięto nieużywany `ResultScreen`; dotychczasowe testy przepływu wyniku
  dostosowano do edytora. Historia zachowuje dotychczasową strukturę.
- `SimplificationViewModel.reset()` oddziela nowe wejście po wyczyszczeniu pola
  od ponawiania poprzedniego żądania.
- Uaktualniono testy trybów, mikrofonu i aparatu oraz dokumentację projektu.

Zmiana dotyczy aplikacji Flutter; kontrakt API i backend pozostają zgodne.
Zmiana jest zawarta w podpisanym [AAB 13](../mobile/docs/google_play_release_13.md).
AAB 12 nie zawiera tego przepływu. Odbiór na telefonie powinien objąć gest Wstecz,
TalkBack, duży tekst, anulowanie aparatu i mikrofonu oraz odczyt wyniku w trybie Popraw.

## Weryfikacja

- `dart format --output=none --set-exit-if-changed lib test`: 107 plików,
  bez wymaganych zmian.
- `flutter analyze`: bez uwag.
- Pełny `flutter test`: 220 testów przeszło.
- Po końcowej zmianie chowania klawiatury ponownie przeszło 26 testów przepływu
  wyniku, nagłówka/Wstecz, edytora, nawigacji i dostępności.
- Testy dostępności obu trybów przy skali tekstu 1 i 2,5 obejmują teraz wynik
  w edytorze oraz nowe przyciski.
- Sprawdzono kolejne wysłanie wyświetlanego wyniku do AI, zachowanie oryginałów
  w historii, czyszczenie po zmianie trybu, mikrofon i aparat po błędzie/anulowaniu,
  rozmiar i pozycję gumki, zatrzymywanie TTS oraz blokady podczas przetwarzania.
- `git diff --check`: bez błędów.

Pliki zmienione w tym zadaniu:

- `mobile/lib/app/app.dart`;
- `mobile/lib/features/home/presentation/home_screen.dart`,
  `text_input_view_model.dart` oraz nowe `editor_result_view_model.dart`, `eraser_icon.dart`;
- `mobile/lib/features/simplification/presentation/simplification_view_model.dart`
  i usunięty `result_screen.dart`;
- `mobile/test/features/home/presentation/text_mode_test.dart` oraz nowe
  `editor_result_view_model_test.dart`, `inline_editor_test.dart`;
- `mobile/test/features/photo/presentation/photo_input_widget_test.dart`,
  `mobile/test/features/speech/speech_input_widget_test.dart`,
  `mobile/test/features/simplification/presentation/result_flow_test.dart`;
- `AGENTS.md`, `README.md`, `mobile/README.md`, `docs/popraw-zadania.md` i ten dokument.

Testy używają atrap AI, mowy i aparatu. Podczas implementacji nie wykonywano
odbioru na telefonie ani budowy pakietu. Następnie przygotowano podpisany AAB 13
zgodnie z raportem wydania. Kod backendu nie wymagał zmian.
