# Prywatność wersji iPhone — projekt do odbioru

Stan: 28.10.2026. To robocza lista kontroli dla wersji iOS. Nie potwierdza
zgodności prawnej ani gotowości deklaracji App Privacy. Nie opublikowano zmian
na stronie sedno.xyz ani w App Store Connect.

W aplikacji sekcja „Prywatność i dane” wyświetla na iPhonie lokalizowany dodatek
przed wspólną polityką. Dodatek rozróżnia Androida i iOS, opisuje Apple jako
dostawcę logowania, płatności i App Attest oraz podaje retencję nowych metadanych.
Dane administratora, cele, podstawy przetwarzania i opis OpenAI pozostają we
wspólnej polityce. Przed publikacją trzeba spójnie zaktualizować jej wersję,
publiczną stronę i deklarację sklepu po akceptacji rzeczywistego działania.

## Dane i przepływy do potwierdzenia

| Obszar | Implementacja / zakres odbioru |
| --- | --- |
| Konto | Firebase Authentication, opcjonalne Google/e-mail/Apple. Przy Apple możliwy adres przekazujący zamiast rzeczywistego e-maila. Sprawdzić konfigurację Firebase i prywatnego przekazywania poczty. |
| AI | Tekst przez Sedno do OpenAI, brak zapisu treści i wyników w bazie Sedno. Oddzielnie sprawdzić rzeczywiste zasady retencji OpenAI i infrastrukturę logowania; `store=false` nie oznacza braku wszelkiej retencji u dostawcy. |
| Zdjęcia/OCR | Przetwarzanie na urządzeniu. Potwierdzić na urządzeniu, że zdjęcie i treść OCR nie są przesyłane przez SDK; sprawdzić osobno telemetrię ML Kit. |
| Mowa | Rozpoznawanie wymaga obsługi lokalnej dla urządzenia i języka; brak cichego przejścia do chmury. Odczyt lokalny, bez wysyłania treści. Sprawdzić odmowę uprawnień, brak głosu/modelu i działanie offline. |
| Historia | Szyfrowana, lokalna, wyłączona z kopii zapasowej. Wygasanie po 7 dniach, kasowanie przy odczycie, starcie i wznowieniu; wylogowanie i usunięcie konta czyszczą historię. Potwierdzić atrybuty pliku i Keychain na iPhonie. |
| App Attest | Apple potwierdza klucz aplikacji, bez przesyłania tekstu, wyniku czy zdjęcia. Firestore przechowuje HMAC instalacji, identyfikator/publiczny klucz, licznik i daty; dowód atestacji nie jest przechowywany, tylko jego skrót do bezpiecznego ponowienia rejestracji. |
| Wyzwania | Ważne 5 minut; natychmiast odrzucane po wygaśnięciu. Fizyczne usunięcie przez zadanie sprzątające, zwykle do następnego godzinowego uruchomienia. |
| Klucze App Attest | Wygasają po 90 dniach od ostatniej udanej weryfikacji sesji. Każda udana asercja odświeża termin. Wygasłe rekordy usuwa zadanie; usunięcie konta usuwa klucze jego instalacji. |
| Zakupy Apple | Identyfikatory transakcji, powiązanie konta i stan uprawnienia, bez danych karty. Obecnie przechowywane do usunięcia konta; brak osobnego automatycznego terminu dla samych zakupów. To wymaga zatwierdzenia retencji przed publikacją. |
| Powiadomienia Apple | Skróty identyfikatorów zdarzeń do deduplikacji, powiązanie konta i czas przetworzenia. Zadanie usuwa starsze niż 30 dni; usunięcie konta usuwa je wcześniej. |
| Infrastruktura | Sprawdzić logi Cloud Run/Hosting, adresy IP, ustawienia Google i umowy dostawców. Europejski region Firestore nie oznacza, że wszystkie dane są przetwarzane wyłącznie w EOG. |

## App Privacy — deklaracja jeszcze niezatwierdzona

Apple wymaga uwzględnienia dostawców i osadzonych SDK. Definicję „zbierania”
trzeba ocenić także u nich; brak treści w bazie Sedno nie wystarcza do odpowiedzi
„nie zbieramy danych”. [App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/).

- [ ] Sporządzić inwentaryzację faktycznie dołączonych wersji SDK z `Podfile.lock`, pakietu Release i raportu prywatności Xcode. Przejrzeć manifesty `PrivacyInfo.xcprivacy`, wymagane powody użycia API i podpisy wymaganych SDK.
- [ ] Potwierdzić zakres telemetrii Firebase Core/Auth, Google Sign-In, ML Kit, Fluttera i pozostałych zależności iOS; nie przenosić bez weryfikacji deklaracji Androida.
- [ ] Oceniać osobno identyfikator konta/instalacji, e-mail, zakupy, dane diagnostyczne oraz treść użytkownika przetwarzaną przez AI. Dla każdej kategorii udokumentować odbiorcę, cel, powiązanie z użytkownikiem i retencję.
- [ ] Zweryfikować brak reklam, analityki, IDFA i śledzenia również w SDK. Nie deklarować „brak śledzenia” wyłącznie na podstawie kodu aplikacji. Nie dodawać ATT bez rzeczywistej potrzeby.
- [ ] Wypełnić App Privacy po audycie rzeczywistej kompilacji. Zachować roboczą tabelę uzasadnień i datę odbioru, następnie porównać z polityką w aplikacji oraz publicznym URL.

## Zgoda na AI i usuwanie konta

- [ ] Przed pierwszym wysłaniem wskazać OpenAI, zakres przekazywanych danych i cel. Wymagać świadomej akceptacji; odmowa lub zamknięcie komunikatu nie wysyła tekstu. Powtórzyć test dla zdjęcia i dyktowania. Jest to również odbiór przepływu wymaganego przez pkt 5.1.2(i), a nie twierdzenie o podstawie prawnej RODO. [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/#data-use-and-sharing).
- [ ] Udostępnić usunięcie konta w aplikacji także dla Apple. Po ponownym uwierzytelnieniu usuwać Firebase, dane Sedno i lokalne dane oraz odwoływać powiązane tokeny Apple. Nie uznawać samego e-maila do właściciela za kompletne rozwiązanie iOS. [Apple: account deletion](https://developer.apple.com/support/offering-account-deletion-in-your-app/).
- [ ] Odebrać odwołanie dostępu Apple na prawdziwym koncie; ustalić obsługę braku aktualnego kodu autoryzacyjnego, przerwania i ponowienia. Dezaktywacja konta nie zastępuje usunięcia. [Apple TN3194](https://developer.apple.com/documentation/technotes/tn3194-handling-account-deletions-and-revoking-tokens-for-sign-in-with-apple).
- [ ] Wyjaśnić, że usunięcie konta nie anuluje subskrypcji Apple, i zapewnić drogę do zarządzania subskrypcją. Odebrać zakup, przywrócenie, odnowienie, zwrot, wygaśnięcie i usuwanie konta z aktywną subskrypcją.
- [ ] Potwierdzić usunięcie nowych kolekcji Apple, brak dostępu starymi sesjami, zachowanie wspólnych limitów i bezpieczne ponowne uruchomienie.

## Dokumenty i odbiór przed publikacją

- [ ] Potwierdzić dane administratora, listę odbiorców, podstawy, transfery, retencję i warunki powierzenia wraz z właścicielem. Osobno potwierdzić warunki Apple/Firebase i ukryty e-mail. [Apple: Sign in with Apple & Privacy](https://www.apple.com/legal/privacy/data/en/sign-in-with-apple/).
- [ ] Przejrzeć 13 wersji językowych, VoiceOver, skalowanie tekstu i działanie linku polityki Apple.
- [ ] Zaktualizować publiczną politykę i wersję dokumentu dopiero po potwierdzeniu powyższych przepływów; ten task nie publikuje strony.
- [ ] Dołączyć wynik audytu SDK, fizycznych testów i podpisanej kompilacji/TestFlight. Nie utożsamiać przejścia testów jednostkowych z odbiorem prywatności.

Powiązane: [protokół App Attest](../backend/docs/apple-app-attest.md),
[plan iPhone](../IphoneVersion.md), [operacje prywatności](privacy-operations-plan.pl.md).
