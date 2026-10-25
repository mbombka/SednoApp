# Sedno na iPhone — zadania dla agentów

Plan z 25.10.2026. Dokument opisuje przyszłe prace; żadne z poniższych zadań
nie jest wykonane przez samo przygotowanie tej listy.

## Uzgodniony kierunek

- Rozszerzamy istniejącą aplikację Flutter/Dart o iOS. Zachowujemy wspólny kod,
  `lib/app`, `lib/features`, odpowiadające testy oraz mechanizm lokalizacji.
- Jeden backend `sedno-api`, istniejące konto usługi, projekt Firebase
  `sednoapp-79241` i Firestore `(default)`. Bez drugiego backendu lub bazy.
- Android nadal używa Play Integrity; iPhone otrzymuje Apple App Attest.
  Obie ścieżki działają równolegle i prowadzą do wspólnej obsługi sesji i limitów.
- Firebase Authentication pozostaje wspólne. Dodajemy logowanie Apple obok
  Google i e-maila. Zakupy Apple i Google Play przyznają ten sam poziom dostępu.
- Pełny zakres obejmuje aparat/OCR, historię, lokalne dyktowanie i odczyt,
  konto, subskrypcję, dostępność oraz wszystkie 13 wariantów językowych.
- Wewnętrzna wersja w TestFlight może poprzedzać płatności i mowę. Niedostępnych
  funkcji nie reklamujemy w interfejsie; ten etap nie oznacza zakończenia migracji.

## Zasady realizacji i przekazywania pracy

Każdy agent przed pracą czyta `AGENTS.md`, główny `README.md`,
`mobile/README.md`, `backend/README.md`, `mobile/pubspec.yaml` oraz aktualny kod
swojego obszaru. Stan dokumentów wdrożeniowych należy porównać z kodem;
historyczna notatka nie potwierdza aktualnego stanu produkcji.

Każde zadanie przekazuje: zmienione pliki, opis kontraktów i konfiguracji,
wyniki faktycznie uruchomionych kontroli, ograniczenia środowiska oraz pozostałe
próby na urządzeniach. Statusy: `TODO`, `W TOKU`, `GOTOWE LOKALNIE`,
`ODEBRANE NA URZĄDZENIU`. Checkbox zamykamy dopiero po spełnieniu kryteriów
odbioru; brak Maca, iPhone'a lub konta Apple zapisujemy jako brak odbioru.

Nie regenerować całego projektu. Nie zmieniać promptów, modelu ani produkcyjnych
parametrów AI w ramach migracji. Nie zapisywać tekstów, wyników, zdjęć, audio,
tokenów ani kluczy w logach lub raportach. Atrapy i emulator wyłącznie
w jawnej konfiguracji Development. Zachować istniejące zachowania Androida.

Poniższe zadania są do przydzielenia agentom; przygotowanie tego dokumentu
nie uruchamia implementacji, konfiguracji kont ani wdrożeń.

## Kolejność i odpowiedzialność

| ID | Agent / zakres | Zależności |
| --- | --- | --- |
| IOS-01 | Architektura, kontrakty i zgodność | brak |
| IOS-02 | Projekt iOS, konfiguracja i narzędzia | IOS-01 |
| IOS-03 | Backend App Attest | IOS-01 |
| IOS-04 | Klient App Attest i sesje iOS | IOS-02, IOS-03 |
| IOS-05 | Szyfrowana historia i dane lokalne | IOS-01, IOS-02 |
| IOS-06 | Aparat, kadrowanie i OCR | IOS-02 |
| IOS-07 | Logowanie Apple, Google i e-mail | IOS-01, IOS-02; odbiór po IOS-04 |
| IOS-08 | Lokalne dyktowanie i odczyt tekstu | IOS-01, IOS-02 |
| IOS-09 | Backend subskrypcji Apple | IOS-01; odbiór po IOS-07 |
| IOS-10 | Zakupy Apple w aplikacji | IOS-02, IOS-09; odbiór po IOS-07 |
| IOS-11 | Interfejs, lokalizacja i dostępność | IOS-02; odbiór po IOS-04–10 |
| IOS-12 | Prywatność i materiały App Store | IOS-01; odbiór po IOS-03–11 |
| IOS-13 | Integracja, testy i regresja Androida | IOS-03–12 |
| IOS-14 | TestFlight, wdrożenie i publikacja | IOS-13 |

Po IOS-01 można równolegle przygotowywać backend i projekt iOS. Po IOS-02
można rozdzielić historię, aparat, konto i mowę między agentów.
Wspólne pliki (`main.dart`, `app.dart`, `Program.cs`, OpenAPI, modele konta
i zakupów) mają jednego właściciela integracji wskazanego w IOS-01.
Pozostali agenci uzgadniają zmiany tych plików przed edycją.

## Zadania

### IOS-01 — architektura i kontrakty

- [ ] Zinwentaryzować kanały platformowe i bezpośrednie zależności od Androida,
  w tym `main.dart`, `app.dart`, historię, sesje, mowę i sklep.
- [ ] Ustalić wybór implementacji przez dependency injection; zachować istniejące
  interfejsy, rozszerzając je tylko tam, gdzie wymaga tego protokół Apple.
- [ ] Zaprojektować zgodne wstecznie rozszerzenia `contracts/openapi.yaml`
  dla App Attest, logowania Apple i zakupów. Stara aplikacja Android nadal działa.
- [ ] Opisać model danych: platforma instalacji, klucz atestacji, wyzwania,
  licznik podpisów, dostawca tożsamości, sklep i identyfikatory zakupu.
  Określić retencję, usuwanie, indeksy i odczyt starszych dokumentów.
- [ ] Ustalić zasadę: konto ma wspólny limit 5/400 dla obu platform i trybów,
  reset o 00:00 UTC; zakupy z obu sklepów nie sumują limitu powyżej 400.
  Goście na różnych urządzeniach pozostają osobnymi instalacjami.
- [ ] Ustalić minimalny iOS po sprawdzeniu wszystkich aktualnych zależności,
  zakres urządzeń oraz macierz obsługi mowy dla 13 wariantów językowych.
- **Odbiór:** zapisane kontrakty, kolejność migracji i właściciele wspólnych
  plików; wskazane decyzje wymagające danych właściciela, bez zgadywania ID Apple.
- **Punkty wejścia:** `mobile/lib/main.dart`, `mobile/lib/app/app.dart`,
  `backend/src/Sedno.Application/Contracts.cs`, `BillingContracts.cs`, OpenAPI.

### IOS-02 — projekt iOS i konfiguracja

- [ ] Dodać wyłącznie brakującą platformę iOS do istniejącego projektu Flutter.
  Skontrolować diff, aby nie nadpisać Androida ani źródeł aplikacji.
- [ ] Przygotować Xcode, zależności natywne, deployment target, identyfikator
  aplikacji, nazwę Sedno, ikony, ekran uruchamiania i podpisywanie.
- [ ] Dodać konfigurację Firebase właściwą dla iOS w tym samym projekcie,
  OAuth i powrót z logowania; oddzielić konfigurację Android/iOS i Development/Production.
- [ ] Dodać wymagane capabilities, entitlements i przetłumaczone opisy uprawnień.
  Sekrety i materiały podpisu przechowywać poza Git; konfigurację opisać szablonami.
- [ ] Przygotować odtwarzalną instrukcję budowy na macOS i wybór implementacji
  platformowych w składaniu zależności. Nie podstawiać atrap w wydaniu produkcyjnym.
- **Odbiór:** udany build i uruchomienie na symulatorze oraz podpisany build na
  iPhonie, z zapisanymi wersjami narzędzi. Sam kod przygotowany na Linuksie
  otrzymuje status bez potwierdzenia kompilacji iOS.

### IOS-03 — App Attest po stronie backendu

- [ ] Dodać App Attest obok istniejącego Play Integrity, z osobną konfiguracją.
  Zachować wymagania bezpieczeństwa dotychczasowej ścieżki Androida.
- [ ] Wdrożyć wydawanie krótkotrwałych, losowych, jednorazowych wyzwań,
  rejestrację klucza i weryfikację assertions według aktualnej dokumentacji Apple.
- [ ] Weryfikować łańcuch zaufania, tożsamość aplikacji, środowisko, nonce,
  podpis, powiązanie z instalacją i operacją oraz licznik przeciw powtórzeniom.
  Zużycie wyzwania i aktualizacje stanu muszą być atomowe między instancjami.
- [ ] Zapobiec obejściu przez zmianę pola platformy, ponowne użycie dowodu,
  podmianę instalacji lub użycie dowodu Development w Production.
- [ ] Ustalić bezpieczną obsługę braku wsparcia App Attest i awarii Apple.
  Brak dowodu nie przyznaje automatycznie dostępu; opisać ponowienia i komunikaty.
- [ ] Dodać ograniczanie ruchu, retencję nowych metadanych w istniejącym cleanup
  i diagnostykę bez treści. Zmierzyć dodatkowe operacje Firestore i opóźnienia.
- **Odbiór:** testy poprawnego przepływu, fałszywych i powtórzonych dowodów,
  wygaśnięcia, współbieżności i izolacji środowisk; stare żądania Androida działają.
- **Punkty wejścia:** `PlayIntegrityVerifier.cs`, `GuestStore.cs`, `Program.cs`,
  `FirestoreStore.cs`, `MetadataCleanup.cs`, `backend/tests/`.

### IOS-04 — App Attest w aplikacji i sesje

- [ ] Zaimplementować adapter iOS do protokołu z IOS-03, np. w Swift przez
  kanał Fluttera, zamiast wywoływania `AndroidIntegrityTokenSource` na iPhonie.
- [ ] Obsłużyć dostępność, generowanie/rejestrację klucza, podpisywanie żądań,
  ponowienia, aktualizację aplikacji, reinstalację i utratę klucza.
- [ ] Powiązać dowód z faktyczną operacją i instalacją. Nie resetować limitu przy
  ponownym logowaniu, zmianie klucza ani odzyskiwaniu sesji.
- [ ] Przetestować sesję gościa, połączenie z kontem, wylogowanie, odrzucenie
  sesji i usunięcie konta; uzgodnić zachowanie danych Keychain po reinstalacji.
- **Odbiór:** iPhone uzyskuje sesję przez prawdziwy App Attest i wykonuje
  operację AI; bezprawny dowód jest odrzucany, Play Integrity nadal działa.
- **Punkt wejścia:** `mobile/lib/features/account/data/backend_session_gateway.dart`.

### IOS-05 — szyfrowana historia i dane lokalne

- [ ] Dodać implementację `HistoryDocumentStore` dla iOS: szyfrowany dokument,
  klucz w Keychain, zapis atomowy i obsługa uszkodzenia lub utraty klucza.
- [ ] Wyłączyć historię i klucz z synchronizacji i przenoszenia przez backup;
  skonfigurować ochronę pliku i dostępność klucza. Sprawdzić zachowanie na urządzeniu.
- [ ] Zachować odczyt i edycję historii obu trybów, retencję 7 dni, usuwanie
  przy odczycie/starcie/wznowieniu oraz czyszczenie po wylogowaniu i usunięciu konta.
- [ ] Sprawdzić przechowywanie sesji, języka i zgody AI przez
  `flutter_secure_storage`, w tym wyłączoną synchronizację iCloud.
- **Odbiór:** testy czasu, równoczesnych zapisów, uszkodzonych danych i usuwania;
  historia nie pojawia się po odtworzeniu backupu i nie synchronizuje się z iCloud.
- **Punkt wejścia:** `mobile/lib/features/history/data/encrypted_history_repository.dart`.

### IOS-06 — aparat, kadrowanie i OCR

- [ ] Uruchomić istniejące `camera` i ML Kit na iOS; nie wymieniać biblioteki
  OCR bez konkretnego powodu. Zdjęcia i rozpoznawanie pozostają na urządzeniu.
- [ ] Zweryfikować obrót, orientację, jakość zdjęcia, kadrowanie i usuwanie
  plików tymczasowych po sukcesie, błędzie, anulowaniu oraz przerwaniu aplikacji.
- [ ] Obsłużyć odmowę i cofnięcie uprawnień oraz powrót z tła.
- [ ] Zachować przepływ „zdjęcie → kadr → Uprość”, automatyczne wysłanie tekstu,
  limit 4000 znaków i pozostawienie rozpoznanego tekstu po błędzie wysłania.
- **Odbiór:** próby na rzeczywistym iPhonie dla 13 wariantów językowych,
  dokumentów obróconych i błędów; zdjęcia nie opuszczają urządzenia.
- **Punkty wejścia:** `mobile/lib/features/photo/`, istniejące testy aparatu i OCR.

### IOS-07 — konto i logowanie Apple

- [ ] Skonfigurować Apple jako dostawcę w istniejącym Firebase i dodać go do
  aplikacji, modelu konta, backendowej listy dostawców i kontraktu API.
- [ ] Zachować Google oraz e-mail/hasło, potwierdzanie e-maila, reset hasła,
  odwoływanie sesji i ponowne uwierzytelnienie przed usunięciem konta.
- [ ] Obsłużyć ukryty adres Apple, dane profilu dostępne przy pierwszej zgodzie,
  anulowanie oraz błędy logowania. Nie scalać kont na podstawie samego e-maila;
  powiązanie istniejących metod wymaga potwierdzenia tożsamości.
- [ ] Zapewnić to samo konto Firebase na obu platformach, wspólny limit
  i zachowanie dotychczasowego wykorzystania przy łączeniu instalacji.
- [ ] Dodać usuwanie konta w aplikacji z wymaganym odwołaniem dostępu Apple;
  nie utożsamiać usunięcia konta z anulowaniem subskrypcji.
- **Odbiór:** prawdziwe logowanie wszystkimi metodami na iPhonie, ukryty e-mail,
  ponowne logowanie, łączenie metod i usunięcie konta; regresja Google na Androidzie.
- **Punkty wejścia:** `firebase_account_repository.dart`, `account.dart`,
  `FirebaseTokenVerifier.cs`, `FirebaseAccountAccess.cs`, `AccountDeletionService.cs`.

### IOS-08 — dyktowanie i odczyt bez wysyłania audio

- [ ] Dodać implementacje istniejących `SpeechService` i `TextPlaybackService`
  dla iOS, np. Apple Speech i `AVSpeechSynthesizer` przez adapter Swift.
- [ ] Sprawdzać wsparcie lokalnego rozpoznawania dla urządzenia i języka;
  wymuszać pracę na urządzeniu. Brak wsparcia wyłącza dyktowanie z jasnym
  komunikatem, bez cichego przełączenia na rozpoznawanie sieciowe.
- [ ] Dla każdego z 13 wariantów sprawdzić dostępność modeli i lokalnych głosów;
  opisać ograniczenia oraz pobieranie zasobów. Nie obiecywać pełnej macierzy
  na podstawie samego API. Audio nie jest zapisywane ani wysyłane.
- [ ] Zachować kończenie po 1,5 s ciszy po mowie lub maksymalnie 60 s,
  anulowanie, czyszczenie edytora i automatyczne wysłanie rozpoznanego tekstu.
- [ ] Zatrzymywać odczyt przy zmianie trybu, menu i przejściu w tło; obsłużyć
  przerwania audio, uprawnienia, słuchawki i błędy sesji audio.
- **Odbiór:** testy adapterów i ViewModeli oraz udokumentowane próby offline
  na iPhonie; niedostępny język nie uruchamia sieciowego rozpoznawania.

### IOS-09 — backend subskrypcji Apple

- [ ] Dodać adapter Apple do istniejącej obsługi subskrypcji i Firestore,
  zachowując zakup Google Play `subscription_full` / `monthly` oraz RTDN.
- [ ] Zweryfikować aktualny protokół StoreKit, App Store Server API
  i App Store Server Notifications V2. Weryfikować podpisy, aplikację, produkt,
  środowisko i przypisanie transakcji do uwierzytelnionego konta.
- [ ] Obsłużyć zakup, odnowienie, anulowanie, wygaśnięcie, okres karencji,
  problem z płatnością, zwrot, odwołanie i przywrócenie zgodnie ze stanem Apple.
- [ ] Zapewnić idempotencję, odporność na powiadomienia poza kolejnością,
  ponowienia i zakaz przypisania tego samego zakupu do dwóch kont.
- [ ] Utrzymać ograniczoną świeżość weryfikacji, odświeżanie na żądanie,
  koordynację między instancjami i brak wywołań sklepu wewnątrz transakcji.
  Awaria nie zeruje użycia ani nie przedłuża przeterminowanego uprawnienia.
- [ ] Agregować uprawnienia obu sklepów do jednego limitu 400; zachować tier
  testerski. Dodać testy równoczesnego używania Androida i iPhone'a.
- **Odbiór:** testy integracyjne stanów zakupu, powtórzeń, utraconych powiadomień,
  izolacji sandbox/production i regresji Google; później rzeczywiste próby sandbox.
- **Punkty wejścia:** `SubscriptionService.cs`, `BillingContracts.cs`,
  `FirestoreStore.cs`, `UsageGate.cs`, `Program.cs`, `backend/tests/`.

### IOS-10 — zakupy Apple w aplikacji

- [ ] Skonfigurować miesięczną subskrypcję w App Store Connect; zapisać
  rzeczywiste ID i ustawienia w konfiguracji. Cel ceny w Polsce: 9,99 PLN,
  z potwierdzeniem dostępnej ceny Apple; UI zawsze pokazuje cenę ze sklepu.
- [ ] Dodać implementację `SubscriptionStore` dla Apple, wykorzystując
  `in_app_purchase`, jeśli spełnia wymagania. Usunąć założenia o tokenie Play
  ze wspólnych kontraktów, zachowując zgodność Androida.
- [ ] Obsłużyć oczekiwanie, sukces, anulowanie, błąd, przywracanie i ukończenie
  transakcji według StoreKit po poprawnej weryfikacji serwerowej.
- [ ] Dodać zarządzanie subskrypcją we właściwym sklepie oraz czytelną obsługę
  konta z zakupem na drugiej platformie; ograniczyć ryzyko podwójnego zakupu.
- [ ] Oddzielić flagi Apple/Google. Gdy zakupy są wyłączone lub oferta jest
  niedostępna, nie odsyłać użytkownika do niedziałającego panelu.
- **Odbiór:** rzeczywiste zakupy sandbox/TestFlight, przywrócenie na drugim
  urządzeniu, odnowienie i wygaśnięcie; poprawny limit 400 na wspólnym koncie.

### IOS-11 — interfejs, lokalizacja i dostępność

- [ ] Sprawdzić safe areas, klawiaturę, zaznaczanie i systemowe kopiowanie,
  nawigację i gest powrotu. Zapewnić przywrócenie oryginału wyniku na iOS.
- [ ] Zachować przepływy edytora i czyszczenia, położenie gumki oraz cele
  dotykowe co najmniej 48 dp. Przetestować duży tekst i małe ekrany iPhone'a.
- [ ] Sprawdzić VoiceOver: kolejność, etykiety ikon, fokus, komunikaty błędów,
  stan przetwarzania i wynik; zachować kontrast WCAG AA.
- [ ] Uzupełnić wspólną lokalizację o Apple i komunikaty zależne od platformy
  we wszystkich 13 wariantach. Usunąć androidowe instrukcje z ekranów iOS.
- [ ] Zachować ostrzeżenie o błędach AI, informację przed pierwszą wysyłką,
  Start bez konta, licznik 1/0 i czas resetu według serwera.
- **Odbiór:** testy widgetów istotnych różnic oraz ręczne próby VoiceOver,
  powiększonego tekstu, klawiatury i wszystkich wersji językowych.

### IOS-12 — prywatność i przygotowanie sklepu

- [ ] Zaktualizować politykę w aplikacji, backendzie i na stronie: dostawcy
  Apple, nowe metadane, retencja, usuwanie, lokalna historia i obsługa mowy.
  Zachować wiek 13+, brak zbierania daty urodzenia i brak niepopartych deklaracji.
- [ ] Sprawdzić rzeczywiste zachowanie i telemetrię SDK; przygotować App Privacy,
  wymagane privacy manifests i uzasadnienia używanych API według bieżących zasad.
- [ ] Zweryfikować informację i wyraźną zgodę przed przekazaniem tekstu do
  zewnętrznego AI, możliwość usuwania konta i obsługę subskrypcji.
- [ ] Przygotować opisy, zrzuty ekranu, kategorię wiekową, adres pomocy,
  prywatności i uwagi dla recenzenta; deklaracje mają odpowiadać gotowemu produktowi.
- **Odbiór:** spójne treści w 13 wariantach, gotowe materiały i lista faktycznie
  sprawdzonych deklaracji. Przygotowanie plików nie oznacza ich publikacji.

### IOS-13 — testy całości i zgodność Androida

- [ ] Zintegrować zadania i uruchomić odpowiednie kontrole: `dart format`,
  `flutter analyze`, `flutter test`, `dotnet test backend/Sedno.Backend.sln`.
  Wykonać je z właściwych katalogów i zapisać wyniki oraz braki środowiska.
- [ ] Dodać testy istotnej logiki: czas, sieć, OCR, AI, tożsamość, billing,
  atestacja, rezerwacje limitów i współbieżność z kontrolowanymi zależnościami.
- [ ] Na iPhonie sprawdzić pełne przepływy oraz brak sieci, timeout, odmowę
  uprawnień, tło, anulowanie i ponowienie. Uwzględnić oba tryby i 13 języków.
- [ ] Sprawdzić reset o 00:00 UTC, zachowanie użycia po logowaniu i zmianie
  platformy, wspólne 400 oraz wygaśnięcie historii i uprawnień.
- [ ] Zbudować i sprawdzić Androida po zmianach: Play Integrity, Google/e-mail,
  aparat, mowa, historia, Play Billing i stare wersje klienta wobec nowego API.
- [ ] Sprawdzić aktualizację istniejącej instalacji i starsze dokumenty Firestore.
  Potwierdzić brak treści użytkowników i sekretów w logach.
- **Odbiór:** raport z wynikami automatycznymi i macierzą urządzeń/wersji iOS,
  rozdzielający wykonane próby od planowanych. Brak krytycznych regresji.

### IOS-14 — wydanie i odbiór

- [ ] Potwierdzić dostęp do Maca/Xcode, rzeczywistego iPhone'a, Apple Developer
  Program, App Store Connect oraz konfiguracji Firebase i sekretów backendu.
  Brak dostępu blokuje tylko zależne czynności, nie przygotowanie kodu.
- [ ] Przygotować zgodny wstecznie rollout backendu przed udostępnieniem iOS,
  konfigurację istniejącego `sedno-api`, plan wycofania i kontrolę starych rewizji.
- [ ] Przeprowadzić podpisany build IPA, walidację i dystrybucję TestFlight;
  potwierdzić środowiska App Attest i zakupów używane przez konkretny kanał.
- [ ] Odebrać prawdziwe logowanie, atestację, aparat, mowę i zakupy na urządzeniu.
  Zweryfikować opóźnienia, operacje Firestore i diagnostykę po wdrożeniu.
- [ ] Przygotować kompletne wydanie App Store i przeprowadzić publikację
  w uzgodnionym zakresie. Nie uruchamiać publicznych zakupów przed ich odbiorem.
- [ ] Zaktualizować README aplikacji i backendu oraz instrukcje utrzymania:
  budowanie obu platform, konfiguracja Apple, powiadomienia, testy i odzyskiwanie.
- **Odbiór:** identyfikatory faktycznych buildów i wdrożeń, wynik odbioru,
  działający Android i iPhone oraz opis ograniczeń. Nie deklarować zbudowania
  IPA/APK/AAB ani publikacji bez zakończonej operacji.

## Źródła do weryfikacji podczas implementacji

Wymagania i wersje narzędzi sprawdzić ponownie przed wdrażaniem zadań:

- [Flutter — budowanie i publikacja iOS](https://docs.flutter.dev/deployment/ios)
- [Apple — App Attest w aplikacji](https://developer.apple.com/documentation/devicecheck/establishing-your-app-s-integrity)
- [Apple — weryfikacja App Attest na serwerze](https://developer.apple.com/documentation/devicecheck/validating-apps-that-connect-to-your-server)
- [Apple — lokalne rozpoznawanie mowy](https://developer.apple.com/documentation/speech/sfspeechrecognizer/supportsondevicerecognition)
- [Firebase — logowanie federacyjne we Flutterze](https://firebase.google.com/docs/auth/flutter/federated-auth)
- [Apple — App Store Server API](https://developer.apple.com/documentation/appstoreserverapi)
- [Apple — zasady oceny aplikacji](https://developer.apple.com/app-store/review/guidelines/)
- [Używany pakiet OCR — wymagania iOS](https://pub.dev/packages/google_mlkit_text_recognition)
