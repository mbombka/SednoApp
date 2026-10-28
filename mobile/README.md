# Aplikacja Android i iOS

23.10.2026: wdrożono **sedno-api-00014-mmh** z 13 wariantami językowymi i przygotowano
**AAB 0.2.0 (17)**. [Aktualny raport wdrożenia i pakietu](../docs/backend-deployment-2026-10-23-multilingual.pl.md).

Potrzebujesz Fluttera z Dartem zgodnym z [pubspec.yaml](pubspec.yaml), Android SDK
oraz emulatora lub telefonu. Wszystkie polecenia poniżej wykonuj w `mobile/`.

## Wersja iPhone

Kod iOS jest przygotowywany we wspólnym projekcie, bez osobnej aplikacji Flutter.
Instrukcja Xcode, podpisywania i odbioru: [ios/README.md](ios/README.md).
Skopiuj `config/ios.example.json` do ignorowanego `config/ios.local.json`
i uzupełnij identyfikatory z istniejącego projektu Firebase oraz konta Apple.
Osobno uzupełnij `ios/Flutter/Sedno.local.xcconfig` według szablonu.
Nie używaj androidowego Firebase App ID jako iOS App ID.

App Attest i zakupy wymagają skonfigurowanego backendu; nie ma automatycznego
obejścia weryfikacji na symulatorze. Apple billing jest domyślnie wyłączony.
[Próby zakupów](docs/apple_subscription_sandbox.md),
[brakujące dostępy](../missing-information.md),
[stan implementacji i testów](../docs/ios-implementation-2026-10-28.pl.md).
Nie wykonano jeszcze kompilacji ani odbioru na iPhonie.

## Uruchomienie

Lokalny plik `config/firebase.local.json` zawiera adres serwera i konfigurację
Firebase oraz Google. Jest pomijany przez Git; po nowym pobraniu projektu trzeba
go przygotować z ustawień tego samego projektu Firebase.

```sh
flutter pub get
flutter run --dart-define-from-file=config/firebase.local.json
```

Potrzebne pola: `BACKEND_BASE_URL`, `PLAY_CLOUD_PROJECT_NUMBER`,
`FIREBASE_API_KEY`, `FIREBASE_APP_ID`, `FIREBASE_PROJECT_ID`, `FIREBASE_SENDER_ID`
i `GOOGLE_WEB_CLIENT_ID`. To konfiguracja aplikacji; klucz OpenAI pozostaje na serwerze.
Flutter korzysta z `FirebaseOptions`; nie wymaga dodatkowego pluginu Google Services
ani kopiowania `google-services.json` do Androida.

Pakiet: `xyz.sedno.app`. Projekt: `sednoapp-79241`, numer `1003558402460`.
Adres serwera: `https://sednoapp-79241-api.web.app`. Google i e-mail/hasło są
włączone w Firebase. Test na telefonie wymaga również certyfikatów podpisu
w Firebase i wersji rozpoznawanej przez Play Integrity.

## Uruchomienie w Android Studio

Otwórz katalog `mobile/`. W **Run → Edit Configurations → Flutter** wybierz
`main.dart`, plik `lib/main.dart`, a w **Additional run args** ustaw:

```text
--dart-define-from-file=config/firebase.local.json
```

Ta konfiguracja korzysta z adresu API zapisanego w pliku. Po zmianie argumentów
zatrzymaj aplikację przyciskiem Stop i uruchom ponownie; hot reload ich nie wczyta.
Jeśli IDE nadal pokazuje stare argumenty, otwórz ponownie konfigurację uruchomienia.

Do emulatora z lokalnym backendem użyj osobnej konfiguracji **Sedno — backend lokalny**:

```text
--dart-define-from-file=config/firebase.local.json --dart-define=BACKEND_BASE_URL=http://10.0.2.2:5000
```

Lokalny backend musi być uruchomiony zgodnie z instrukcją poniżej. Same argumenty
nie uruchamiają serwera. Logowanie z rzeczywistym Firebase wymaga również jego
konfiguracji w lokalnym backendzie; tryb demonstracyjny modelu nie zastępuje
weryfikacji tożsamości Firebase.

Komunikat „Tutaj pojawią się opcje konta” oznacza brak konfiguracji konta
podczas uruchamiania, a nie numer ani wiek wersji aplikacji. Sam argument z adresem
backendu nie wystarcza — trzeba wczytać także konfigurację Firebase i Google.
Lokalne pliki `.idea` są pomijane przez Git; po nowym pobraniu projektu ustaw
argumenty ponownie. Pliku `firebase.local.json` również nie dodawaj do Git.

Produkcyjny backend wymaga Play Integrity. Pełna konfiguracja pokaże opcje konta
na emulatorze, ale nie gwarantuje akceptacji jego instalacji przez produkcyjne API.
Do testu całego przepływu użyj telefonu lub lokalnego backendu w Development;
nie wyłączaj zabezpieczeń produkcyjnych, aby dopuścić emulator.

## Serwer lokalny

Uruchom [backend w trybie demonstracyjnym](../backend/README.md), a następnie
skieruj emulator Androida na port 5000:

```sh
flutter run --dart-define-from-file=config/firebase.local.json \
  --dart-define=BACKEND_BASE_URL=http://10.0.2.2:5000
```

Po zmianie konfiguracji zatrzymaj aplikację i uruchom ją ponownie.
Lokalne testy gościa nie wymagają logowania Firebase. HTTP jest dopuszczone tylko
w wersji debug dla adresów lokalnych; wydanie produkcyjne wymaga HTTPS.

## Testy i plik APK

```sh
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter build apk --debug --dart-define-from-file=config/firebase.local.json
```

Plik powstaje w `build/app/outputs/flutter-apk/app-debug.apk`.
To wersja testowa. Publikacja w Google Play wymaga podpisanego wydania AAB.
[Pierwsze wydanie w testach wewnętrznych](docs/google_play_internal_test.md).

Podpis wydania jest w lokalnych `android/key.properties` i
`android/keystore/sedno-upload.jks`. Zachowaj ich zabezpieczoną kopię poza projektem.
Po pobraniu projektu odtwórz je z kopii; układ ustawień pokazuje
[key.properties.example](android/key.properties.example). Bez klucza release nie zbuduje się.

Próby na urządzeniu: [aparat i OCR](docs/android_camera_ocr_manual_check.md),
[subskrypcje](docs/google_play_subscription_sandbox.md) i
[dostępność](../docs/model-acceptance.pl.md#dostępność).

## Konfiguracja subskrypcji

Produkt Google Play: `subscription_full`, plan bazowy: `monthly`, miesiąc,
9,99 PLN w Polsce i 400 uproszczeń dziennie łącznie. Identyfikatory są domyślnie
zapisane w [PlaySubscriptionConfiguration](lib/features/subscription/domain/play_subscription_configuration.dart).
Cena w interfejsie pochodzi z Google Play. Aplikacja wybiera zwykły miesięczny
plan z automatycznym odnawianiem, bez promocji.

Panel zakupów jest domyślnie wyłączony (`PLAY_BILLING_ENABLED=false`). Do prób
na istniejącym `https://sednoapp-79241-api.web.app` dodaj
`--dart-define=PLAY_BILLING_ENABLED=true` lub użyj lokalnego pliku
`config/billing.local.json`. Serwer `sedno-api` ma już włączoną obsługę płatności.
Identyfikatory można nadpisać przez `PLAY_SUBSCRIPTION_PRODUCT_ID` i
`PLAY_SUBSCRIPTION_BASE_PLAN_ID` w argumentach budowy. Samo włączenie panelu
nie uruchamia płatności na serwerze. [Pełne przygotowanie i testy](docs/google_play_subscription_sandbox.md).

Gotowy podpisany pakiet do testów: [wydanie 16](docs/google_play_release_16.md).

Aparat działa wewnątrz Sedna: **Zrób zdjęcie → Zaznacz tekst → Uprość**.
Ramka początkowo obejmuje całe zdjęcie. Można przesunąć jej rogi, aby wybrać
fragment. Odczytany tekst trafia do pola i od razu do uproszczenia. Po błędzie
albo przy zbyt długim tekście zostaje w polu do ręcznej poprawy. Zdjęcie pozostaje nieruchome; nie ma dodatkowego zatwierdzania zdjęcia
ani wyboru proporcji. Zdjęcia i wycinanie fragmentów pozostają na urządzeniu.

Kod jest w `lib/app/` i `lib/features/`; testy mają odpowiadający układ w `test/`.
Aktualny opis komunikacji z serwerem: [kontrakt API](../contracts/openapi.yaml).

## Nawigacja i wynik

Przycisk „Menu użytkownika” w górnym pasku otwiera Start, Historię, Konto,
O aplikacji oraz Prywatność i dane. Start działa bez logowania.
Odnośnik do prywatności jest dostępny w menu użytkownika oraz w informacji
przed pierwszym wysłaniem tekstu. Ekrany konta, logowania i rejestracji
nie powtarzają tego odnośnika.

Akceptacja informacji „Zanim uprościsz tekst” / „Zanim poprawisz tekst” jest
zapisywana lokalnie dla instalacji, wspólnie dla obu trybów. Po akceptacji monit
nie wraca przy kolejnych uruchomieniach ani po wylogowaniu. Anulowanie nie zapisuje
akceptacji. Usunięcie danych aplikacji lub ponowna instalacja przywraca monit.
Jeżeli zapis ustawienia się nie powiedzie, akceptacja działa w bieżącym
uruchomieniu, a po kolejnym uruchomieniu aplikacja zapyta ponownie.

Wynik zastępuje tekst w tym samym edytorze. Nagłówek „Uproszczony tekst” lub
„Poprawiony tekst” jest przyciskiem przywracającym oryginał ostatniej operacji.
Tak samo działa systemowy Wstecz; dopiero kolejne Wstecz może opuścić Start.
Tekst można edytować, zaznaczać i kopiować przez menu systemowe.
Gumka po prawej stronie przełącznika trybu czyści pole oraz zapamiętany oryginał.
Zmiana trybu i rozpoczęcie nagrywania lub zdjęcia również je usuwają.
Anulowanie lub błąd nagrywania/zdjęcia pozostawia puste pole; błąd wysyłania
rozpoznanego tekstu do AI zachowuje go do ręcznej edycji.
Historia nadal zapisuje oryginał i wynik niezależnie od przywracania i czyszczenia.
W Historii przycisk „Usuń całą historię teraz” z koszem usuwa wszystkie lokalne
wpisy po potwierdzeniu. Podczas usuwania jest zablokowany; po błędzie można ponowić
próbę. Przy pustej historii przycisk jest nieaktywny.
[Zmiana przepływu edytora](../docs/edytor-wynik.pl.md).

Aplikacja jest przeznaczona dla osób od 13 lat. Osoby w wieku 13–17 lat
powinny korzystać z niej za zgodą rodzica lub opiekuna.

## Ikona i ekran uruchamiania

Źródło logo: [sedno-icon.svg](../docs/Content/sedno-icon.svg).
Wariant PNG: [sedno-icon-A-512.png](../docs/Content/sedno-icon-A-512.png).
Zasoby Androida odtwarza `python3 tools/generate_android_icons.py` z katalogu
głównego projektu (wymaga Pillow).
Znak jest zapisany jako ścieżki, bez zależności od czcionek.
Zasoby w `android/app/src/main/res/` zawierają ikony PNG dla starszych Androidów,
ikonę adaptacyjną od Androida 8 oraz wariant jednokolorowy od Androida 13.
Kolor ikon tematycznych wybiera system. Ekran uruchamiania pokazuje biały znak
na niebieskim kole i jasnym tle, również w trybie ciemnym.

Po zmianie logo sprawdź na telefonie ikonę w menu i na ekranie głównym,
maskę okrągłą i zaokrągloną oraz ikony tematyczne, jeżeli program uruchamiający
je obsługuje. Sprawdź też ekran startowy po pełnym zamknięciu aplikacji,
w jasnym i ciemnym trybie systemu, na Androidzie 12+ i starszym.
Zmiana ikony wymaga nowej instalacji lub aktualizacji aplikacji;
przeładowanie kodu Fluttera jej nie zmienia.

## Potwierdzanie adresu e-mail

[Raport wdrożenia backendu i budowy APK — 19.10.2026](../docs/archiwum/email-verification-2026-10-19.pl.md).

Po rejestracji aplikacja wysyła przez Firebase wiadomość w wybranym języku.
Konto czeka na potwierdzenie adresu. W tym czasie uproszczenia nadal działają
w trybie gościa, z dotychczasowym limitem instalacji.

Na ekranie Konto pojawia się instrukcja:

> Aby dokończyć tworzenie konta, kliknij link w wiadomości od Sedna.
> Sprawdź też folder Spam. Potem wróć tutaj i wybierz „Sprawdź potwierdzenie”.

Aplikacja sprawdza potwierdzenie również po wznowieniu. Przed połączeniem konta
odświeża użytkownika i token Firebase. Wiadomość można wysłać ponownie;
przycisk ma 60-sekundową przerwę, a Firebase dodatkowo ogranicza częste próby.
Błąd wysyłania nie powoduje ponownego tworzenia konta. Istniejące niepotwierdzone
konto po zalogowaniu również otwiera ten ekran. Wylogowanie usuwa lokalną historię.

Próba na telefonie wymaga nowej wersji aplikacji i backendu z obsługą
`email_not_verified`. Zarejestruj nowy adres, sprawdź wiadomość (także Spam),
kliknij link i wróć do Sedna. Sprawdź brak dostępu do konta przed potwierdzeniem,
ponowne wysłanie, wylogowanie i powrót do oczekującego konta oraz zachowanie limitu.
Dostarczania prawdziwej poczty nie zastępują testy z atrapami.

## Logowanie, nowe konto i odzyskiwanie hasła

Ekran Konto domyślnie pokazuje logowanie Google lub e-mail/hasło. Link
„Nie masz konta? Utwórz konto” otwiera osobny formularz rejestracji. Hasło trzeba
wpisać dwukrotnie; aplikacja sprawdza zgodność przed utworzeniem konta. Każde
pole hasła ma opisany przycisk podglądu, niezależny od drugiego pola.
Przełączenie formularza czyści hasła i ponownie je ukrywa.

„Nie pamiętam hasła” prowadzi do formularza wysłania linku przez Firebase.
Wiadomość używa języka przekazanego do Firebase (dostarczenie i szablony wymagają odbioru). Komunikat po wysłaniu jest taki sam dla istniejącego
i nieistniejącego konta. Prawdziwe dostarczenie poczty wymaga testu na telefonie.

## Upraszczanie mowy

Przycisk mikrofonu po lewej stronie „Uprość” uruchamia lokalne rozpoznawanie
mowy w wybranym języku. Wymaga Androida 13 lub nowszego, lokalnego silnika i pobranego
modelu wybranego języka. Audio nie jest zapisywane ani wysyłane na serwer.
Po 1,5 s ciszy po wykryciu mowy lub po maksymalnie 60 s rejestracji aplikacja
kończy nagrywanie i automatycznie przekazuje tekst do upraszczania, jak przy OCR.
Przycisk stop anuluje sesję. Rozpoczęcie nagrywania czyści dotychczasowy tekst.
Rozpoznana wypowiedź zastępuje zawartość pola; po anulowaniu nagrywania pole jest puste.

[Zadania i stan weryfikacji](docs/speech_tasks.md).
[Wymagania techniczne i próby na telefonie](docs/android_speech_manual_check.md).

## Tryby „Uprość” i „Popraw”

Strzałki nad głównym przyciskiem zmieniają tryb i usuwają tekst z edytora.
„Uprość” zachowuje aparat, OCR i mikrofon. „Popraw” usuwa błędy językowe,
zachowując sens wypowiedzi; korzysta z osobnego promptu na backendzie.
W tym trybie aparat znika, a głośniczek odczytuje bieżący tekst z pola.
Przycisk stop zatrzymuje odczyt. Zmiana trybu, otwarcie menu lub przejście
aplikacji do tła również zatrzymuje odczyt. Potrzebny jest zainstalowany lokalny
głos wybranego języka do odczytu bez internetu; aplikacja nie wybiera głosów wymagających sieci.
Wynik i zaszyfrowana historia rozróżniają tekst uproszczony i poprawiony.
Starsze wpisy historii są traktowane jako uproszczenia.

Oba tryby mają wspólne limity 5/400 użyć dziennie. Najpierw trzeba wdrożyć
backend obsługujący `mode=correct`, a potem aplikację. Aplikacja sprawdza tryb
zwrócony przez API, aby nie wyświetlić uproszczenia ze starego serwera jako korekty.
[Zadania i próby na telefonie](../docs/popraw-zadania.md).

## Dostęp testerski

Aplikacja obsługuje `tier=tester` i opcjonalną datę `testerAccessExpiresAt`
z odpowiedzi limitu. Konto pokazuje datę ważności i informację o bezpłatnym dostępie.
[Przyznawanie dostępu i kolejność wdrożenia](../docs/tester-access.pl.md).

## Wersje językowe

Kod aplikacji obsługuje [13 wariantów językowych](../docs/multilingual-13-languages.pl.md),
w tym portugalski z Portugalii i norweski Bokmål. Menu → Język pozwala wybrać język
lub używać preferencji telefonu. Ten sam wybór obejmuje tekst i funkcje mowy.
[Architektura, źródła tłumaczeń, prompty i dodawanie języków](../docs/multilingual-app.pl.md).
Backend z obsługą `language` musi zostać wdrożony przed nową aplikacją.
