# Płatności na istniejącym serwerze — 20.10.2026

Obsługę zakupów skonfigurowano na dotychczasowym `sedno-api`. Nie wdrożono
osobnego serwera. Próby zakupów na telefonie oraz ustawienia Play Console
wymienione poniżej pozostają do potwierdzenia.

## Wdrożone ustawienia

| Element | Wartość |
| --- | --- |
| Projekt | `sednoapp-79241` |
| API | `https://sednoapp-79241-api.web.app` |
| Usługa / rewizja Cloud Run | `sedno-api` / `sedno-api-00007-dwm` |
| Konto serwera | `sedno-api@sednoapp-79241.iam.gserviceaccount.com` |
| Firestore | istniejąca baza `(default)`, Warszawa |
| Produkt / plan | `subscription_full` / `monthly` |
| Cena i limit | 9,99 PLN miesięcznie w Polsce; 400 uproszczeń dziennie łącznie |
| Włączenie na serwerze | `Billing__Enabled=true` |
| Sekret szyfrowania zakupów | `sedno-billing-keyring`, wersja `1` |
| Montowanie klucza | `/secrets/keyring/key.xml`, tylko odczyt |
| Konto podpisujące powiadomienia | `sedno-billing-push@sednoapp-79241.iam.gserviceaccount.com` |
| Temat Google Play | `projects/sednoapp-79241/topics/sedno-billing-rtdn-test` |
| Subskrypcja push | `sedno-billing-rtdn-push` |
| Odbiornik i audience OIDC | `https://sednoapp-79241-api.web.app/notifications/google-play` |
| Temat niedostarczonych wiadomości | `sedno-billing-rtdn-test-dead-letter` |
| Kolejka przeglądu niedostarczonych wiadomości | `sedno-billing-rtdn-test-dead-letter-review` |

Zachowano dotychczasowe klucze sesji i fingerprintów, bazę, konto usługi oraz
parametry skalowania. Nie dodawano kontu serwera nowych uprawnień Firebase.
Serwer dostał odczyt wyłącznie nowego sekretu zakupów. Google Play może publikować
do wskazanego tematu; Pub/Sub podpisuje dostarczenia kontem powiadomień.
Ponowienia: 10–600 sekund, termin potwierdzenia 60 sekund, po maksymalnie 10
próbach kierowanie do dead-letter; retencja wiadomości 7 dni.

Obraz:
`europe-central2-docker.pkg.dev/sednoapp-79241/backend/api@sha256:5fde147b5844c779ae77867c1ee8e8513515afe1f6ef28beec2f5640077d802e`.
Cloud Build: `4e334b0b-ff8b-4bf2-a3f8-dd85aede296c` — sukces.
Hosting API opublikowano ponownie, przypinając nową rewizję.
Kopia polityki w API zawiera wersję 20.10.2026 i wiek od 13 lat.

## Weryfikacja

- `/health/ready`: HTTP 200 przez publiczny adres API.
- Odbiornik RTDN bez tokenu: HTTP 401.
- Syntetyczne `testNotification` wysłane przez rzeczywisty Pub/Sub:
  dostarczenie do rewizji `sedno-api-00007-dwm`, HTTP 204, 20.10.2026 o 10:24:54 UTC.
- To potwierdza transport Pub/Sub, podpis, audience i działanie odbiornika.
  Nie potwierdza zakupu ani włączenia wysyłania RTDN w Play Console.
- Nie odczytywano wartości sekretów w raportach ani nie wykonywano płatnego zakupu.

## Pozostałe ustawienia Google Play

1. W Play Console → Użytkownicy i uprawnienia udostępnij aplikację Sedno
   istniejącemu kontu serwera `sedno-api@sednoapp-79241.iam.gserviceaccount.com`.
   Potrzebne są uprawnienia wyświetlania danych finansowych oraz zarządzania
   zamówieniami i subskrypcjami. Nie używaj konta `sedno-billing-test`.
2. W ustawieniach zarabiania aplikacji włącz RTDN dla subskrypcji i unieważnionych
   zakupów. Wpisz pełną nazwę tematu:
   `projects/sednoapp-79241/topics/sedno-billing-rtdn-test`.
   Wyślij wiadomość testową z Play Console i sprawdź odbiór HTTP 204.
3. Konto Google telefonu: konto właściciela. Właściciel potwierdził, że jest
   już dodane jako testowe; przy próbie zakupu sprawdź widoczność metody testowej.
4. Prześlij [AAB 8](../mobile/docs/google_play_release_8.md), zainstaluj go z Google
   Play i przejdź [listę prób zakupów](../mobile/docs/google_play_subscription_sandbox.md).
   Używaj metod testowych; nie potwierdzono rzeczywistego zakupu, przywracania,
   wygaśnięcia, zwrotów ani limitu 400 po zakupie.

Nie uzyskano potwierdzenia tych ustawień w Play Console. Odczytowe sprawdzenie
produktu przez impersonację konta serwera nie było możliwe z konta operatora;
nie rozszerzano w tym celu uprawnień. Bezpośrednia próba Play API z logowaniem
operatora zwróciła HTTP 403, `ACCESS_TOKEN_SCOPE_INSUFFICIENT`: dostępne
poświadczenia Google Cloud nie mają zakresu OAuth `androidpublisher`.
Właściciel potwierdził, że konto serwera istnieje w Play Console i zlecił zmianę
jego uprawnień; do wykonania tego kroku potrzebna jest autoryzacja Play API
albo zapis ustawień w panelu.

## Aktualizacja — poprawka subskrypcji, 20.10.2026

Wdrożono commit `19e09f7`: subskrypcja jest ważna do daty wygaśnięcia z Google Play
(bez 15-minutowego okna świeżości), a status subskrypcji sprawdzany jest raz na żądanie.

| Element | Wartość |
| --- | --- |
| Rewizja Cloud Run | `sedno-api-00008-6vj`, 100% ruchu, przypięta w Hosting |
| Obraz | `europe-central2-docker.pkg.dev/sednoapp-79241/backend/api@sha256:576bfe2fe34dd8923b13356531a04da3e39c049de3e268898aaa2cfdc76c371c` (tag `20261020-19e09f7`) |
| Cloud Build | `57ed0233-2965-413e-a95c-9b23e1b7acc2` — sukces |
| Poprzednia rewizja | `sedno-api-00007-dwm` |

Przed wdrożeniem sprawdzono, że działająca usługa była zgodna z `service.json`;
zmieniono tylko digest obrazu. Poprzedni manifest:
`backend/deploy/generated/service-before-subscription-fix.json`. Reguł, indeksów
i zadania cleanup nie zmieniano.

Weryfikacja: `/health/ready` HTTP 200 przez publiczny adres (obsłużone przez nową
rewizję), `/v1/quota` bez sesji HTTP 401, odbiornik RTDN bez tokenu HTTP 401.

## Aktualizacja — polityka prywatności, 20.10.2026

Usunięto nieaktualne zdanie o wyłączonych płatnościach Google Play z polityki
wbudowanej w API (`/prywatnosc`); pozostałe zmiany backendu to komentarz i dokumentacja.

| Element | Wartość |
| --- | --- |
| Rewizja Cloud Run | `sedno-api-00009-8jv`, 100% ruchu, przypięta w Hosting |
| Obraz | `europe-central2-docker.pkg.dev/sednoapp-79241/backend/api@sha256:bf3d174749152d23917ac134234a0551a9d4451a2dd694a26b107cc40852133c` (tag `20261020-policy`) |
| Cloud Build | `241a8dbf-6b67-448d-b063-7e06b8d9c875` — sukces |
| Poprzednia rewizja | `sedno-api-00008-6vj`; manifest: `backend/deploy/generated/service-before-policy-update.json` |

Przed wdrożeniem działająca usługa była zgodna z `service.json`; zmieniono tylko digest.
Weryfikacja: `/health/ready` HTTP 200, `/v1/quota` bez sesji HTTP 401, odbiornik RTDN
bez tokenu HTTP 401, `/prywatnosc` bez usuniętego zdania. Strona `sedno.xyz` jest
hostowana osobno i wymaga ręcznej publikacji plików z `docs/public/`.

## Kolejne wdrożenie i wycofanie

Przy generowaniu konfiguracji dotychczasowej usługi użyj
`--billing-product subscription_full --push-email sedno-billing-push@sednoapp-79241.iam.gserviceaccount.com`
oraz `--google-credentials cloud-run`. Opcja `--without-billing` wyłącza obsługę zakupów.
Zachowaj sekret `sedno-billing-keyring` i jego wersję; nie twórz nowego klucza
przy każdym wdrożeniu. Klucz wymaga zaplanowania rotacji przed wygaśnięciem.

Bieżący lokalny manifest to `backend/deploy/generated/service.json`.
Kopia konfiguracji sprzed włączenia zakupów jest w
`backend/deploy/generated/service-before-billing.json`; poprzednia rewizja to
`sedno-api-00006-j9x`. Wycofanie wymaga również aktualizacji przypięcia Firebase Hosting.
Nie usuwaj sekretu po zapisaniu zakupów, również przy czasowym wyłączeniu płatności.

## Odrzucone osobne środowisko

Przed korektą zakresu utworzono bazę `billing-test`, konto `sedno-billing-test`
i sekrety `sedno-billing-test-credential-key`, `sedno-billing-test-fingerprint-key`,
`sedno-billing-test-keyring`. Nie są używane przez istniejący serwer; nie wdrożono
żadnej usługi testowej. Nie nadano temu kontu wcześniej proponowanych ról.

Uporządkowanie 20.10.2026: przed usunięciem sprawdzono, że baza była pusta,
konto nie miało ról ani kluczy, a usługi Cloud Run nie używały tych zasobów.
Usunięto bazę `billing-test`, konto `sedno-billing-test` i trzy sekrety
`sedno-billing-test-*`. Usunięto też nieużywane sekrety `sedno-postgres`
i `sedno-postgres-migration` po dawnej bazie PostgreSQL.
Bazie `(default)` włączono ochronę przed usunięciem. `/health/ready`: HTTP 200.

Odrzucony AAB 7 przeniesiono z katalogu wydań do `mobile/build/discarded/`;
nie należy go publikować. Lokalną konfigurację z niewłaściwym adresem usunięto.

Źródła konfiguracji: [Google Play RTDN](https://developer.android.com/google/play/billing/getting-ready),
[uwierzytelnianie Pub/Sub push](https://docs.cloud.google.com/pubsub/docs/authenticate-push-subscriptions).
