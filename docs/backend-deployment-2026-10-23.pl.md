# Wdrożenie backendu — 23.10.2026

Wdrożono **`sedno-api-00013-8x6`** na istniejącym `sedno-api`, projekt `sednoapp-79241`,
region `europe-central2`. Nowa rewizja otrzymuje 100% ruchu i obsługuje
**https://sednoapp-79241-api.web.app**.

## Zakres i obraz

- Polski i angielski (UK) w `POST /v1/simplifications`, wspólne limity i osobne
  prompty trybów Uprość oraz Popraw. Brak `language` nadal oznacza `pl`.
- Aktualne prompty właściciela: `simplify.pl.txt`, `correct.pl.txt`,
  `simplify.en-gb.txt`, `correct.en-gb.txt`. Treści nie zmieniano przy wdrożeniu.
- Pozostałe przygotowane pliki promptów są osadzone w obrazie, ale nie włączają
  dodatkowych języków w API. Obsługiwane języki to nadal `pl` i `en`.
- Produkcyjne ustawienia Responses API, brak utrwalania tekstu, weryfikacja
  tożsamości, limity i płatności pozostają zachowane.
- Cloud Build: `f9250928-f32a-414c-81c6-ed1e6ab6f7a6`, **SUCCESS**.
- Obraz: `europe-central2-docker.pkg.dev/sednoapp-79241/backend/api@sha256:9b919a5c0d401568da89967cace738269690657865e5367491c26a80a3c7f6a4`.
- Tag obrazu: `20261023-english16-813c2d5b`.
- Hosting: tag `fh-f900ef5714088d13` wskazuje nową rewizję. Stary tag `fh-4c26c1712721c16e`
  usunięto po przełączeniu; jego `/health/ready` zwraca 404.
- Cleanup działa na tym samym nowym obrazie; wykonanie `sedno-cleanup-p8njp`
  zakończyło się powodzeniem. Harmonogram pozostaje godzinowy w UTC.

## Zachowanie konfiguracji

Przed i po wdrożeniu porównano konto usługi, wszystkie zmienne środowiska
oraz odwołania do sekretów, woluminy i montowania, zasoby, porty i obie sondy.
Wartości są identyczne. Zachowano współbieżność 80, timeout 30 sekund,
0–3 instancje rewizji i limit usługi 20. Billing pozostaje włączony do testów
z istniejącym produktem `subscription_full` i planem `monthly`.
Nie tworzono nowej bazy, usługi ani konta usługi; nie odczytywano wartości sekretów.
Oba istniejące indeksy Firestore sprawdzono przed przełączeniem jako READY.

Sprawdzono 75 plików kontekstu Cloud Build: zawierały cztery aktywne prompty,
a nie zawierały lokalnej konfiguracji mobilnej ani kluczy podpisu Androida.
Źródłem był bieżący stan roboczy brancha `feature/multilingual-app`, obejmujący
wcześniejsze niezacommitowane zmiany właściciela. Nie wykonywano commita.

SHA-256 aktywnych promptów:

```text
simplify.pl.txt  49049b3d2eb01b65476cbe9cbfba7349f80a227b33c5857b5156b56f64a795d7
correct.pl.txt  f0e31360ab73e24e28371aab60be400ec20ce731bb84bf69c5aff064b111892a
simplify.en-gb.txt  168d373e7064865da3dd8cddcfec084c4157d135758fc631f32d1bef8a6acb25
correct.en-gb.txt  84bc064f8094c420cf8217c3a0fb63268ff2e13ba26a1a5a82e2dc3049d58ddd
```

## Weryfikacja

- Backend: 111 testów jednostkowych, 99 integracyjnych z emulatorem Firestore,
  38 testów narzędzi benchmarkowych — wszystkie przeszły.
- Pierwszą próbę integracji przerwał błąd montowania kontenera Dockera
  (`device or resource busy`). Ponowiony pełny projekt integracyjny przeszedł 99/99.
- Flutter: analiza bez uwag, 261 testów przeszło; formatowanie 122 plików bez zmian.
- Natywny Android: 6 testów, bez błędów.
- Skrypty wdrożenia: 20 testów; oba generatory prywatności potwierdziły zgodność.
- Po wdrożeniu: 15 kontroli HTTP przez Hosting, bezpośredni Cloud Run i nowy tag.
  `/health/live` i `/health/ready`: 200 oraz `no-store`; limit, przetwarzanie
  angielskiego tekstu i RTDN bez uwierzytelnienia: 401.
- Skrypt wdrożenia sprawdził zgodność przypięcia Hosting, gotowość nowej rewizji
  i 404 starego adresu tagowanego.

Kontrole produkcyjne nie wywoływały AI ani nie tworzyły danych testowych w bazie.
Nie testowano rzeczywistych zakupów, wiadomości Firebase, jakości wyników AI
ani urządzenia fizycznego. Strony `sedno.xyz` nie publikowano; dokumenty
udostępniane przez Hosting API pochodzą z nowego obrazu.

## Aplikacja i zmienione pliki wydania

Przygotowano [podpisany AAB 0.1.0 (16)](../mobile/docs/google_play_release_16.md).
Pakietu nie wysyłano do Google Play.

Przy przygotowaniu wydania zmieniono numer w `mobile/pubspec.yaml` i aktualne
odnośniki w README aplikacji, backendu i repozytorium, `docs/README.md`,
`backend/deploy/firebase/README.pl.md`, `docs/multilingual-app.pl.md`.
Dodano ten raport oraz raport AAB 16. Manifesty zapisano w ignorowanym
`backend/deploy/generated/release16/`, artefakty w `mobile/build/releases/`.
Zachowano wcześniejsze zmiany kodu i promptów.
