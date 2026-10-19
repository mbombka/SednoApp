> Dokument archiwalny. Opisuje stan z czasu zadania. [Bieżąca dokumentacja](../README.md).

# Sedno — polityka prywatności, informacje o aplikacji i strona

16 października 2026 r. Właściciel potwierdził dane administratora i odbiorców 16+
oraz zlecił samodzielny wybór brakujących zasad. Zdefiniowano adresy publikacji,
uzupełniono treść i przygotowano pliki dla aplikacji, backendu oraz strony.
Nie wdrożono hostingu, nie zawarto umów w imieniu właściciela i nie ustawiono
retencji w zewnętrznych usługach. Dokument odróżnia te prace od działającego kodu.

## Wynik i decyzje

- Publiczne podsumowanie prywatności: `https://sedno.xyz/#prywatnosc`; pełna polityka w aplikacji i plikach do publikacji.
- Usuwanie konta: `https://sedno.xyz/usun-konto`.
- Pierwszy rynek: Polska; wiek 16+, z informacją o zgodzie opiekuna dla 16–17.
- Wybrany plan infrastruktury: Firebase Hosting, Google Cloud Run i Cloud SQL
  for PostgreSQL w europe-central2 (Warszawa). Nie utworzono płatnych zasobów.
- Wybrana retencja operacyjna: logi i kopie do 30 dni, korespondencja do 90 dni
  od zamknięcia, minimalna ewidencja realizacji praw do 12 miesięcy.
- Dotychczasowa retencja aplikacji pozostaje rzeczywistym opisem kodu: historia
  7 dni, metadane 8 dni, sesje kont 7 dni i gości 90 dni; konta i zakupy do usunięcia
  konta. Nie obiecano niewdrożonego automatycznego usuwania nieaktywnych kont.
- Przyjęto podstawy dla usługi, bezpieczeństwa i realizacji praw, procedurę
  weryfikacji zgłoszeń bez aplikacji oraz sposób komunikowania zmian.

Szczegóły i obowiązki wdrożeniowe są w
[przyjętym planie](../privacy-operations-plan.pl.md). Ustawienia kont dostawców,
umowy, zabezpieczenia transferów, diagnostyka SDK i operacyjna obsługa żądań
wymagają zastosowania przed produkcją. Same dokumenty nie dowodzą zgodności prawnej.

## Zmienione i dodane pliki

| Pliki | Zakres |
| --- | --- |
| `docs/privacy-policy.pl.json` | Jedno źródło treści, daty, adresów i źródeł dostawców |
| `tools/generate_privacy_policy.py` | Generowanie Markdown, Fluttera i HTML; `--check` wykrywa rozbieżności |
| `docs/privacy-policy.pl.md`, `docs/public/prywatnosc/index.html`, `docs/public/usun-konto/index.html`, `docs/public/README.pl.md` | Pełna polityka, podstrony do publikacji i instrukcja |
| `mobile/lib/features/privacy/domain/privacy_policy.dart`, `mobile/lib/app/app_information.dart` | Wygenerowana treść i wspólne adresy |
| `mobile/lib/features/privacy/presentation/privacy_screen.dart` | Pełna polityka, nagłówki semantyczne, data i kopiowanie linków |
| `mobile/lib/features/about/presentation/about_screen.dart` | Opis Sedno, odbiorcy, sposób użycia, limity, cena, ostrzeżenie AI, kontakt |
| `mobile/lib/features/shared/presentation/website_information.dart` | Dostępne kopiowanie wskazanego adresu, bez nowych zależności |
| `mobile/lib/features/account/presentation/user_menu_screen.dart` | Wejście „O aplikacji” |
| `mobile/pubspec.yaml` | Opis po polsku |
| `backend/src/Sedno.Api/PrivacyPage.cs`, `Sedno.Api.csproj`, `Program.cs` | Osadzona publiczna polityka `/prywatnosc`, bez logowania, z CSP i no-store |
| `backend/src/Sedno.Api/DeletionPage.cs`, `appsettings.Production.json` | Kontakt właściciela, strona i przyjęte zasady usuwania; brak starych pustych pól |
| `contracts/openapi.yaml`, `mobile/api/openapi.yaml` | Metadane kontaktu i kontrakt publicznej polityki |
| Testy Flutter: nowy `features/about/presentation/about_screen_test.dart`, rozszerzone testy privacy/menu/account | Nawigacja, treść, właściwe adresy schowka, długi tekst i dostępność |
| `backend/tests/Sedno.IntegrationTests/DeletionApiTests.cs` | Publiczna polityka, brak sesji, CSP, typ treści, dane właściciela i brak pustych pól |
| `backend/tests/Sedno.UnitTests/OpenAiModelTests.cs` | Dodatkowe próby podszywania pod system, nadpisania ustawień i wywołania narzędzi |
| README aplikacji i backendu, `docs/privacy-operations-plan.pl.md`, `docs/google-play-data-safety.pl.md` | Aktualne decyzje, generowanie i publikacja; odrębny stan konfiguracji |
| `docs/privacy-policy-draft.pl.md` | Dawna wersja oznaczona jako archiwum |
| `backend/tools/Sedno.ModelBenchmark/results/2026-10-16-costs.md`, README benchmarku, `docs/model-acceptance.pl.md` | Koszt według istniejących rzeczywistych pomiarów |

Nie zmieniono zaakceptowanego promptu, ustawień produkcyjnych modelu ani
historycznych raportów benchmarku. Nie dodano zapisu treści ruchu aplikacji.

## Weryfikacja

- `python3 tools/generate_privacy_policy.py --check`: wszystkie dokumenty spójne.
- `dart format lib test`: wykonano, 66 plików.
- `flutter analyze`: brak problemów.
- Pełny `flutter test`: 110 testów przeszło.
- Pełny `dotnet test backend/Sedno.Backend.sln --no-restore --nologo`: 56 testów
  jednostkowych, 38 benchmarku, 32 integracyjne — wszystkie przeszły.
- `flutter build apk --debug`: sukces;
  `mobile/build/app/outputs/flutter-apk/app-debug.apk`.
- `git diff --check`: bez błędów.

Backend testuje błędne i niepełne odpowiedzi dostawcy, odmowy, błędy HTTP,
ograniczenia długości, limity darmowe i płatne, granice UTC, idempotencję oraz
zwalnianie limitu po błędzie. Timeout dostawcy korzysta z wstrzykniętego czasu;
pozostałe warstwy mają testy anulowania i przekroczenia czasu. Nowe przypadki
potwierdzają, że złośliwy tekst pozostaje wiadomością użytkownika bez zmiany
instrukcji, modelu, zapisu i narzędzi. Nie dowodzą odporności prawdziwego modelu.

Kompilacja jest debug, bez potwierdzenia produkcyjnej konfiguracji i bez podpisu
wydawniczego. Ostrzeżenia: integracja Kotlin w Firebase, dostęp natywny Gradle/Java,
wersje metadanych Android SDK. .NET zgłosił NU1900 — brak pobrania danych audytu
podatności NuGet; wszystkie testy wykonano z dostępnymi lokalnie zależnościami.

## Koszty

OpenAI Docs posłużyło do sprawdzenia oficjalnych stawek. Analiza istniejącego
`usage` z 16.10.2026: 15 wywołań Responses default, 21 845 tokenów wejścia i 872
wyjścia. Bazowo 0,00262050 USD łącznie, średnio 0,00017470 USD. Nie wykonano nowych
płatnych wywołań. Brak rozbicia cache i opłat projektu uniemożliwia ustalenie
kwoty faktury; krótkie odpowiedzi syntetycznych próbek nie reprezentują całego
przyszłego ruchu. [Szczegółowy raport](../../backend/tools/Sedno.ModelBenchmark/results/2026-10-16-costs.md).

## Dostępność i emulator

Testy nowych ekranów obejmują 320 × 480 dp, tekst 250%, przewijanie, cele dotykowe
co najmniej 48 dp, `androidTapTargetGuideline`, `labeledTapTargetGuideline`
i `textContrastGuideline`. Polityka ma nagłówki semantyczne, SafeArea i brak
sztywnych wysokości akapitów. Testy Start, Historia, Konto i wyniku zachowano.

Kontrast podstawowych kolorów, według luminancji sRGB: granat #14243A na bieli
15,63:1, niebieski #0057B7 na bieli 6,89:1, granat na tle menu #F5F7FB 14,58:1.
Nie stanowi to potwierdzenia zgodności całej aplikacji z WCAG.

Na emulatorze Android 17 (1080 × 2400, skala 1,0) zainstalowano APK, obejrzano
nowe ekrany i odczytano UIAutomator. Wykryte angielskie „Back” zastąpiono polskim
„Wróć” na obu ekranach; etykiety potwierdzono także na Androidzie. TalkBack jest
zainstalowany, ale nie wykonano odsłuchowego audytu całej aplikacji. Nie powtarzano
fizycznych prób aparatu, logowania i zakupów. Po instalacji końcowego APK
potwierdzono także otwarcie pełnej polityki, dane administratora, polską etykietę
powrotu i możliwość przewinięcia do końcowych przycisków kopiowania obu podstron.

## Publikacja

Właściciel wskazał `https://sedno.xyz/#prywatnosc`. Odczyt przez HTTPS 16.10.2026
potwierdził działającą stronę i sekcję podsumowującą zasady dotyczące zdjęć, AI
oraz historii. Zaktualizowano źródło JSON, aplikację, wygenerowane dokumenty,
metadane OpenAPI i testy. Generator sprawdza rzeczywisty host URL i dopuszcza
fragment strony. Publiczna sekcja zawiera podsumowanie; pełne zasady pozostają
w aplikacji i przygotowanym dokumencie. Instrukcja publikacji wyjaśnia różnicę
między fragmentem strony głównej a osobną ścieżką.

Nie znaleziono na stronie linku usuwania konta. `https://sedno.xyz/usun-konto`
pozostaje wybranym adresem do publikacji. Nie zmieniano zdalnej strony ani DNS.
Poprzedni odczyt strony „w budowie” jest nieaktualny dla domeny bez www.
