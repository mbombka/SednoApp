# Google Play — formularz bezpieczeństwa danych

Materiał do przygotowania formularza, nie potwierdzenie jego wysłania.
Pakiet: **`xyz.sedno.app`**, projekt Firebase: `sednoapp-79241`.
Serwer działa od 19.10.2026; płatności są wyłączone. Odpowiedzi dopasuj do
faktycznie publikowanego wydania, zależności SDK i ustawień dostawców.

## Podstawowe odpowiedzi

| Pole | Informacja do formularza |
| --- | --- |
| Zbieranie danych | Tak: tekst do uproszczenia, identyfikatory i dane techniczne; opcjonalnie dane konta i zakupów |
| Szyfrowanie w przesyłaniu | Produkcja wymaga HTTPS; sprawdź całe wydanie i infrastrukturę |
| Tworzenie konta | Google lub e-mail i hasło; można zacząć jako gość |
| Usuwanie konta | Konto → Usuń konto; także zgłoszenie przez stronę |
| Polityka | https://sedno.xyz/prywatnosc/ — sprawdź zgodność aktualnej treści |
| Usuwanie bez aplikacji | https://sedno.xyz/usun-konto/ — kontakt e-mail z weryfikacją właściciela |
| Reklamy | Brak integracji reklamowej w kodzie |
| Niezależny audyt / certyfikacja | Brak potwierdzenia; testy nie są certyfikacją |

## Kategorie danych do sprawdzenia

| Dane | Kiedy i po co |
| --- | --- |
| Adres e-mail i identyfikator konta | Dobrowolne logowanie; prowadzenie konta |
| Identyfikatory instalacji i sesji | Wymagane do żądań serwera; limity i ochrona przed nadużyciami |
| Daty, statusy i liczniki żądań | Działanie usługi i bezpieczeństwo |
| Tekst użytkownika | Wysyłany przez backend do OpenAI do uproszczenia |
| Historia zakupów | Po włączeniu płatności: weryfikacja subskrypcji i powiązanie z kontem |
| Diagnostyka i metryki SDK | ML Kit i inne użyte usługi; sprawdź wersje i ruch sieciowy |
| Nazwa i zdjęcie profilu Google | Sprawdź na koncie testowym, co otrzymuje Firebase; sam backend nie zapisuje nazwy |

Kategoria obejmująca wymagany identyfikator instalacji nie staje się w całości
opcjonalna przez to, że logowanie jest dobrowolne. Dopasuj nazwy kategorii do formularza Play.

Zdjęcia OCR i lokalna historia nie są wysyłane. Sedno nie pobiera numerów kart,
kontaktów, SMS ani lokalizacji. Sprawdź osobno zachowanie dostawców SDK.
Dowolny tekst użytkownika może zawierać dane wrażliwe mimo braku takich formularzy.

## Dostawcy i przechowywanie

- **OpenAI:** otrzymuje tekst. Backend go nie zapisuje; `store=false` nie oznacza,
  że dostawca przetwarza go wyłącznie w pamięci. Nie deklaruj zerowej retencji.
- **Firebase Authentication / Google Sign-In:** konto, IP i techniczne dane logowania.
- **Play Integrity:** kontrola aplikacji i urządzenia, bez tekstów i zdjęć.
- **ML Kit:** rozpoznaje tekst lokalnie, ale może wysyłać diagnostykę i metryki.
- **Google Cloud:** Hosting, Cloud Run i PostgreSQL w Warszawie; region bazy
  nie gwarantuje przetwarzania wszystkich danych wyłącznie w UE.
- **Google Play:** dane płatności i subskrypcji po włączeniu zakupów.

„Zbieranie” obejmuje także dane przetwarzane poza telefonem tylko chwilowo.
„Udostępnianie” ma odrębną definicję Play; sprawdź role usługodawców i wyjątki.
Metadane, sesje i zakupy są zapisywane, więc nie są przetwarzane tylko w pamięci.
Brak Firebase Analytics nie oznacza braku diagnostyki innych SDK.

Przed wysłaniem formularza sprawdź certyfikaty podpisu, kraj i grupę 16+,
ruch wersji release, dostępność obu stron, pełne usuwanie konta, konfigurację
logów oraz zgodność z [polityką](privacy-policy.pl.md) i
[procedurami przechowywania](privacy-operations-plan.pl.md).
Usunięcie konta nie anuluje subskrypcji.

Źródła do sprawdzenia przy wypełnianiu:
[definicje Play](https://support.google.com/googleplay/android-developer/answer/10787469?hl=pl),
[ML Kit](https://developers.google.com/ml-kit/android-data-disclosure),
[Firebase](https://firebase.google.com/docs/android/play-data-disclosure#authentication),
[Play Integrity](https://developer.android.com/google/play/integrity/terms#data-safety),
[OpenAI](https://developers.openai.com/api/docs/guides/your-data).
