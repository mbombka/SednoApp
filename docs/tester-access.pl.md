# Dostęp testerski Sedno

Każdy tester używa własnego konta Sedno. Dostęp nadajemy po pierwszym logowaniu.
Serwer daje 400 operacji AI dziennie łącznie (Uprość i Popraw), bez zakupu Google Play.
Dostęp jest rzeczywistym uprawnieniem serwera, nie atrapą modelu ani płatności.
Nie wymaga nowego backendu, konta usługi ani bazy.

Backend z obsługą dostępu testerskiego wdrożono 22.10.2026 jako
`sedno-api-00012-9j4`; aplikacja jest przygotowana w podpisanym
[AAB 12](../mobile/docs/google_play_release_12.md).
[Raport wdrożenia](backend-deployment-2026-10-22.pl.md).

## Uruchomienie narzędzia

Potrzebne są Python 3.9+ z bazą stref czasowych i Google Cloud CLI `gcloud`.
Skrypt używa aktualnie skonfigurowanego konta `gcloud`; nie czyta plików kluczy,
nie tworzy poświadczeń i nie zapisuje tokenów na dysku. W razie potrzeby skonfiguruj
swoje konto administratora zgodnie z procedurą dostępu do projektu.

Z głównego katalogu repozytorium:

```sh
python3 tools/tester_access.py
```

Domyślny projekt to `sednoapp-79241`, baza zawsze `(default)`.
Inny projekt można jawnie wskazać przez `--project IDENTYFIKATOR`.
Narzędzie odmawia pracy z ustawionym `FIRESTORE_EMULATOR_HOST`.

Skrypt wskazuje wybrany projekt także w nagłówku `X-Goog-User-Project`, aby
Google rozliczało limity API w projekcie Sedno. Bez tego nagłówka token konta
użytkownika może powodować HTTP 403 `SERVICE_DISABLED` dla wspólnego projektu
Google Cloud CLI, mimo poprawnego logowania i uprawnień do Sedno.
Opis mechanizmu: [uwierzytelnianie REST Google](https://docs.cloud.google.com/docs/authentication/rest#set-quota-project).

Przebieg:

1. Podaj e-mail konta testera.
2. Skrypt wyszukuje Firebase UID przez Firebase Authentication i odczytuje
   powiązanie `firebase_uids` oraz konto `verified_accounts` w Firestore.
   Nie tworzy kont. Odmawia zmian kont wyłączonych, niespójnych lub usuwanych.
3. Zobaczysz identyfikator konta Sedno i status: brak dostępu, aktywny lub wygasły,
   wraz z datą wygaśnięcia. Jest to status uprawnienia testerskiego,
   nie status płatności Google Play.
4. Wybierz `1`, aby nadać/przedłużyć dostęp, albo `2`, aby usunąć atrybut testera.
   Enter kończy bez zmian.
5. Dla opcji `1` wpisz datę końcową, np. `2026-11-15`. Dostęp będzie ważny
   przez cały wskazany dzień i wygaśnie **16 listopada o 00:00**.
   Jest to czas **Europe/Warsaw**, niezależny od strefy terminala.
   Opcjonalnie możesz nadal podać dokładną godzinę, np. `2026-11-15 20:00`;
   wtedy dostęp wygaśnie dokładnie o 20:00. Skrypt pokaże termin lokalny i UTC.
   Odrzuca terminy, które już minęły, oraz niejednoznaczne/nieistniejące godziny
   podczas zmiany czasu. Możesz podać dzisiejszą datę, aby nadać dostęp do końca dnia.
6. Wpisz `TAK`, aby zapisać. Inna odpowiedź anuluje zmianę.

Narzędzie wymaga uprawnienia IAM `firebaseauth.users.get` oraz odczytu i aktualizacji
istniejących dokumentów Firestore (`datastore.entities.get`, `datastore.entities.update`).
Wymaga również `serviceusage.services.use` w wybranym projekcie (np. rola
Service Usage Consumer), aby wskazać go jako projekt limitów API.
Przykładowe role standardowe to Firebase Authentication Viewer i Cloud Datastore User;
administrator projektu może mieć te uprawnienia przez szerszą rolę. Reguł dostępu
aplikacji mobilnej nie należy otwierać. Skrypt używa OAuth/IAM, a nie reguł klienta.

Zapis aktualizuje tylko pole `TesterAccessExpiresAt`, z warunkiem zgodności
`updateTime` dokumentu. Jeżeli ktoś zmieni konto w międzyczasie, operacja zostanie
przerwana: uruchom skrypt ponownie i sprawdź bieżący status. Po błędzie sieci podczas
zapisu również ponownie sprawdź status — zapis mógł już zostać wykonany.

## Ręczna edycja w konsoli Firebase

Firestore Database → `(default)` → Dane → `verified_accounts` → właściwy dokument:

- dodaj lub zmień pole **`TesterAccessExpiresAt`** jako **Timestamp**;
- aby odebrać dostęp, usuń pole albo ustaw datę w przeszłości;
- nie zmieniaj dokumentów `play_purchases` ani liczników `daily_usage`.

Wielkość liter i typ pola mają znaczenie. Nie wpisuj daty jako tekstu.
Kolekcja kont nie zawiera adresu e-mail. Najłatwiej znaleźć właściwy dokument
skryptem; adres wyszukiwany jest w Firebase Authentication i nie jest kopiowany do bazy.
Pole usunięte może przy późniejszym zapisie konta pojawić się jako `null`;
obie postacie oznaczają brak uprawnienia.

## Zachowanie serwera i aplikacji

- Aktywna subskrypcja ma pierwszeństwo: `tier=subscription`.
- Bez aktywnej subskrypcji ważna data testerska daje `tier=tester`, limit 400.
- Pozostali mają `tier=free`, limit 5. Goście nie dostają dostępu testerskiego.
- Limity nie sumują się; nadanie, przedłużenie, odebranie i wygaśnięcie nie zerują użycia.
- Serwer odczytuje datę konta w tej samej transakcji Firestore, która ustala limit
  i rezerwuje operację. W chwili `serverTime >= TesterAccessExpiresAt` dostęp wygasa.
  Nie wymaga usunięcia pola ani uruchomienia sprzątania. Operacja zarezerwowana
  wcześniej może zostać dokończona zgodnie z dotychczasową ważnością rezerwacji.
- Użycie jest współdzielone między powiązanymi instalacjami konta. Po wykorzystaniu
  np. 30 operacji i powrocie do limitu 5 kolejne operacje są zablokowane do resetu
  o 00:00 UTC. Aktywna subskrypcja nadal daje 400.
- Zakupy Google Play i RTDN działają niezależnie; dostęp testerski nie udaje zakupu.
- Aplikacja pokazuje datę w czasie lokalnym, informację o bezpłatnym dostępie i jego
  wygaśnięciu. Dane dostępu są w odpowiedziach limitu: `tier` i `testerAccessExpiresAt`.
  W czasie dostępu testerskiego nie pokazuje przycisku kupna, ale umożliwia
  przywrócenie zakupów. Rzeczywista subskrypcja nadal ma opcję zarządzania w Google Play.
- Limit odświeża się przy starcie, wznowieniu, po zmianach sesji i operacjach AI,
  a także po dacie wygaśnięcia dostępu testerskiego. Ręczna zmiana administratora
  staje się widoczna po kolejnym odczycie; tester może wrócić do aplikacji, aby odświeżyć.
- Wylogowanie nie usuwa uprawnienia z konta, ale sesja gościa nie korzysta z niego.
  Usunięcie konta usuwa również pole; nowe konto nie dziedziczy dostępu.

## Wdrożenie

Najpierw wdroż backend i udostępnij aplikację obsługującą `tier=tester`, następnie
przyznawaj dostęp testerom korzystającym z tej wersji. Starsza aplikacja nie zna
nowej wartości `tier`. Samo dodanie daty przed wdrożeniem backendu nie zmieni limitu.
Istniejące konta bez pola zachowują dotychczasowe działanie; nie ma migracji bazy.
Nie trzeba zmieniać produktu `subscription_full` ani planu `monthly`.
Nadal należy wykonać osobne testy zakupów Google Play przed publicznym wydaniem.

## Weryfikacja lokalna

```sh
python3 -m unittest discover -s tools/tests
cd backend
dotnet test Sedno.Backend.sln
cd ../mobile
dart format lib/features/account/presentation/tester_access_panel.dart lib/features/quota/domain/quota_state.dart
flutter analyze
flutter test
```

Testy integracyjne backendu uruchamiają wyłącznie emulator Firestore w Dockerze.
Testy skryptu mają atrapę API i nie zmieniają danych w Google.

## Zakres zmian i wynik sprawdzenia — 22.10.2026

Pliki zmienione w ramach dostępu testerskiego:

- Backend: `backend/src/Sedno.Domain/Models.cs`,
  `backend/src/Sedno.Application/Contracts.cs`,
  `backend/src/Sedno.Infrastructure/FirestoreStore.cs`,
  `backend/src/Sedno.Infrastructure/UsageStore.cs` oraz `contracts/openapi.yaml`.
- Aplikacja: `mobile/lib/features/quota/domain/quota_state.dart`,
  `mobile/lib/features/account/presentation/account_screen.dart`,
  nowy `mobile/lib/features/account/presentation/tester_access_panel.dart`,
  `mobile/lib/features/subscription/presentation/subscription_panel.dart`,
  `mobile/lib/features/home/presentation/home_screen.dart`.
- Administracja: nowy `tools/tester_access.py`.
- Testy: nowe `backend/tests/Sedno.IntegrationTests/TesterAccessTests.cs`,
  `backend/tests/Sedno.UnitTests/TesterAccessSerializationTests.cs`,
  `tools/tests/test_tester_access.py`,
  `mobile/test/features/quota/domain/tester_quota_test.dart`,
  `mobile/test/features/home/presentation/tester_expiry_widget_test.dart`,
  `mobile/test/features/subscription/tester_access_panel_test.dart`
  oraz rozszerzony `mobile/test/features/subscription/subscription_test.dart`.
- Dokumentacja: ten dokument oraz odnośniki w `README.md`, `backend/README.md`
  i `mobile/README.md`.

Weryfikacja zakończona powodzeniem:

- `dotnet test backend/Sedno.Backend.sln --no-restore`: 107 testów jednostkowych,
  98 integracyjnych na emulatorze Firestore i 38 testów narzędzi modelowych.
- `flutter test`: 212 testów.
- `flutter analyze`: bez uwag.
- `dart format --output=none --set-exit-if-changed`: 9 zmienionych plików Dart,
  bez wymaganych zmian formatowania.
- `python3 -m unittest discover -s tools/tests`: 20 testów.
- `git diff --check`: bez błędów.

W środowisku wykonania nie ma `gcloud`, dlatego skrypt sprawdzono z atrapami API,
bez prób na rzeczywistych kontach Google. Nie zmieniono produkcyjnych danych,
nie wdrożono backendu ani nowej wersji aplikacji i nie budowano APK/AAB w tym zadaniu.
Wcześniejsze niezacommitowane zmiany w repozytorium zachowano.
