# Ograniczanie ruchu przez Hosting i Cloud Run — 21.10.2026

Poprawka jest przygotowana lokalnie, bez wdrożenia. Zachowuje Firebase Hosting,
publiczny Cloud Run i istniejącą bazę. Właściciel zaakceptował wspólny limit
ruchu **przed uzyskaniem sesji** za proxy Hosting. Ważne sesje gości i kont mają
osobne liczniki, niezależnie od drogi dostępu.

## Granica zaufania i identyfikacja

Istnieją dwie drogi do tego samego procesu API:

- bezpośrednio: klient → publiczny frontend Cloud Run → zarządzany transport
  wewnętrzny → Kestrel;
- przez Hosting: klient → CDN/proxy Firebase Hosting → frontend Cloud Run
  przypiętej rewizji → zarządzany transport wewnętrzny → Kestrel.

[Integracja Hosting z Cloud Run](https://firebase.google.com/docs/hosting/cloud-run)
przekazuje żądania do usługi; Hosting nie jest tożsamością klienta.
Adres połączenia `RemoteIpAddress` w kontenerze może wskazywać zarządzany
transport, a nie klienta publicznego API.

Dla ruchu bez ważnej sesji `TrafficLimiting` pobiera wyłącznie **ostatni adres**
z `X-Forwarded-For`, dopisywany na wejściu Cloud Run. Nie usuwa kolejnych
„zaufanych” adresów Google/Fastly i nie próbuje rozpoznać Hosting po liczbie
adresów, `Host`, `X-Forwarded-Host`, `Via` ani `Fastly-Client-IP`. Sam publiczny
adres Cloud Run pozwala wysłać takie same nagłówki. Fastly opisuje wprost, że
[`Fastly-Client-IP` może pochodzić od klienta](https://www.fastly.com/documentation/reference/http/http-headers/Fastly-Client-IP/).
Prefiks `X-Forwarded-For` może zawierać dowolne dane.

Ta reguła dotyczy wyłącznie zarządzanego Cloud Run (`K_SERVICE`, Production),
bez dodatkowego własnego load balancera. Po zmianie topologii trzeba ponownie
zweryfikować sufiks nagłówka; nie zwiększać automatycznie liczby zaufanych hopów.
Brak lub błędny ostatni adres daje wspólny klucz `unknown`. IPv4 i jego zapis
IPv4-mapped IPv6 wskazują ten sam licznik. Poza Cloud Run nagłówki proxy są
ignorowane, a klucz korzysta z `RemoteIpAddress`.

Przez Hosting ostatni zaufany adres oznacza pośrednika Hosting. Kilku klientów
bez sesji może więc dzielić licznik, a jeden klient może trafić na różne adresy
proxy. Jest to świadomie zaakceptowane przybliżenie; nie deklarujemy izolacji
poszczególnych klientów przed sesją przez Hosting. Dotyczy to także tworzenia
sesji przez `/v1/guest-sessions`. Bezpośredni Cloud Run rozdziela ruch według
adresu widzianego na swoim wejściu; użytkownicy jednego NAT dzielą taki adres.

Dla chronionych tras istniejące `IGuestStore.AuthenticateAsync` ustala tożsamość,
a limiter korzysta wyłącznie z wyniku zapisanego wewnętrznie w `HttpContext`:

| Ruch | Klucz licznika publicznego API |
| --- | --- |
| Ważna sesja gościa | `guest:<IdentityId>` |
| Ważna sesja konta | `account:<AccountId>` — wspólny dla sesji tego konta |
| Brak sesji / błędne poświadczenie | `network:<zaufany adres wejścia>` |

Dowolny `Authorization`, identyfikator instalacji ani nagłówek konta nie wybiera
licznika tożsamości. Weryfikacja sesji pozostaje aktualna: bez cache omijającego
wylogowanie, usunięcie konta lub odwołanie dostępu. Brak ważnej sesji przechodzi
przez limiter, a następnie zwraca 401; po wyczerpaniu limitu zwraca 429.

**Koszt uwierzytelnienia:** dla rozdzielenia ważnych sesji od fałszywych istniejąca
weryfikacja odbywa się przed limiterem. Może ona czytać Firestore i sprawdzać
Firebase również dla żądania zakończonego 429. Sam limiter nie rozwiązuje usług
uwierzytelnienia, nie czyta bazy, nie zapisuje liczników w bazie i nie wykonuje
połączeń sieciowych. Nie dodano drugiej weryfikacji sesji. To ograniczenie ruchu
operacji API, a nie ochrona kosztu całego uwierzytelnienia przed DDoS.

## Liczniki i RTDN

`RateLimiting:PermitLimit` (domyślnie **60/min**) jest limitem na klucz publicznego
API **w każdej instancji**. `RateLimiting:NotificationPermitLimit` (domyślnie
**600/min**) jest osobnym, wspólnym licznikiem RTDN w danej instancji.
Wartości muszą być dodatnie. Używamy minutowego stałego okna bez kolejki.
Okna są lokalne, nie są synchronizowane z zegarem UTC ani innymi instancjami;
na granicy okien możliwy jest krótki podwójny zryw.

Przy trzech instancjach łączny limit danego klucza może wynosić około
**3 × 60 = 180 żądań/min**, zależnie od rozdziału ruchu i położenia okien.
Restart, wymiana rewizji lub skalowanie do zera usuwa lokalne liczniki.
Nie ma Firestore, Redis ani zewnętrznego magazynu dla tego mechanizmu.
**Dzienne limity 5/400 nadal są wspólne, transakcyjne w Firestore i resetują się
o 00:00 UTC według czasu serwera.** Ta zmiana ich nie modyfikuje.

Trasę RTDN oznacza metadana endpointu, a nie nagłówek klienta. Dzięki temu również
warianty adresu z końcowym ukośnikiem lub inną wielkością liter mają oddzielny
limit. Wyczerpany licznik publiczny nie blokuje poprawnego RTDN. Kod endpointu
nadal wymaga weryfikacji podpisanego tokenu Pub/Sub, odbiorcy i konta usługi;
fałszywy token nie daje dostępu. Limiter nie zastępuje tej weryfikacji.

## Weryfikacja lokalna

Nowe testy `TrafficLimitingTests` i `TrafficLimitingApiTests` obejmują:

- rozdzielenie klientów bezpośredniego Cloud Run przy wspólnym adresie transportu;
- brak obejścia przez podrobiony prefiks XFF, Fastly, host i token Bearer;
- wspólny licznik przed sesją przez Hosting i ignorowanie XFF poza Cloud Run;
- błędny sufiks, wiele linii XFF oraz normalizację IPv4-mapped IPv6;
- izolację ważnych sesji gości i kont po rzeczywistym przejściu przez pipeline API;
- wspólny licznik kilku sesji tego samego konta;
- osobne liczniki równoległych instancji i puste liczniki po restarcie;
- niezależne, ograniczone liczniki RTDN i publicznego API;
- poprawny testowy RTDN po wyczerpaniu limitu publicznego, nadal 401 dla
  fałszywego tokenu, także przy wariancie trasy z końcowym ukośnikiem.

Testy samego limitera budują aplikację bez zarejestrowanego Firestore i klientów
sieciowych. Testy całego API używają lokalnego emulatora i atrap tożsamości,
AI, zakupów oraz weryfikacji tokenów. Kryptografię Pub/Sub nadal sprawdzają
istniejące `PushAuthenticationTests`.

Końcowe `dotnet test backend/Sedno.Backend.sln --no-restore --verbosity quiet`:
**235/235 zaliczonych**, bez pominiętych: 105 jednostkowych, 92 integracyjne
(w tym 12 nowych) i 38 narzędzia benchmarkowego. `git diff --check` bez błędów.

## Kontrola działających adresów bez obciążania produkcji

21.10.2026 około **08:46 czasu polskiego** odczytano istniejące `sedno-api`
w `europe-central2`: ingress `ALL`, 100% ruchu do `sedno-api-00010-wj5`,
tag Hosting `fh-124b4d67a8c727d4`. Nie zmieniano infrastruktury ani konfiguracji.

Wykonano **łącznie osiem GET**: po dwa adresy × dwa endpointy × wariant bez/z
fałszywym XFF, `Fastly-Client-IP` i `X-Forwarded-Host`.

| Adres | `/health/live` | `/v1/quota` bez sesji |
| --- | --- | --- |
| `https://sednoapp-79241-api.web.app` | 200, także z podrobionymi nagłówkami | 401, także z podrobionymi nagłówkami |
| `https://sedno-api-cabqsikexq-lm.a.run.app` | 200, także z podrobionymi nagłówkami | 401, także z podrobionymi nagłówkami |

Odczytano osiem odpowiadających im wpisów request logów Cloud Run po unikalnym
User-Agent `sedno-traffic-probe-fa9aa518744c416fbfb7a4454af3ba56`.
Próby przez Hosting miały trzy różne źródłowe adresy pośredników; cztery próby
bezpośrednie miały jeden wspólny adres źródłowy. Żaden nie był adresem podanym
w fałszywych nagłówkach. W raporcie nie zapisujemy rzeczywistych adresów klientów.

Te logi pokazują adres widziany na wejściu platformy, **nie surowy XFF otrzymany
przez Kestrel**. Nie uruchamiano endpointu wypisującego nagłówki i nie wdrażano
rewizji diagnostycznej. Potwierdzono dostępność obu dróg oraz różnicę ich
pośredników; zachowanie nowego limitera i dobór sufiksu sprawdzono lokalnie na
symulowanych łańcuchach. Odbiór nowej rewizji po wdrożeniu pozostaje osobnym krokiem.
Nie wysyłano tekstów, nie wywoływano AI, nie tworzono sesji i nie zapisywano
danych aplikacji. Nie wyczerpywano limitów produkcyjnych.

## Zmienione pliki

- Implementacja: [Program.cs](../backend/src/Sedno.Api/Program.cs),
  [CloudRunHosting.cs](../backend/src/Sedno.Api/CloudRunHosting.cs),
  [TrafficLimiting.cs](../backend/src/Sedno.Api/TrafficLimiting.cs).
- Testy: [TrafficLimitingTests.cs](../backend/tests/Sedno.IntegrationTests/TrafficLimitingTests.cs),
  [TrafficLimitingApiTests.cs](../backend/tests/Sedno.IntegrationTests/TrafficLimitingApiTests.cs).
- Dokumentacja: ten raport, [spis dokumentów](README.md),
  [README backendu](../backend/README.md),
  [instrukcja wdrożenia](../backend/deploy/firebase/README.pl.md)
  i [Tasks.md](../Tasks.md).

Zmiana dotyczy wyłącznie backendu i dokumentacji. Nie zmieniano Fluttera;
nie uruchamiano jego formatowania, analizy, testów ani budowy APK.
