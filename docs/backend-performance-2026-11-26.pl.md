# Wydajność backendu i cold start Sedna

**Wniosek na 26.11.2026.** Cel około 1 s wymaga dalszej walidacji. Utrzymałbym jedną ciepłą instancję, dopóki krótszy próbnik nie zostanie sprawdzony także z prawdziwym Firestore.

## Zakres i punkt odniesienia

26.11.2026 produkcyjna rewizja `sedno-api-00016-ll9` obsługiwała cały ruch w `europe-central2`. Usługa miała minimum **1** i maksimum 20 na poziomie usługi, a rewizja minimum 0 i maksimum 3. Kontener miał 1 vCPU, 512 MiB, `concurrency=80`, rozliczanie na podstawie żądań oraz próbnik `/health/ready` co 5 s z timeoutem 2 s. Konfigurację i logi produkcyjne odczytano bez generowania ruchu testowego.

W istniejących logach aktualnej rewizji z siedmiu dni były dwa udane uproszczenia z podziałem na etapy. Cała obsługa w backendzie zajęła **4,81 s** i **7,20 s**. Etap modelu zajął odpowiednio **4,40 s** i **6,73 s**, a reszta ścieżki około **0,42 s** i **0,47 s**. To dwie obserwacje działania rzeczywistej ścieżki. Osobno trzy automatyczne uzupełnienia minimum instancji przeszły produkcyjny próbnik gotowości za drugim podejściem. Czas od logu rozpoczęcia instancji do gotowości wyniósł 6,58–6,75 s, z medianą 6,64 s.

Eksperyment oparto na kodzie `25d2ad9` i .NET 10 SDK 10.0.115. Kod aplikacji, konfiguracja produkcyjna i mechanizmy bezpieczeństwa zachowały obecny stan. Warianty Cloud Run działały na dwóch osobnych usługach na każde ustawienie próbnika, dostępnych przez IAM, z dedykowanym kontem bez ról projektowych, bez udostępniania ich przez Firebase Hosting. Wykorzystywały własne obrazy, testowe klucze, wyłączony model i konfigurację Firestore wskazującą projekt testowy, bez połączeń z Firestore. Prywatny wariant mierzył gotowość procesu na `/health/live`. Lokalna próba `/health/ready` osobno obejmowała połączenie z emulatorem. Po pomiarach usunąłem cztery usługi testowe, pakiet obrazów i dedykowane konto runtime oraz zatrzymałem lokalny emulator.

## Obciążenie ciepłego backendu

Wykonałem po 10 fal dla 1, 10, 100 i 1000 użytkowników, łącznie 11 110 żądań. Każdy użytkownik w danej fali miał własną przygotowaną wcześniej sesję. Test korzystał z jednego rozgrzanego procesu Kestrel z jednym logicznym CPU na Linux x64, emulatora Firestore i synchronicznego mocka modelu. Po nawiązaniu połączeń TCP klient zwalniał wspólną blokadę. Maksymalny czas od zwolnienia blokady do wysłania ostatniego żądania wyniósł 13 ms dla 100 użytkowników i 120 ms dla 1000. Serie uporządkowałem od najmniejszej fali, po przeciążeniu widocznym między falami w próbie wstępnej. Przy 1000 użytkowników między falami była przerwa 5 s.

| Użytkownicy w fali | Sukcesy | Średni czas backendu | Mediana backendu | P95 backendu | P95 czasu klienta |
| ---: | ---: | ---: | ---: | ---: | ---: |
| 1 | 10 / 10 | 0,08 s | 0,06 s | 0,12 s | 0,12 s |
| 10 | 100 / 100 | 0,23 s | 0,22 s | 0,29 s | 0,30 s |
| 100 | 1000 / 1000 | 1,24 s | 1,18 s | 1,92 s | 1,95 s |
| 1000 | 0 / 10000 | 11,22 s | 10,06 s | 16,04 s | 16,30 s |

Czas backendu pochodzi z `TotalMs` w logach Sedna. Czas klienta zaczyna się tuż przed wysłaniem żądania i kończy po odebraniu treści. Statystyki uwzględniają wszystkie odpowiedzi. Przy 1000 użytkowników wszystkie liczby opisują odpowiedzi błędów, w tym **9161 HTTP 504** i **839 HTTP 500**. W kodzie obowiązuje 9-sekundowy limit ścieżki uproszczenia. Pod przeciążeniem faktyczne czasy odesłania błędów przekraczały ten limit. Przy 100 użytkownikach mediany rezerwacji i zakończenia operacji wyniosły odpowiednio 471 i 456 ms, a uwierzytelnienia 97 ms.

Test lokalny przepuszczał wszystkie połączenia bezpośrednio do jednej instancji, zatem mierzy zachowanie tego backendu i emulatora przy nagłym napływie żądań. W Cloud Run część żądań czekałaby na dostępne miejsce lub dodatkową instancję przy limicie 80 na instancję. Zdolność produkcji do obsłużenia 1000 kliknięć pozostaje poza wynikiem tego testu. [Wszystkie 40 fal i etapy backendu](../backend/tools/performance/results/2026-11-26-load.json)

## Cold start w prywatnym Cloud Run

Usługi testowe miały `min=0`, `max=1`, `concurrency=80`, 1 vCPU i 512 MiB. Zestawiłem IL bez Boost z ReadyToRun i Startup CPU Boost na tym samym obrazie bazowym. Najpierw ruch był przełączany na nową rewizję, co często rozpoczynało skalowanie jeszcze przed żądaniem. Główna tabela używa prób z potwierdzonym startem po nadejściu żądania. W tych próbach nowa rewizja miała własny adres dla pojedynczej serii, a log `AUTOSCALING` potwierdzał nową instancję. Kolejne wywołanie pozwoliło zmierzyć odpowiedź tej samej, ciepłej instancji.

| Odstęp próbnika | Wariant | Próby | Start → udany próbnik p50 / P95 | Pierwsza odpowiedź HTTP p50 / P95 | Ciepłe HTTP p50 / P95 |
| --- | --- | ---: | ---: | ---: | ---: |
| 5 s | IL, Boost wył. | 30 | 5,41 s / 5,57 s | 5,49 s / 5,64 s | 36 ms / 42 ms |
| 5 s | R2R + Boost | 30 | 5,41 s / 5,65 s | 5,47 s / 5,72 s | 35 ms / 42 ms |
| 1 s | IL, Boost wył. | 30 | 2,41 s / 2,65 s | 2,49 s / 2,74 s | 35 ms / 71 ms |
| 1 s | R2R + Boost | 30 | 2,38 s / 2,63 s | 2,46 s / 2,74 s | 38 ms / 234 ms |

Czas HTTP obejmuje oczekiwanie na skalowanie i odpowiedź `/health/live`, od wysłania żądania po zestawieniu TLS. Czas platformy pochodzi z pary logów startu instancji i pozytywnego wyniku próbnika. Wariant 1 s korzystał z timeoutu 1 s i podniesionego progu niepowodzeń, dzięki czemu całkowite okno na gotowość pozostało 120 s. Próbnik 5 s przechodził za drugim podejściem we wszystkich 60 próbach z tabeli. Skrócenie okresu dało największą poprawę. W granicach tej próby połączenie R2R i Boost miało niewielki wpływ na odpowiedź HTTP przy tym samym okresie próbnika. W wariancie 1 s p50 pierwszej odpowiedzi wyniosło około 2,5 s. Dla ciepłych wywołań tego wariantu P95 z logów Cloud Run wyniósł 4,4 ms z IL i 10,2 ms z R2R + Boost. P95 zaobserwowany przez klienta obejmuje dodatkowe opóźnienie poza czasem zarejestrowanym przez platformę. P95 we wszystkich tabelach obliczono metodą najbliższej rangi.

[Pomiary Cloud Run, próbnik 5 s](../backend/tools/performance/results/2026-11-26-cloud-p5.json) · [Pomiary Cloud Run, próbnik 1 s](../backend/tools/performance/results/2026-11-26-cloud-p1.json)

## Start lokalny z gotowością Firestore

Uruchomiłem po 30 świeżych procesów na wariant, naprzemiennie, na tym samym hoście i z gotowym emulatorem. Czas startu biegnie od uruchomienia procesu do HTTP 200 z `/health/ready`. Obie wersje po założeniu sesji wykonały pierwsze uproszczenie z mockiem. Poniższa próba mierzy wpływ samego ReadyToRun, ponieważ Startup CPU Boost działa tylko w Cloud Run.

| Wariant | Procesy | Start → gotowość p50 / P95 | Pierwsze uproszczenie w backendzie p50 / P95 |
| --- | ---: | ---: | ---: |
| IL | 30 | 1,94 s / 2,47 s | 354 ms / 473 ms |
| ReadyToRun | 30 | 1,50 s / 1,88 s | 325 ms / 463 ms |

[Próbki lokalnych startów](../backend/tools/performance/results/2026-11-26-cold-local.json) · [Uruchomienie testów](../backend/tools/performance/README.md)

## Koszty

Przy rozliczaniu za żądania minimum 0 usuwa opłatę za utrzymywanie instancji w bezczynności. Dla 30 dób, 1 vCPU, 0,5 GiB i stawki referencyjnej 0,0000025 USD za każdą vCPU-s i GiB-s bezczynnej instancji daje to **9,72 USD za cały miesiąc bezczynności** przed darmowym limitem i upustami. Faktyczna oszczędność zależy od czasu bezczynności, rozliczanych SKU i darmowego limitu. Odczyt katalogu Billing API zwrócił 403, dlatego szacunek korzysta ze stawek referencyjnych, bez danych z faktury. [Cennik Cloud Run](https://cloud.google.com/run/pricing)

Przy bazowym 1 vCPU Startup CPU Boost przydziela 2 vCPU w czasie startu oraz na 10 s po starcie. Dla przykładowych 2 s startu to nominalnie 24 vCPU-s w oknie boost. Przy 0,000024 USD za vCPU-s aktywności to około **0,58 USD za 1000 takich okien CPU** przed rabatami i darmowym limitem. Do porównania netto trzeba odjąć CPU wariantu bazowego i uwzględnić czas rozliczany po zakończeniu żądań, pamięć, liczbę startów i rzeczywiste stawki. Uproszczenia uruchamiają te same operacje Firestore i dostawcy modelu. [Startup CPU Boost i jego rozliczanie](https://docs.cloud.google.com/run/docs/configuring/services/cpu) · [Cennik Cloud Run](https://cloud.google.com/run/pricing)

## Kompatybilność i bezpieczeństwo

- Oba obrazy korzystają z tego samego przypiętego runtime ASP.NET 10.0.15 na Linux x64. Publikacja pozostaje zależna od frameworka, bez trimmingu i z dostępnym JIT. Payload publikacji urósł z 6,70 MB do 12,26 MB, a lokalny rozmiar obrazu z 354,85 MB do 363,05 MB według `docker image inspect`. Większe pliki mogą mieć znaczenie przy pobieraniu obrazu i innych architekturach, które wymagają osobnej publikacji. [Dokumentacja ReadyToRun](https://learn.microsoft.com/dotnet/core/deploying/ready-to-run)
- Prywatny wariant Cloud Run odrzucił żądanie bez poświadczeń IAM kodem 403. Po uwierzytelnieniu IAM endpoint `/v1/quota` zwrócił 401 dla żądania bez sesji Sedno.
- Testowy obraz R2R uruchomił się lokalnie w trybie Production z testowym pierścieniem kluczy Billing zamontowanym tylko do odczytu. `/health/live` zwrócił 200, a `/v1/quota` bez sesji zwrócił 401. Zakres próby obejmował uruchomienie z testowym kluczem i kontrolę dostępu.
- `dotnet test backend/Sedno.Backend.sln --no-restore -v minimal` zakończył się powodzeniem. Przeszło 135 testów jednostkowych, 113 integracyjnych i 38 testów narzędzia modelowego. Skrypty Python przeszły sprawdzenie składni i zostały użyte do pomiarów.

## Decyzja wdrożeniowa

Jeśli celem dla użytkownika jest około 1 s po zejściu do zera, utrzymałbym dziś `min=1`. Największą poprawę w eksperymencie dało skrócenie odstępu próbnika. Przed decyzją o `min=0` powtórzyłbym próbę na prywatnej usłudze z rzeczywistym odczytem jej własnego Firestore na `/health/ready` i z testowym pierścieniem Billing. Porównałbym najpierw `periodSeconds=1` i `periodSeconds=2` bez Boost. Przy okresie 1 s timeout próbnika też wynosi 1 s. Krótszy timeout musi dawać wystarczająco dużo czasu na weryfikację Firestore. Po potwierdzeniu gotowości i kosztów skoków ruchu można zdecydować o `min=0` bez zmiany kontroli dostępu i logiki Sedna. [Próbniki Cloud Run](https://docs.cloud.google.com/run/docs/configuring/healthchecks) · [Minimalna liczba instancji](https://docs.cloud.google.com/run/docs/configuring/min-instances)
