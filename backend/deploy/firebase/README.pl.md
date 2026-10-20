# Serwer w Firebase i Google Cloud — Firestore

API: **https://sednoapp-79241-api.web.app**, projekt `sednoapp-79241`, numer
`1003558402460`. Obsługę płatności Google Play włączono do testów 20.10.2026
na istniejącym `sedno-api`; [stan i pozostałe ustawienia](../../../docs/billing-deployment-2026-10-20.pl.md).
Strona `sedno.xyz` jest oddzielna.

**Wdrożono 19.10.2026:** API korzysta z Firestore. Przeniesiono i zweryfikowano
7 dokumentów testowych; kont i zakupów w źródle było 0. Indeksy są gotowe,
a godzinowe sprzątanie działa także przez Cloud Scheduler.

Starą instancję `sedno-postgres` i wszystkie 4 stare kopie **trwale usunięto
19.10.2026**, po jednoznacznej zgodzie właściciela. Przed usunięciem instancji
potwierdzono pustą listę kopii, a po usunięciu — pustą listę instancji SQL projektu.
Nie utworzono nowej ani końcowej kopii.
[Raport wdrożenia](../../../docs/archiwum/firestore-deployment-2026-10-19.pl.md).

## Działające zasoby

| Element | Konfiguracja |
| --- | --- |
| Region API i bazy | `europe-central2` — Warszawa |
| Baza | Cloud Firestore Standard, Native mode, `(default)` |
| Cloud Run | `sedno-api`, 1 CPU, 512 MiB, 0–3 instancje, współbieżność 20, CPU podczas żądań |
| Sprzątanie | Cloud Run Job `sedno-cleanup`, uruchamiany co godzinę przez Cloud Scheduler |
| Hosting API | `sednoapp-79241-api`, HTTPS przekazywane do przypiętej rewizji Cloud Run |
| Obrazy | Artifact Registry `backend` |

Firestore ma darmowe pule, a Blaze rozlicza nadwyżki. Backupy/PITR i TTL są
odrębnie płatne; te manifesty ich nie włączają. Nie zakładaj zerowego rachunku
całego projektu: obrazy, sekrety, Cloud Build, zadania, transfer i AI mają własne
zasady. Ustaw alerty rozliczeń; alert nie jest automatycznym limitem wydatków.

## Przygotowanie projektu

1. Utwórz bazę `(default)` w Firestore **Standard / Native mode** w Warszawie.
   Najpierw sprawdź istniejące bazy i region — nie twórz drugiej bazy zamiast
   ponownego użycia właściwej. Ta konfiguracja korzysta z jednej bazy.
2. Włącz Firestore API i Cloud Scheduler API (pozostałe API są opisane w historycznym wdrożeniu).
3. Nadaj kontu `sedno-api@sednoapp-79241.iam.gserviceaccount.com`
   `roles/datastore.user` z warunkiem
   `resource.name=="projects/sednoapp-79241/databases/(default)"`, zachowując jego dostęp do Secret Manager,
   `firebaseauth.users.get/delete`, Service Usage i pozostałych integracji Google.
   Dostęp serwera do Firestore jest kontrolowany przez IAM, nie Security Rules.
4. Przygotuj konto `sedno-scheduler@sednoapp-79241.iam.gserviceaccount.com`.
   Nadaj mu `roles/run.invoker` na zadaniu `sedno-cleanup` po jego utworzeniu
   (można wcześniej utworzyć zadanie z `cleanup.json`). Wdrażający musi mieć
   prawo `iam.serviceAccounts.actAs` do tego konta. Scheduler używa tokenu OAuth
   do Google Run Admin API; jego agent usługi musi zachować rolę Cloud Scheduler Service Agent.
5. Wdróż reguły i indeksy z tego katalogu. Reguły blokują cały dostęp SDK klientów;
   nie dodawaj biblioteki Firestore do Fluttera. Sprawdź, czy wszystkie indeksy
   są `READY` przed wysłaniem ruchu — publikacja konfiguracji nie czeka na ich zbudowanie.

## Migracja działającego PostgreSQL

Przygotuj i przećwicz te kroki na odrębnej bazie testowej. Migracja wymaga krótkiej
przerwy; nie wykonujemy podwójnego zapisu do dwóch baz.

1. Zachowaj stary obraz, wydanie Hosting i konfigurację. Zasady zachowania SQL
   i ewentualnej kopii ustal przed migracją. W migracji z 19.10.2026 właściciel
   wyraźnie zrezygnował z nowego backupu, ponieważ nie było kont użytkowników. Zapisz
   dokładny digest starego obrazu. Zachowaj wersje kluczy sesji, fingerprintów i
   Data Protection. Nie losuj kluczy ponownie.
2. Przygotuj połączenie tylko do odczytu ze źródłem (np. przez Cloud SQL Auth Proxy).
   Ustaw `SEDNO_MIGRATION_POSTGRES` bez zapisywania hasła w Git, historii poleceń
   lub raporcie. Narzędzie nie wypisuje rekordów, tokenów ani połączenia.
3. Z katalogu głównego uruchom analizę — bez zapisu do Firestore:

   ```sh
   dotnet run --project backend/tools/Sedno.FirestoreMigration
   ```

4. Zatrzymaj dostęp do starego API **zarówno przez Hosting, jak i bezpośredni Cloud Run**,
   zatrzymaj jego zadania i dopływ RTDN (wiadomości muszą pozostać do ponowienia).
   Poczekaj na zakończenie żądań. Samo ustawienie minimum instancji na zero nie
   zatrzymuje przyjmowania ruchu. Docelowy backend również nie może jeszcze przyjmować zapisów.
5. Używając ADC z uprawnieniami do docelowego Firestore, uruchom:

   ```sh
   export Firestore__ProjectId=sednoapp-79241
   dotnet run --project backend/tools/Sedno.FirestoreMigration -- --apply --source-stopped
   ```

   Import zachowuje identyfikatory kont/instalacji/sesji, skróty poświadczeń,
   zaszyfrowane zakupy i powiadomienia; odtwarza liczniki z metadanych żądań.
   Nie zmienia źródła. Działa wyłącznie na pustym celu lub wznawia przerwany import
   identycznego źródła. Sprawdza zapisane dokumenty. Produkcyjny `Firestore:RequireMigration=true` blokuje gotowość API i cleanup
   także przed rozpoczęciem importu, dopóki nie ma markera zakończenia migracji. Po sukcesie ponowny import jest zabroniony.
   `--source-stopped` to potwierdzenie operatora, nie automatyczna blokada starego serwera.
6. Zbuduj i wdróż nowy obraz, uruchom cleanup, sprawdź gotowość, istniejące sesje,
   limity przed/po logowaniu, usuwanie konta i ewentualne zakupy. Odtwórz dopływ RTDN.
7. Po odbiorze zaplanuj wycofanie `sedno-migrate`, dostępu Cloud SQL Client,
   sekretów SQL i instancji `sedno-postgres`. **Skrypty nie usuwają tych zasobów.**
   Samo zatrzymanie SQL nie musi usuwać opłat za dysk i backupy. Ustal czas
   zachowania kopii, zanim usuniesz źródło. Sprawdź również stare, otagowane rewizje
   Cloud Run: mogą nadal utrzymywać minimum jednej instancji. Po okresie wycofania
   zmiany usuń zbędne przypięcia lub skoryguj konfigurację, aby zakończyć ten koszt.

Próba lokalna importu używa `--emulator` i `FIRESTORE_EMULATOR_HOST` z odrębnym
projektem `demo-*`. Nie używaj danych użytkowników do testów.

Wycofanie: przed dopuszczeniem zapisów do nowej bazy można wrócić do starego API
z nienaruszonym SQL. **Po nowych zapisach w Firestore proste przełączenie obrazu
utraci nowe sesje i wykorzystanie limitów** — zatrzymaj ruch i uzgodnij dane przed
powrotem. Nie ma automatycznego migratora wstecznego.

## Budowa i wdrożenie

Z katalogu głównego, po przygotowaniu bazy, IAM i zakończeniu importu:

```sh
gcloud builds submit --project sednoapp-79241 --billing-project sednoapp-79241 \
  --region europe-central2 \
  --service-account projects/sednoapp-79241/serviceAccounts/sedno-build@sednoapp-79241.iam.gserviceaccount.com \
  --config backend/deploy/firebase/cloudbuild.yaml \
  --substitutions _IMAGE=europe-central2-docker.pkg.dev/sednoapp-79241/backend/api:NOWY_TAG .
python3 tools/prepare_firebase.py \
  --project sednoapp-79241 --region europe-central2 --site sednoapp-79241-api \
  --image europe-central2-docker.pkg.dev/sednoapp-79241/backend/api@sha256:DIGEST_OBRAZU \
  --google-credentials cloud-run --billing-product subscription_full \
  --push-email sedno-billing-push@sednoapp-79241.iam.gserviceaccount.com \
  --output backend/deploy/generated
```

Przejrzyj `service.json`, `cleanup.json`, `firebase.json` oraz reguły i indeksy.
Pierwsza konfiguracja wymaga utworzenia zadania cleanup i nadania kontu Scheduler
uprawnienia do jego uruchamiania. Po gotowości indeksów:

```sh
cd backend/deploy/generated
bash deploy.sh
```

Skrypt wykonuje cleanup, zakłada/aktualizuje harmonogram `0 * * * *` UTC, wdraża
API i Hosting oraz sprawdza publiczne `/health/ready`. Nie importuje danych SQL,
nie tworzy bazy i nie usuwa starego SQL. Zadanie cleanup ma pełną obsługę retencji
bez klucza OpenAI i sekretów zakupów. Sprawdź jego wykonania oraz alerty o błędach;
przy awarii harmonogramu wygasłe sesje/rezerwacje nadal są odrzucane w odczycie,
ale fizyczne usuwanie metadanych wymaga naprawy zadania.

Sekrety API: `sedno-credential-key`, `sedno-fingerprint-key`, `sedno-openai-key`.
Przy włączonych płatnościach dochodzi `sedno-billing-keyring`. Manifesty przypinają
wersje sekretów; zachowaj działające wersje z poprzedniego wdrożenia.

## Prywatność, kopie i odbiór

Politykę przygotowaną dla Firestore publikuj wraz z migracją; osobna domena
`sedno.xyz` wymaga [aktualizacji HTML](../../../docs/public/README.pl.md).
Godzinowy cleanup usuwa metadane żądań i liczniki po 8 dniach, wygasłe sesje oraz
niepowiązane tożsamości gości po 90 dniach, gdy nie mają sesji ani żądań.
Przerwane usuwanie kont jest wznawiane, również po błędzie lub timeoutcie Firebase;
konto oczekujące na usunięcie nie przyjmuje nowych uproszczeń ani zakupów. Wszystkie kolekcje są płaskie; usunięcie
konta jawnie usuwa dokumenty potomne oraz jego wkład we wspólne liczniki.

**Firestore nie dziedziczy kopii SQL.** Manifesty nie włączają backupów ani PITR.
Właściciel zrezygnował z backupów na obecnym etapie (19.10.2026, brak kont).
Nie ma automatycznego odtworzenia nowej bazy z kopii. Jeśli ta decyzja się zmieni,
skonfiguruj kopie z retencją do 30 dni i przećwicz odtworzenie oraz ponowne
zastosowanie usunięć. Nie włączaj płatnych kopii ani PITR bez zmiany tej decyzji.

Przed większym ruchem zmierz operacje Firestore i koszty Cloud Run oraz sprawdź
limit IP za proxy. Przed publikacją pozostają [próby Google Play](../../../mobile/docs/google_play_internal_test.md).
Historyczne wdrożenie SQL: [raport z 19.10.2026](../../../docs/archiwum/task-14-deployment.pl.md).
