# Rozszerzenie do 13 wariantów językowych

Na branchu `feature/multilingual-app` przygotowano 11 dodatkowych wariantów,
z zachowaniem polskiego i angielskiego brytyjskiego. Kod wdrożono następnie jako `sedno-api-00014-mmh`; przygotowano AAB 0.2.0 (17).
[Raport wdrożenia](backend-deployment-2026-10-23-multilingual.pl.md).
Nie publikowano aplikacji w Google Play.
Wdrożenie z 23.10.2026 i AAB 16 opisane w osobnych raportach obejmowały PL i UK.

| Język | Kod API i historii | Locale mowy | Wariant plików promptów |
|---|---|---|---|
| Polski | `pl` | `pl-PL` | `pl` |
| Angielski brytyjski | `en` | `en-GB` | `en-gb` |
| Angielski amerykański | `en-US` | `en-US` | `en-us` |
| Francuski | `fr` | `fr-FR` | `fr` |
| Niemiecki | `de` | `de-DE` | `de` |
| Włoski | `it` | `it-IT` | `it` |
| Hiszpański | `es` | `es-ES` | `es` |
| Portugalski, Portugalia | `pt` | `pt-PT` | `pt` |
| Słowacki | `sk` | `sk-SK` | `sk` |
| Czeski | `cs` | `cs-CZ` | `cs` |
| Rumuński | `ro` | `ro-RO` | `ro` |
| Norweski Bokmål | `nb` | `nb-NO` | `no` |
| Szwedzki | `sv` | `sv-SE` | `sv` |

Każdy wariant ma osobne `simplify.*.txt` i `correct.*.txt` w Infrastructure.
Istniejąca treść wszystkich promptów pozostaje bez zmian. `TextLanguages`
centralizuje walidację i mapowanie promptów backendu. Produkcyjne ustawienia
modelu, prywatność, transakcyjne limity i baza pozostają wspólne.
Starsze żądania bez języka i historia bez pola języka nadal oznaczają polski.
Dotychczasowe `en` nadal oznacza UK; API celowo wymaga podanych kodów i wielkości liter.
Nie dodano aliasów API `en-GB`, `pt-PT`, `no` czy `nn`.

## Wybór języka i tłumaczenia

Pierwszy obsługiwany język preferencji telefonu jest wybierany automatycznie.
Dopasowanie regionu rozróżnia `en-US` i `en-GB`; samo `en` oznacza UK.
Norweskie `no` i `nb` wybierają Bokmål; `nn` nie jest deklarowane jako obsługiwane.
Dla innych odmian portugalskiego interfejs wybiera dostępny wariant Portugalii.
Brak obsługiwanej preferencji oznacza polski. Menu → Język pozwala nadpisać wybór;
ustawienie zostaje zapisane lokalnie. Nazwy języków są w ich własnym języku.

Wybór obejmuje interfejs, komunikaty, wysyłany język tekstu, dyktowanie i odczyt.
Nie jest automatycznym wykrywaniem języka tekstu ani tłumaczeniem między językami.
Zmiana języka nie usuwa tekstu i nie odnawia limitów. Rozpoczęte żądanie zachowuje
swój język; ponowienie w innym języku otrzymuje nowy identyfikator.

Wszystkie 13 katalogów `mobile/lib/l10n/app_*.arb` zawiera komplet komunikatów
z tymi samymi parametrami. `flutter gen-l10n` generuje klasy Dart.
Polityki dla dodatkowych języków mają wersjonowane źródła JSON w `docs/`;
`python3 tools/generate_privacy_translations.py` tworzy dokumenty Markdown
oraz treść aplikacji. Wariant USA korzysta z angielskiej polityki.
Strona internetowa ma przygotowane lokalnie wszystkie 13 wersji, w tym instrukcje
obrazkowe, polityki i usuwanie konta. Pliki w `website/SednoWebsite/public/`
wymagają przesłania na OVH. [Generowanie i publikacja strony](../website/SednoWebsite/README.md).
Polskie adresy przywołane w istniejących tłumaczeniach polityk pozostają dostępne.
Tłumaczenia i wyniki AI wymagają odbioru przez osoby znające dany język i potrzeby
odbiorców. Przygotowanie kodu nie stanowi takiego odbioru.

## Aparat i mowa

Wszystkie dodane języki korzystają z dotychczasowego lokalnego OCR pisma łacińskiego.
Zdjęcia i dźwięk nie są wysyłane do backendu ani do AI.
Dyktafon wymaga Androida 13+, dostępnego silnika lokalnego i pobranego modelu
wybranego języka. Sprawdzenie na urządzeniu odróżnia model zainstalowany,
możliwy do pobrania, pobierany oraz język nieobsługiwany przez silnik.
Nie ma awaryjnego przełączenia na rozpoznawanie sieciowe.

Odczyt wybiera zainstalowany głos niewymagający sieci. Jawny inny region
(np. portugalski brazylijski zamiast Portugalii, UK zamiast USA) nie jest
podstawiany. Silnik może deklarować sam kod języka bez regionu; taki model lub
głos jest akceptowany. Starsze oznaczenie `no-NO` odpowiada `nb-NO`.
Nie można zagwarantować modeli każdego języka na każdym telefonie.
Brak modelu lub głosu powoduje komunikat w wybranym języku.

## Weryfikacja i kolejność wydania

Najpierw wdrożyć backend obsługujący rozszerzony kontrakt, potem aplikację.
Nie wymaga to nowych usług ani migracji Firestore. Stary backend odrzuci nowe
kody; aplikacja nie powinna przyjmować wyniku oznaczonego innym językiem.

Testy obejmują zgodność katalogów, wybór regionu i zapis języka, lokalne polityki,
format dat, oba tryby i ustawienia prywatności dla wszystkich promptów,
wspólny limit i identyfikatory żądań oraz parametry kanałów Androida.
Audyt widgetów obejmuje wszystkie języki, oba tryby i skalę tekstu 1,0 oraz 2,5.
Testy Kotlin sprawdzają dopasowanie regionów i aliasy norweskie.

Do odbioru na telefonie pozostają OCR, dostępność i jakość lokalnego dyktowania,
głosy offline, TalkBack oraz komunikaty Firebase i Google Play. Ceny i ekrany
zewnętrznych usług zależą także od konta, sklepu i konfiguracji ich dostawców.
W tym kroku nie wykonuje się wywołań produkcyjnego AI ani oceny jakości wyników.

Firebase otrzymuje `pt-PT` dla portugalskiego, `en-GB` dla UK, `en` dla USA
i `no` dla Bokmål; pozostałe języki używają kodów podstawowych. Warianty
regionalne poczty opisuje [dokumentacja Firebase](https://firebase.google.com/docs/auth/web/email-link-auth#default_email_template_for_link_sign-in).
Rzeczywiste wiadomości należy odebrać przy testach na telefonie.

## Wynik automatycznej weryfikacji — 23.10.2026

- `dart format` i `flutter analyze`: zakończone, analiza bez uwag.
- Pełne `flutter test`: 325 testów zaliczonych, w tym 52 scenariusze audytu
  dostępności dla 13 języków, dwóch trybów i dwóch skal tekstu.
- `dotnet test Sedno.Backend.sln --no-restore`: 135 jednostkowych,
  110 integracyjnych z emulatorem Firestore i 38 benchmarków, wszystkie zaliczone.
- `:app:testDebugUnitTest`: 9 testów Kotlin zaliczonych; kompilacja Androida
  zakończona poprawnie. Pozostają ostrzeżenia narzędzi o migracji pluginów Kotlin
  i istniejącym przestarzałym callbacku TTS.
- Generatory polityk z `--check`: źródła i artefakty spójne.
- Testy narzędzi Python: 20 zaliczonych.
- `git diff --check`: bez błędów; SHA-256 wszystkich 26 promptów zgodne ze stanem
  sprzed rozszerzenia.

Testy ujawniły przepełnienie okna informacji o AI przy dłuższych tłumaczeniach
w skali 250%. Okno przewija teraz tytuł wraz z treścią; po poprawce cały audyt
przechodzi. Nie podłączono telefonu; nie testowano rzeczywistych modeli mowy,
OCR każdego języka ani jakości odpowiedzi produkcyjnego modelu.
Nie wykonywano wdrożenia ani budowy nowego AAB w tym kroku.

## Wdrożenie i AAB

Po przygotowaniu kodu wdrożono `sedno-api-00014-mmh` i zbudowano AAB 0.2.0 (17).
[Raport i wyniki walidacji](backend-deployment-2026-10-23-multilingual.pl.md).
Wcześniejsze stwierdzenia o braku wdrożenia opisują etap przygotowania kodu.
