# Wdrożenie backendu — 22.10.2026

Wdrożono **`sedno-api-00012-9j4`** na istniejącym `sedno-api` w projekcie
`sednoapp-79241`, region `europe-central2`. Nowa rewizja otrzymuje 100% ruchu
Cloud Run i obsługuje **https://sednoapp-79241-api.web.app**.

## Zakres

- Aktualne, zmienione przez właściciela prompty: `simplify.pl.txt` i `correct.pl.txt`.
  Ich treści nie poprawiano ani nie zmieniano podczas wdrożenia.
- Tryb `mode=correct`, osobny osadzony prompt poprawiania i potwierdzanie trybu
  w odpowiedzi API. Starsze żądania nadal domyślnie upraszczają tekst.
- Czasowy dostęp testerski: `TesterAccessExpiresAt` w istniejącym koncie,
  limit 400, data sprawdzana w transakcji; bez zerowania liczników i bez
  ingerencji w zakupy Google Play. [Instrukcja administracyjna](tester-access.pl.md).
- Zachowane parametry modelu produkcyjnego i brak zapisywania treści przez backend.

## Obraz i konfiguracja

- Cloud Build: `5d6e8071-01da-4784-af51-e64a6b9b6757`, **SUCCESS**.
- Obraz: `europe-central2-docker.pkg.dev/sednoapp-79241/backend/api@sha256:fa05d0a9f6904a9452f2bc1d08ab3d093085869323ce7edf622b0a0749621ce1`.
- Hosting: wersja `4c26c1712721c16e`, wydanie `1792676051425000`;
  tag `fh-4c26c1712721c16e` wskazuje nową rewizję.
- Poprzedni tag `fh-2027f4cf6de7a4f5` usunięto po przełączeniu Hosting;
  jego `/health/ready` zwraca 404. Nie usuwano historycznych obrazów i rewizji.
- Istniejące zadanie `sedno-cleanup` używa nowego obrazu;
  wykonanie `sedno-cleanup-b5rhl` zakończone sukcesem. Harmonogram pozostaje godzinowy.
- Przed wdrożeniem porównano manifest z działającą usługą: te same zmienne
  środowiska, odwołania do sekretów, konto usługi, montowania, zasoby i timeout.
  Współbieżność 80; 0–3 instancje rewizji; limit usługi 20 zachowany.
- Zachowano istniejący Firestore `(default)`, konto usługi i klucze płatności.
  Nie tworzono nowych usług, baz ani kont usługi. Reguły i indeksy opublikowano
  repozytoryjnym skryptem; oba istniejące indeksy były `READY`.

SHA-256 plików promptów przesłanych do Cloud Build:

```text
simplify.pl.txt  63248603dd180117131b0a4fb4759a1362d779736d1979128f8c85c55387107f
correct.pl.txt   f0e31360ab73e24e28371aab60be400ec20ce731bb84bf69c5aff064b111892a
```

Sprawdzono listę 51 plików kontekstu Cloud Build: zawiera oba prompty;
nie zawiera lokalnej konfiguracji mobilnej ani klucza podpisu Androida.

## Weryfikacja

- `dotnet test backend/Sedno.Backend.sln --no-restore`: **243 testy** —
  107 jednostkowych, 98 integracyjnych z emulatorem Firestore, 38 narzędzi modelowych.
- `flutter analyze`: bez uwag; `flutter test`: **212 testów**.
- `dart format --output=none --set-exit-if-changed mobile/lib mobile/test`:
  104 pliki, bez zmian.
- `python3 -m unittest discover -s tools/tests`: **20 testów**.
- `python3 tools/generate_privacy_policy.py --check`: dokumenty spójne.
- `./gradlew :app:testDebugUnitTest` (JDK Android Studio): 6 testów natywnych Androida, sukces.
- Po wdrożeniu: **15 kontroli HTTP** przez Hosting, bezpośredni Cloud Run
  i nowy adres tagowany. Gotowość i żywotność 200 z `no-store`;
  odczyt limitu, żądanie poprawiania i RTDN bez uwierzytelnienia — 401.
- Skrypt wycofania tras potwierdził gotowość Hosting, właściwe przypięcie i 404
  poprzedniego adresu tagowanego.

Kontrole produkcyjne nie wywoływały AI ani nie tworzyły danych testowych w bazie.
Nie przeprowadzono oceny jakości nowych promptów na rzeczywistym modelu,
zakupów Google Play ani odbioru odczytu TTS na telefonie.
Publicznej strony `sedno.xyz` nie publikowano w ramach tego wdrożenia;
Hosting API i dokumenty serwowane przez backend korzystają z nowego obrazu.

## Aplikacja Android

Przygotowano [podpisany AAB 0.1.0 (12)](../mobile/docs/google_play_release_12.md).
Budowa release zakończona sukcesem; podpis i certyfikat zgodne z poprzednim
wydaniem, manifest i walidacja bundletool poprawne. Pakietu nie wysłano do Google Play.

Pliki zmienione przy przygotowaniu tego wydania: `mobile/pubspec.yaml` (numer 12),
`README.md`, `backend/README.md`, `backend/deploy/firebase/README.pl.md`,
`mobile/README.md`, `docs/README.md`, `docs/popraw-zadania.md`, `docs/tester-access.pl.md`
oraz nowe raporty tego wdrożenia i wydania AAB 12. Manifesty wdrożenia powstały
w ignorowanym katalogu `backend/deploy/generated/`; AAB, suma kontrolna i mapa R8
w ignorowanym `mobile/build/releases/`. Wcześniejsze zmiany kodu i aktualne
prompty właściciela zachowano.
