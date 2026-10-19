# Firestore — wdrożenie 19.10.2026

Produkcję przełączono na Cloud Firestore Standard / Native mode, `(default)`,
`europe-central2` (Warszawa). Publiczny adres pozostaje bez zmian:
`https://sednoapp-79241-api.web.app`.

## Źródło i import

Właściciel zrezygnował z nowego backupu, wskazując brak zarejestrowanych użytkowników.
Odczyt źródła potwierdził: 0 kont, 1 instalacja, 1 sesja, 4 metadane żądań,
0 zakupów i 0 powiadomień. Po zablokowaniu publicznego ruchu, ograniczeniu ingress
oraz oczekiwaniu na zakończenie żądań wykonano import narzędziem
`Sedno.FirestoreMigration`. Zapisano i porównano 7 dokumentów, w tym dzienny licznik.
Nie eksportowano treści ani wyników. Nie wymieniano kluczy sesji i fingerprintów.

Do jednorazowego połączenia użyto lokalnego Cloud SQL Auth Proxy z tożsamością
gcloud i hasłem pobranym z Secret Manager tylko do pamięci procesu. Firestore
uwierzytelniono krótkotrwałym tokenem operatora, bez tworzenia pliku klucza.
Narzędzie obsługuje opcjonalne `SEDNO_MIGRATION_PROXY_PORT` oraz
`SEDNO_MIGRATION_ACCESS_TOKEN`; wartości poświadczeń nie należy zapisywać w Git,
historii poleceń ani raportach. Tunel zamknięto po migracji.

## Wydanie

- Cloud Build: `2213c24f-b132-4beb-986f-af47bcb589c3`, SUCCESS.
- Obraz: `europe-central2-docker.pkg.dev/sednoapp-79241/backend/api@sha256:bf822af4e9301f12e1b7ff3521d885786501e0c87fdea0c64dc548146c6d843f`.
- Rewizja API: `sedno-api-00003-xlh`, 100% ruchu.
- Firebase Hosting: wersja `4e0714a3b37bec42`, tag `fh-4e0714a3b37bec42`.
- Cloud Run: 0–3 instancje, 1 CPU, 512 MiB, CPU podczas żądań; brak połączenia Cloud SQL.
- Płatności nadal wyłączone; produkcyjny provider AI i ustawienia modelu bez zmian.

## Firestore i harmonogram

Reguły blokują odczyt/zapis klientom. Konto backendu ma `roles/datastore.user`
z warunkiem ograniczającym zasób do
`projects/sednoapp-79241/databases/(default)`. Początkowe nadanie roli bez warunku
odrzucono w automatycznej kontroli; wdrożono zawężony wariant.

Oba indeksy (`guest_sessions`: IdentityId/AccountId;
`play_purchases`: AccountId/Revoked) osiągnęły stan READY.

Zadanie `sedno-cleanup` ma te same uprawnienia do bazy co API. Cloud Scheduler
uruchamia je według `0 * * * *`, UTC. Osobne konto `sedno-scheduler` otrzymało
wyłącznie `roles/run.invoker` na tym zadaniu, bez roli na poziomie projektu.

Potwierdzone udane wykonania:

- Ręczne: `sedno-cleanup-22ps7`, zakończone 12:16:57 UTC.
- Przez Cloud Scheduler: `sedno-cleanup-q8s2m`, zakończone 12:20:21 UTC.

Nie włączono backupów, PITR ani TTL Firestore. Bez kopii nie ma automatycznego
odtworzenia danych po ich utracie; jest to decyzja właściciela na obecnym etapie.

## Weryfikacja

- Kontrola gotowości nowej rewizji i publicznego adresu: `/health/ready` i
  `/health/live` zwracają 200.
- `/prywatnosc` zwraca 200 i zawiera opis Firestore.
- `/v1/quota` bez sesji zwraca 401.
- Anonimowy odczyt `guest_sessions` bezpośrednio z Firestore zwraca 403.
- Sprzątanie wykonane pomyślnie ręcznie i przez Scheduler — potwierdzone IAM i zapytania.
- Po zmianie obsługi poświadczeń migratora: 3 testy integracyjne migracji przeszły.
- Pełną ścieżkę telefonu z Play Integrity, logowaniem i AI trzeba nadal sprawdzić
  według instrukcji Google Play. Nie wykonywano płatnego wywołania modelu w tej operacji.

## Wycofanie SQL i ograniczenia

Początkowo instancję `sedno-postgres` zatrzymano z zachowaną ochroną usunięcia.
Automatyczna kontrola odrzuciła usuwanie bez jednoznacznej zgody na konkretną
instancję i kopie. Nie obchodzono blokady. Następnie właściciel wyraźnie zatwierdził
trwałe usunięcie instancji i wszystkich czterech kopii, bez możliwości odzyskania.

19.10.2026 usunięto kolejno kopie `1792375200000`, `1792288800000`,
`1792202400000`, `1792172438455`. Potwierdzono pustą listę kopii (`[]`).
Wyłączono ochronę usunięcia, zachowanie kopii po usunięciu i tworzenie końcowej
kopii. Usunięcie instancji zakończyło się powodzeniem; lista instancji SQL
projektu `sednoapp-79241` jest pusta (`[]`). Nie wykonano nowej ani końcowej kopii.
Po usunięciu ponownie sprawdzono publiczne API: gotowość i żywotność HTTP 200,
a `/v1/quota` bez sesji HTTP 401.

Sekrety połączeń SQL pozostawiono; nie są używane przez bieżące API ani zadanie
sprzątania. Ich usuwanie nie było częścią tej operacji.

Usunięto zadanie `sedno-migrate` i dwie nieużywane rewizje SQL
`sedno-api-00001-ll4`, `sedno-api-00002-cc7`. Odebrano kontu backendu
`roles/cloudsql.client`; stare obrazy pozostają w rejestrze.

Politykę wdrożono przy API. Osobna domena `sedno.xyz` nie jest aktualizowana przez
wdrożenie API; publikacja przygotowanych plików HTML pozostaje osobnym zadaniem.
Nie budowano nowego APK ani AAB.
