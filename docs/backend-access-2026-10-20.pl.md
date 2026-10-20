# Dostęp do rewizji API — kontrola 20.10.2026

Zadanie wykonano na istniejącym `sedno-api` w projekcie `sednoapp-79241`,
region `europe-central2`. Aktualna rewizja to **`sedno-api-00010-wj5`**;
otrzymuje 100% ruchu i obsługuje Hosting. Kontrole wykonano około 16:21–16:31
czasu polskiego. Nie tworzono dodatkowej usługi ani bazy.

## Sprawdzone rewizje i adresy

Przed zmianą Cloud Run kierował 100% ruchu na `00009`, ale zachowywał cztery
publiczne tagi poprzednich rewizji. Hosting API miał tylko kanał `live`,
przypięty do `fh-84206ceb4a4bae7b` / `00009`. Drugi serwis Hosting,
`sednoapp-79241`, miał tylko kanał `live`, bez opublikowanego wydania i przepisań.
Nie było kanałów podglądu wymagających zachowania starego API.

Poniższe tagi usunięto. Pełny stary adres ma postać
`https://TAG---sedno-api-cabqsikexq-lm.a.run.app`.

| Rewizja | Usunięty tag | GET `/v1/quota` | POST `/v1/auth/sessions` |
| --- | --- | --- | --- |
| `sedno-api-00003-xlh` | `fh-4e0714a3b37bec42` | 404 | 404 |
| `sedno-api-00004-w5q` | `fh-4c0f36a1f1e95b7f` | 404 | 404 |
| `sedno-api-00005-5g5` | `fh-b452257d0d97801f` | 404 | 404 |
| `sedno-api-00006-j9x` | `fh-05752b0cf67738ff` | 404 | 404 |
| `sedno-api-00009-8jv` | `fh-84206ceb4a4bae7b` | 404 | 404 |

`sedno-api-00007-dwm` i `sedno-api-00008-6vj` także sprawdzono w wykazie rewizji:
nie miały tagów ani udziału w ruchu. Rewizje pozostawiono administracyjnie;
nie mają publicznego przypięcia. Nie usuwano obrazów ani historii wdrożeń.
Dla pierwszych czterech starych adresów sprawdzono również 404 `/health/ready`;
dla `00009` ten sam test wykonało `retire_routes.py` po przełączeniu Hosting.

Jedynym pozostałym tagiem jest `fh-124b4d67a8c727d4` → `sedno-api-00010-wj5`.
Hosting `live` ma wersję `124b4d67a8c727d4`, wydanie
`1792506411364000`, z tym samym przypięciem.

## Sesje i próby dostępu

Nowe sesje kont otrzymują `AccountAccessVerified=true` dopiero w transakcji
`GuestStore.LinkAsync`, po dotychczasowej kontroli tożsamości i potwierdzenia
adresu e-mail. `AuthenticateAsync` odrzuca sesje kont bez tej wartości.
Brak pola w starym dokumencie jest równoważny `false`.

Wymusza to jednorazowe ponowne logowanie dla wszystkich wcześniejszych sesji
kont, również Google. Nie zmieniono klucza sesji: stare sesje gości pozostają
ważne. Zachowano powiązania instalacji, limity, konta i zakupy. Późniejsze
potwierdzenie adresu lub zmiana dostawcy konta nie przywracają starego tokenu.
Nie jest to mechanizm bieżącego sprawdzania odwołania sesji w Firebase;
ten osobny temat pozostaje w zadaniu 2.

Kontrola produkcyjna użyła dwóch tymczasowych kont Firebase z hasłem i adresem
w `example.invalid`. Potwierdzono w Firebase `emailVerified=false`.
Utworzono po pięć syntetycznych dokumentów w istniejącej bazie `(default)`:
dwie tożsamości, konto, sesję gościa i dawną sesję konta bez nowego pola.
Nie wysyłano wiadomości e-mail, tekstów do uproszczenia ani żądań do modelu.
Klucz do wyliczenia HMAC pozostawał w pamięci procesu; nie zapisywano kluczy,
poświadczeń ani tokenów w raporcie. Konta testowe i wszystkie dziesięć dokumentów
usunięto w blokach sprzątających; odpowiedzi operacji usunięcia sprawdzono.

Pod każdym z poniższych adresów sprawdzono:

| Próba | Wynik |
| --- | --- |
| GET `/v1/quota`, stara sesja konta | 401 |
| GET `/v1/subscription`, stara sesja konta | 401 |
| GET `/v1/quota`, stara sesja gościa | 200 |
| POST `/v1/auth/sessions`, sesja gościa + rzeczywisty token niepotwierdzonego konta | 403 `email_not_verified` |

Adresy poddane powyższym próbom:

- `https://sednoapp-79241-api.web.app`
- `https://sednoapp-79241-api.firebaseapp.com`
- `https://sedno-api-cabqsikexq-lm.a.run.app`
- `https://sedno-api-1003558402460.europe-central2.run.app`
- `https://fh-124b4d67a8c727d4---sedno-api-cabqsikexq-lm.a.run.app`

Na pięciu starych adresach próby GET i POST wykonano z syntetyczną sesją gościa;
POST zawierał rzeczywisty token niepotwierdzonego konta. Wszystkie zwróciły 404.
Gotowość aktualnego Hosting po usunięciu tagów: `/health/ready` → 200.
Początkowa kontrola API i Hosting bez sesji: `/v1/quota` → 401.

## Wdrożenie i zabezpieczenie następnych wydań

- Cloud Build: `e416cee7-c339-4acb-a60a-a8edd726d3cc`, **SUCCESS**.
- Obraz: `europe-central2-docker.pkg.dev/sednoapp-79241/backend/api@sha256:232300d133fd38e75fba2ca3492be5fe3cd9e52a36835222a165bb99a07a2baf`.
- Zaktualizowano obraz istniejącej usługi, potem Hosting i uruchomiono
  `retire_routes.py`. Zachowano konto
  `sedno-api@sednoapp-79241.iam.gserviceaccount.com`, konfigurację płatności,
  sekrety oraz bazę. Lokalny manifest obrazu także zaktualizowano.
- `deploy.sh` pomija tagi z lokalnego manifestu, zachowuje aktualne przypięcie
  na czas przełączenia, jawnie ustawia 100% ruchu na gotową rewizję, publikuje
  Hosting i usuwa wszystkie tagi poza sprawdzonym przypięciem `live`.
- `retire_routes.py` odmawia usuwania tagów przy niezgodnym przypięciu Hosting,
  braku gotowości albo zmianie rewizji w czasie kontroli. Sprawdza 404 usuniętych
  adresów i 200 Hosting. Generator manifestów kopiuje narzędzie do katalogu wydania.
- Nie wykonywać równoległych wdrożeń ani odtwarzać dawnych tagów. Stare wydania
  Hosting przestają mieć działające przypięcia API. Nie cofać backendu do obrazu
  sprzed kontroli `AccountAccessVerified`; poprawki wycofywać w nowym, bezpiecznym obrazie.

Tagi są publicznymi drogami do rewizji niezależnie od procentowego podziału
ruchu. Hosting z `pinTag` korzysta właśnie z tagów Cloud Run.
Źródła: [Cloud Run — routing i tagi](https://docs.cloud.google.com/run/docs/rollouts-rollbacks-traffic-migration),
[Firebase Hosting — przypinanie rewizji](https://firebase.google.com/docs/hosting/cloud-run).

## Zmienione pliki i testy

Kod: `backend/src/Sedno.Domain/Models.cs`,
`backend/src/Sedno.Infrastructure/GuestStore.cs`.
Testy backendu: `backend/tests/Sedno.IntegrationTests/ApiTests.cs`, `BackendFixture.cs`.
Wdrożenia: `backend/deploy/firebase/deploy.sh`, `retire_routes.py`,
`tools/prepare_firebase.py`, `tools/tests/test_retire_routes.py`.
Dokumentacja: ten raport, `backend/README.md`, instrukcja wdrożenia,
`docs/README.md`, oznaczenie zadania 1 w `Tasks.md`.

- `dotnet test backend/Sedno.Backend.sln --no-restore --verbosity quiet`:
  98 testów jednostkowych, 63 integracyjne, 38 benchmarków — wszystkie przeszły.
  Integracja korzystała z emulatora Firestore w Dockerze, nie z produkcji.
- Cztery nowe przypadki integracyjne obejmują e-mail/Google oraz brak/false
  nowego pola; sprawdzają blokadę endpointów, ponowne logowanie bez odnowienia
  limitu i trwałą odmowę starego tokenu. Dotychczasowy test niepotwierdzonego
  e-maila także przeszedł.
- `python3 -m unittest discover -s tools/tests -q`: 13 testów — wszystkie przeszły.
- `bash -n backend/deploy/firebase/deploy.sh`, `git diff --check`: poprawne.
- Generator uruchomiony do tymczasowego katalogu: nowe narzędzie skopiowane poprawnie.
- Flutter/Dart bez zmian; nie uruchamiano testów mobilnych ani budowy APK.
  Docker i chmura wymagały uruchomienia poza ograniczoną piaskownicą; wykonano je.
