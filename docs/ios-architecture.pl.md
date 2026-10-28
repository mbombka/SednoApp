# Wspólny Android/iOS — decyzje implementacyjne

28.10.2026, branch `iPhoneVersion`. Właścicielem integracji wspólnych plików
jest agent główny; natywne iOS, atestacja i billing mają osobne zakresy.

## Granice platform

Flutter zachowuje feature-first i bieżące ViewModele/repozytoria. Składanie
zależności w `mobile/lib/main.dart` wybiera iOS lub Android; interfejsy historii,
mowy i sklepu pozostają wspólne. Nowe komunikaty są w ARB, z polskim fallbackiem.
Wymagane minimum natywne: iOS 15.5 z powodu bieżącego pakietu ML Kit.
Aktualność wszystkich zależności należy potwierdzić przez CocoaPods na Macu.

Android zachowuje Kotlin, Play Integrity, Keystore, Play Billing i RTDN.
iOS dodaje Swift: CryptoKit/Keychain, Apple Speech, AVSpeechSynthesizer
i DeviceCheck/App Attest. Aparat, kadrowanie i ML Kit wykorzystują obecne pakiety.
Nazwa klasy aparatu zawierająca Android nie oznacza zależności od Android API:
jej implementacja używa wieloplatformowego pakietu `camera`.

## Sesje i zgodność API

`/v1/guest-sessions` pozostaje zgodne z obecnym Androidem. iOS ma osobne
endpointy wyzwania, rejestracji klucza i sesji, z serwerowym sprawdzeniem
kryptograficznym. Nie ma wyboru mniej restrykcyjnej ścieżki przez samo pole
platformy. Protokół i stan opisuje `backend/docs/apple-app-attest.md`.
Weryfikacja prowadzi do tego samego `IGuestStore`, a konto ma wspólne rezerwacje
limitu. Sesja jest tworzona raz także przy równoczesnych żądaniach klienta.

Powiązanie instalacji i konta pozostaje transakcyjne. Zmiana klucza atestacji
nie zmienia identyfikatora instalacji. Nie identyfikujemy jednej osoby na dwóch
urządzeniach bez zalogowania. Pole dostawcy konta dopuszcza nowe `apple`;
stare wartości pozostają zgodne. Stary klient Androida nie obsłuży nowego typu
konta, jeżeli to samo konto Firebase ostatnio logowano przez Apple — przed
publicznym iOS należy udostępnić aktualny Android obsługujący tę wartość.

## Subskrypcje

Istniejący Google adapter pozostaje; Apple ma osobny adapter i konfigurację,
ale wspólny `IEntitlementResolver`. Aktywne uprawnienie z dowolnego sklepu
daje limit 400 łącznie, a nie 800. Tier testerski pozostaje niezależny.
Odczyt subskrypcji podaje jej sklep, aby UI wskazywał zarządzanie we właściwym
miejscu i nie proponował drugiego zakupu. Dowody zakupów Google i Apple mają
osobne endpointy; stary kontrakt `purchaseToken` pozostaje bez zmian.

Apple appAccountToken jest deterministycznym UUID konta. To nie identyfikator
instalacji, e-mail ani UID Firebase. Zakup jest przypisywany do jednego konta
w transakcji; przypisania nie przenosimy po samym dopasowaniu adresu e-mail.
Łączenie Apple z istniejącym Google/e-mailem oraz Google z kontem Apple jest
jawne i wymaga ponownego uwierzytelnienia oraz zachowania tego samego UID
Firebase. Użytkownik zaczynający na iPhonie może połączyć Google, a następnie
zalogować się nim na Androidzie. Nie scalamy dwóch odrębnych UID po e-mailu;
konflikt metody pozostawia dotychczasowe konto. Odbiór rzeczywistych dostawców,
ukrytego adresu Apple i usuwania kont powiązanych wymaga ich konfiguracji.


## Stan danych i migracja

Nowe kolekcje są w istniejącym Firestore `(default)` i dostępne wyłącznie przez
IAM backendu. Stare dokumenty pozostają czytelne bez destrukcyjnej migracji.
App Attest dodaje wyzwania, klucze, licznik i daty, zakupy Apple dodają stan
subskrypcji i deduplikację powiadomień. Usuwanie konta obejmuje nowe kolekcje;
istniejący cleanup usuwa przeterminowaną atestację i powiadomienia.
Zasady retencji i wymagane indeksy porównać z rzeczywistymi zapytaniami przed rolloutem.

Historia i zdjęcia nie są migrowane przez serwer. Historia pozostaje lokalna,
szyfrowana i wyłączona z backupów; 7-dniowa retencja jest wspólną logiką Dart.
Audio nie trafia do serwera: brak lokalnego rozpoznawania wyłącza dyktowanie.
Obsługę wszystkich 13 języków trzeba sprawdzić na urządzeniach, bez deklarowania
niepotwierdzonej dostępności modeli i głosów.

## Wdrożenie i ograniczenia

Konfiguracja Apple jest domyślnie wyłączona. Brak dowodu atestacji nie jest
powodem do przyznania dostępu ani uruchomienia atrapy produkcyjnej.
Najpierw zgodny backend i aktualny Android, potem skonfigurowany build iOS,
TestFlight i odbiór. Zachować obecne klucze, service account, bazę i ustawienia
OpenAI; prompty i parametry modelu nie są częścią migracji.

Brakujące dostępy opisuje `missing-information.md`. Stan kodu, kompilacja iOS,
test urządzenia i publikacja są osobnymi etapami. Linux pozwala sprawdzić Dart
i .NET, ale nie potwierdza poprawności kompilacji Swift/Xcode.
