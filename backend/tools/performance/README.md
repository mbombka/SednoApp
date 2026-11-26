# Pomiary backendu Sedno

[Raport z 26.11.2026](../../../docs/backend-performance-2026-11-26.pl.md) opisuje wyniki, warunki prób i sposób interpretacji.

## Publikacja wariantów

Z katalogu głównego repozytorium, z .NET 10 SDK i Dockerem na Linux x64.

```bash
work=$(mktemp -d)
for variant in il r2r; do
  ready_to_run=false
  if [ "$variant" = r2r ]; then ready_to_run=true; fi
  dotnet publish backend/src/Sedno.Api -c Release -r linux-x64 \
    --self-contained false -p:UseAppHost=false -p:PublishReadyToRun="$ready_to_run" \
    -o "$work/$variant"
done
```

Oba warianty korzystają z tego samego obrazu runtime .NET 10. ReadyToRun pozostawia IL i możliwość JIT. Obraz zachowuje użytkownika bez uprawnień roota i nie włącza trimmingu ani Native AOT.

## Obciążenie i start lokalny

Potrzebny jest dedykowany emulator Firestore na porcie `18781` oraz Python 3.11+ i `taskset`. Przykładowe uruchomienie emulatora w osobnym terminalu.

```bash
docker run --rm --name sedno-perf-firestore -p 127.0.0.1:18781:8080 \
  gcr.io/google.com/cloudsdktool/google-cloud-cli:emulators \
  gcloud emulators firestore start --host-port=0.0.0.0:8080 --quiet
```

```bash
python3 backend/tools/performance/local.py load \
  --dll "$work/il/Sedno.Api.dll" --output "$work/load.json"
python3 backend/tools/performance/local.py cold \
  --dll "$work/il/Sedno.Api.dll" --r2r "$work/r2r/Sedno.Api.dll" \
  --trials 30 --output "$work/cold-local.json"
```

Narzędzie uruchamia własny proces na loopbacku w trybie Development, z jednym logicznym CPU, losowymi kluczami i oddzielnym projektem emulatora. Korzysta z istniejącego mocka modelu i mocka Play Integrity. Przed pomiarami tworzy sesje gości. Identyfikatory instalacji są różne, a każda sesja zużywa do pięciu użyć. W próbie obciążenia klient najpierw otwiera TCP, potem zwalnia wspólną blokadę dla wszystkich kliknięć. JSON zawiera rzeczywisty rozrzut wysłania, czasy HTTP, czasy etapów z logów oraz statusy. Lokalny test startu uruchamia nowy proces dla każdej próby, odpytuje `/health/ready` i wykonuje pierwsze uproszczenie po założeniu sesji. Warianty mają naprzemienną kolejność.

## Cloud Run

Użyj oddzielnych prywatnych usług, lokalizacji `europe-central2` i istniejącego repozytorium Artifact Registry. Ustaw `SEDNO_PERF_PROJECT` na identyfikator projektu i `SEDNO_PERF_RUN` na unikalną nazwę eksperymentu zgodną z parametrem `--run-id`. Przykład zakłada repozytorium `backend`. Konto runtime służy wyłącznie do pomiarów i nie potrzebuje ról projektowych.

```bash
region=europe-central2
registry="$region-docker.pkg.dev/$SEDNO_PERF_PROJECT/backend"
gcloud auth configure-docker "$region-docker.pkg.dev"
gcloud iam service-accounts create "sedno-perf-$SEDNO_PERF_RUN" \
  --project "$SEDNO_PERF_PROJECT"
for variant in il r2r; do
  image="$registry/sedno-perf-$SEDNO_PERF_RUN:$variant"
  docker build --platform linux/amd64 -f backend/tools/performance/Dockerfile \
    -t "$image" "$work/$variant"
  docker push "$image"
done

python3 backend/tools/performance/cloud.py --project "$SEDNO_PERF_PROJECT" \
  --run-id "$SEDNO_PERF_RUN" --tagged-trials --trials 30 --output "$work/cloud.json"
python3 backend/tools/performance/cloud.py --project "$SEDNO_PERF_PROJECT" \
  --run-id "$SEDNO_PERF_RUN" --probe-period 1 --tagged-trials --trials 30 \
  --output "$work/cloud-p1.json"
```

Narzędzie używa tokenu tożsamości zalogowanego operatora. Operator potrzebuje uprawnień do wdrażania, wywoływania usług i czytania logów. Usługi zachowują `concurrency=80`, 1 vCPU, 512 MiB i automatyczne skalowanie 0–1. Maksimum 1 pozwala przypisać próbę do jednej instancji. Każda próba tworzy nową rewizję bez testu gotowości podczas wdrożenia i wykonuje dwie próby HTTP przez TLS. Produkcyjne uruchomienie aplikacji zachowuje kontrolę IAM, korzysta z `/health/live` i nie odwołuje się do Firestore ani do dostawcy AI. W próbach tagowanych po pierwszym wdrożeniu kolejne wywołania trafiają na własne adresy rewizji bez domyślnego ruchu.

`--verify-only` ponownie dopasowuje zebrane próby do logów platformy. Użyj go po pojawieniu się opóźnionych wpisów. `start_to_probe_ms` jest różnicą między logiem startu instancji i logiem powodzenia próbnika. `requested_start_client_ms` uwzględnia próby, w których instancja uruchomiła się po nadejściu żądania, z tolerancją 250 ms na znaczniki czasu. `warm_client_ms` uwzględnia drugą odpowiedź na tej samej instancji. Czas klienta zaczyna się po zestawieniu TLS.

Po zapisaniu wyników usuń utworzone na potrzeby pomiaru usługi, obrazy i dedykowane konto runtime. Dane w JSON zawierają wyłącznie czasy, kody odpowiedzi i metadane prób.

## Pomiar etapów startu Sedna i Go

[Wyniki pomiaru etapów](../../../docs/backend-startup-phases-2026-11-26.pl.md)

`phases/stage.py` tworzy osobny katalog budowania i dodaje znaczniki czasu wyłącznie do kopii `Program.cs`. Obraz zawiera aplikację Sedno i statyczny program Go. Tryb `sedno` zapisuje początek wykonania i przekazuje proces do `dotnet`. Tryb `go` uruchamia mały serwer, który zwraca `200 OK` na `/health/live`.

```bash
phase_context=$(mktemp -d)
python3 backend/tools/performance/phases/stage.py "$phase_context"
docker build --platform linux/amd64 -t sedno-phases:local "$phase_context"
bash backend/tools/performance/phases/readiness-local.sh sedno-phases:local 30 > firestore-local.json
```

Użyj dedykowanego konta runtime i unikalnego `SEDNO_PERF_RUN` zgodnie z wcześniejszą instrukcją. Prześlij jeden obraz do `$registry/sedno-perf-$SEDNO_PERF_RUN:measure`. Ustaw `SEDNO_PHASE_IMAGE` na tę samą ścieżkę pakietu z `@sha256:<digest>` zamiast tagu. Obie usługi w każdej serii pobiorą dokładnie ten sam obraz.

```bash
for period in 1 5; do
  python3 backend/tools/performance/cloud.py --project "$SEDNO_PERF_PROJECT" \
    --run-id "$SEDNO_PERF_RUN" --phase-timing-image "$SEDNO_PHASE_IMAGE" \
    --probe-period "$period" --tagged-trials --trials 30 \
    --output "phases-p$period.json"
done
```

Przy opóźnionym dostarczeniu logów ponów polecenie z `--verify-only`. Sprawdź, czy `requested_start_count` oraz licznik `n` przy pomiarach etapów wynoszą co najmniej 30 w każdej serii. Skrypt zapisuje różnice czasów z logów tej samej instancji. Po pomiarach usuń cztery prywatne usługi testowe, pakiet obrazu i konto runtime.

## Pierwsze uproszczenie po starcie kontenera

Porównanie uruchamia nowy, lokalny kontener Sedna dla każdej próby. Klient tworzy sesje gości wcześniej w oddzielnym kontenerze. Przy starcie mierzonej instancji skrypt symuluje żądanie oczekujące na gotowość. Po dopuszczeniu ruchu wywołuje `POST /v1/simplifications` z istniejącą sesją i sprawdza, czy odpowiedź zawiera wynik. Zapisuje czas od startu kontenera do dopuszczenia żądania, czas samej odpowiedzi API i status.

W pierwszym wariancie skrypt odpytuje `/health/ready` co 5 s z limitem 2 s na próbę. W drugim wysyła żądanie po lokalnym wykryciu otwartego portu TCP. Test używa Dockera na Linuksie, wydzielonego emulatora Firestore i testowego modelu w trybie Development. Lokalny test portu sprawdza go co 10 ms, więc jego wynik nie określa czasu domyślnego próbnika TCP w Cloud Run.

```bash
python3 backend/tools/performance/cold_simplification.py \
  --image sedno-phases:local --trials 30 \
  --output cold-simplification-local.json
```

Opcja `--check-unavailable` dodaje po jednej próbie dla obu wariantów po zatrzymaniu wydzielonego emulatora. Lokalny skrypt zgłasza brak gotowości, jeśli próbnik HTTP nie dopuści żądania w swoim oknie prób.

[Wyniki wszystkich prób](results/2026-11-26-cold-simplification-local.json)
