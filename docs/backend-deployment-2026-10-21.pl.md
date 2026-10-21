# Wdrożenie backendu i AAB 11 — 21.10.2026

Wdrożono **`sedno-api-00011-bfh`** na istniejącym `sedno-api`, projekt
`sednoapp-79241`, region `europe-central2`. Rewizja otrzymuje 100% ruchu
bezpośredniego Cloud Run i obsługuje Hosting API. Przygotowano
[podpisany AAB 0.1.0 (11)](../mobile/docs/google_play_release_11.md).
Nie opublikowano aplikacji w Google Play.

## Zakres

- Odwoływanie sesji po zmianach Firebase, cache kontroli do 5 minut i wymaganie
  świeżego uwierzytelnienia przy usuwaniu konta.
- Weryfikacja subskrypcji ważna maksymalnie 15 minut, odświeżana na żądanie.
- Lokalny limiter: osobne ważne tożsamości gości i kont, wspólny limit przed
  sesją za pośrednikiem Hosting, niezależny limit RTDN.
- Współbieżność **80 żądań na instancję**, rewizja skaluje się od 0 do 3 instancji.
  Nominalnie do 240 równoczesnych żądań API; nie wykonywano testu tej wydajności.
- Zachowano istniejący limit usługi 20 instancji; bieżącą rewizję ogranicza
  niższy limit 3. Nie zmieniano tożsamości usługi, bazy `(default)`, wersji
  sekretów ani współdzielonego pierścienia kluczy płatności.

## Obraz, Hosting i cleanup

- Cloud Build: `f1143262-4ab5-4251-8b39-1e4bf1949a2b`, **SUCCESS**.
- Obraz: `europe-central2-docker.pkg.dev/sednoapp-79241/backend/api@sha256:6ef3df18813c51c72b057b46d46f66c0263324adff5e299582d3c8c52413547f`.
- Hosting: wersja `2027f4cf6de7a4f5`, wydanie `1792567161125000`,
  tag `fh-2027f4cf6de7a4f5` → `sedno-api-00011-bfh`.
- Poprzedni tag `fh-124b4d67a8c727d4` usunięto po przełączeniu Hosting;
  jego `/health/ready` zwraca 404. Nie pozostawiono innego publicznego tagu.
- Istniejące zadanie `sedno-cleanup` korzysta z nowego obrazu.
  Wykonanie `sedno-cleanup-6jk42` zakończyło się sukcesem.
- Wykonano repozytoryjny `deploy.sh`, w tym publikację istniejących reguł/indeksów,
  aktualizację istniejącego harmonogramu godzinowego i kontrolę starych tras.
  Nie utworzono nowej bazy ani backendu.

## Weryfikacja

Przed wdrożeniem: **235/235 testów backendu**, **176/176 testów Fluttera**
i **13/13 testów narzędzi Python**. Formatowanie Dart bez zmian, analiza Fluttera
bez problemów. AAB zbudowany, podpis i zgodność certyfikatu z wydaniem 10
zweryfikowane; manifest i `bundletool validate` poprawne.

Po wdrożeniu wykonano 21 lekkich kontroli API — po siedem pod każdym adresem:

- `https://sednoapp-79241-api.web.app`;
- `https://sedno-api-cabqsikexq-lm.a.run.app`;
- `https://fh-2027f4cf6de7a4f5---sedno-api-cabqsikexq-lm.a.run.app`.

Wyniki: gotowość 200; bez sesji 401; bez sesji z podrobionymi XFF/Fastly/hostem
401; dwie niezależne sesje gości 200 z limitem 5 i pozostałymi 5; dawna sesja
konta bez nowych pól 401; sfałszowany RTDN 401. Utworzono wyłącznie pięć
syntetycznych dokumentów testowych i usunięto je w bloku sprzątającym.

Dodatkowa próba konta użyła jednego tymczasowego użytkownika Firebase i trzech
syntetycznych dokumentów reprezentujących ważną sesję konta. Przez Hosting
i bezpośredni Cloud Run potwierdzono HTTP 200 przy odczycie limitu po rzeczywistej kontroli statusu
konta w Firebase oraz 403 przy usuwaniu bez świeżego tokenu. Wylogowanie zwróciło
204, a ponowne użycie poświadczenia 401. Wszystkie trzy dokumenty i użytkownika
Firebase usunięto. Próba nie zastępuje logowania ani usuwania na telefonie.

Do istniejącego tematu `sedno-billing-rtdn-test` opublikowano jeden komunikat
`testNotification` dla `xyz.sedno.app`. Wiadomość `21731374258806800` została
dostarczona przez skonfigurowany Pub/Sub z OIDC. Request log nowej rewizji
potwierdza **204 o 09:19:59 czasu polskiego**. Trzy próby z fałszywym tokenem
zwróciły 401. Testowy RTDN nie zmieniał żadnej subskrypcji.

Nie wysyłano tekstów do AI i nie wykonywano zakupów. Nie wyczerpywano liczników
produkcyjnych; izolację przy wyczerpaniu i lokalność instancji potwierdzają testy
integracyjne. Nie odczytywano surowego XFF w kontenerze ani nie dodawano
publicznego endpointu diagnostycznego. Pozostaje odbiór aplikacji na telefonie,
rzeczywiste zakupy Google Play oraz pomiar wydajności przy większym ruchu.
