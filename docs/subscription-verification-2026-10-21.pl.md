# Ważność weryfikacji subskrypcji — 21.10.2026

Zmianę wdrożono jako `sedno-api-00011-bfh` 21.10.2026.
[Raport wdrożenia i potwierdzenie RTDN 204](backend-deployment-2026-10-21.pl.md).
Korzysta z istniejącego zakupu,
blokady konta, usługi `sedno-api` i bazy `(default)`. Nie zmienia aplikacji ani
kontraktu API. Nie dodaje zadania okresowego.

## Działanie

Płatny limit wymaga poprawnego stanu zakupu, przyszłego `ExpiresAt` oraz
`VerifiedAt` sprzed mniej niż 15 minut, bez daty z przyszłości. Weryfikacja
nie przedłuża terminu zakupu. Świeży zapis jest obsługiwany samym odczytem:
bez Google, blokady i zapisu w Firestore. Status jest nadal ustalany raz na żądanie.

Starszy zapis odświeża się podczas ustalania limitu, także podczas uproszczenia,
bez otwierania panelu zakupów. Istniejąca dzierżawa konta koordynuje instancje,
RTDN, przywracanie i usuwanie konta. Po jej uzyskaniu backend ponownie czyta zakupy.
Google jest wywoływane poza ponawianą transakcją Firestore. `VerifiedAt` pochodzi
z chwili odebrania odpowiedzi Google, nie z kolejnej próby zapisu transakcji.

Odświeżanie ma limit 2 sekund. Po błędzie zakup otrzymuje opcjonalne
`RefreshNotBefore` ustawione minutę w przyszłość. Kolejne żądania w tym czasie
nie wywołują Google. Zapis błędu ma osobny, ograniczony czas, żeby anulowanie
żądania również zachowało przerwę. Starsze dokumenty bez pola nadal działają.
Błąd nie zmienia `VerifiedAt`, `ExpiresAt` ani wykorzystania limitu. Backend
stosuje limit darmowy; wykorzystanie większe niż 5 blokuje dalsze uproszczenia.
Niedostępność samej bazy lub utrata dzierżawy nie pozwalają przyznać płatnego limitu.

RTDN pozostaje główną drogą szybkiej aktualizacji. Omija przerwę po błędzie,
sprawdza bieżący stan w Google i zapisuje identyfikator powiadomienia dopiero
po powodzeniu. Błąd nie potwierdza przetworzenia i pozwala Pub/Sub ponowić
wiadomość. Poprawne RTDN, przywrócenie i odświeżenie usuwają przerwę.

## Odczyt bieżącej konfiguracji chmury

Sprawdzono przez Google Cloud API 21.10.2026, bez zmian konfiguracji,
publikowania wiadomości i pobierania treści zakupów:

| Element | Potwierdzony stan |
| --- | --- |
| Cloud Run `sedno-api` | Billing włączone, pakiet `xyz.sedno.app`, produkt `subscription_full` |
| Temat RTDN | `projects/sednoapp-79241/topics/sedno-billing-rtdn-test` |
| Wydawca tematu | `google-play-developer-notifications@system.gserviceaccount.com`, `roles/pubsub.publisher` |
| Push `sedno-billing-rtdn-push` | `ACTIVE`, endpoint i audience `https://sednoapp-79241-api.web.app/notifications/google-play` |
| Konto OIDC | `sedno-billing-push@sednoapp-79241.iam.gserviceaccount.com`, zgodne z konfiguracją API |
| Ponowienia | 10–600 sekund, termin potwierdzenia 60 sekund, retencja 7 dni |
| Dead-letter | temat `sedno-billing-rtdn-test-dead-letter`, około 10 prób dostarczenia |
| IAM dead-letter | agent Pub/Sub ma publisher na temacie i subscriber na subskrypcji źródłowej |
| Przegląd dead-letter | `sedno-billing-rtdn-test-dead-letter-review`, `ACTIVE`, pull, retencja 7 dni, bez automatycznego wygasania subskrypcji |

Metryki źródłowej subskrypcji z 21.10.2026, 06:14 UTC: 0 niedostarczonych
wiadomości, wiek najstarszej niepotwierdzonej wiadomości 0 sekund. Dla kolejki
przeglądu brak szeregu metryk w odczytanym oknie 24 godzin; nie traktujemy tego
jako potwierdzenia jej pustki. Nie pobierano ani nie potwierdzano jej wiadomości.

Ostatnie odczytane dostarczenie HTTP 204 pochodzi z 20.10.2026, 13:54:06 UTC.
Historia zawiera też HTTP 400 i 401; same kody nie dowodzą utraty prawidłowych RTDN.
Konfiguracja Pub/Sub nie potwierdza wszystkich ustawień nadawcy w Play Console
ani pełnego przebiegu rzeczywistego zakupu.

Kolejka dead-letter wymaga ręcznego przeglądu i kontrolowanego ponowienia
przetwarzania po usunięciu przyczyny błędu, przed upływem retencji. Backend nie
ma automatycznego konsumenta tej kolejki. Nie wdrażano go w tej zmianie.

Zgodnie z [dokumentacją RTDN](https://developer.android.com/google/play/billing/rtdn-reference)
powiadomienie jest sygnałem do odczytania statusu zakupu z Google.
[Dokumentacja Pub/Sub](https://docs.cloud.google.com/pubsub/docs/dead-letter-topics)
zastrzega, że liczba prób przed dead-letter jest przybliżona i wymaga właściwego IAM.

## Weryfikacja lokalna

Testy kontrolują czas, Google i Firestore przez emulator. Obejmują granicę
15 minut, utracone RTDN i odebrany zakup, odnowienie aktywnego zakupu,
wygaśnięcie zakupu wcześniej niż potwierdzenia, brak zapisów dla świeżych danych,
współbieżność niezależnych instancji także przy awarii Google, minutową przerwę,
zachowanie liczników, anulowanie oraz RTDN omijające przerwę i ponawiane po błędzie.

`dotnet test backend/Sedno.Backend.sln --no-restore` — sukces: 105 testów
jednostkowych, 80 integracyjnych, 38 narzędzi pomiarowych (223 łącznie).
`git diff --check` — bez błędów. Testy integracyjne używały lokalnego Dockera
i emulatora, bez rzeczywistych wywołań Google Play. Fluttera nie zmieniano;
nie uruchamiano jego testów ani kompilacji Androida.

## Zmienione pliki

- [SubscriptionService.cs](../backend/src/Sedno.Infrastructure/SubscriptionService.cs): świeżość, odświeżanie, blokada i przerwa po błędzie.
- [Models.cs](../backend/src/Sedno.Domain/Models.cs): opcjonalny termin kolejnej próby w istniejącym zakupie.
- [FirestoreStore.cs](../backend/src/Sedno.Infrastructure/FirestoreStore.cs): zapis nowego pola jako timestamp.
- [UsageStore.cs](../backend/src/Sedno.Infrastructure/UsageStore.cs): aktualizacja komentarza o wywołaniach Google poza transakcją.
- [SubscriptionApiTests.cs](../backend/tests/Sedno.IntegrationTests/SubscriptionApiTests.cs): scenariusze integracyjne zmiany.
- [README backendu](../backend/README.md), [Tasks.md](../Tasks.md) i ten raport: opis działania, status i aktualna kontrola chmury.
