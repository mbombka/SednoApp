# Wdrożenie 13 wariantów językowych — 23.10.2026

Wdrożono **`sedno-api-00014-mmh`**, 100% ruchu, na istniejącym `sedno-api`, projekt
`sednoapp-79241`, region `europe-central2`. API: https://sednoapp-79241-api.web.app.

Obsługiwane kody: `pl`, `en` (UK), `en-US`, `fr`, `de`, `it`, `es`, `pt`
(Portugalia), `sk`, `cs`, `ro`, `nb` (Bokmål), `sv`. Osobne prompty obu trybów;
brak języka nadal oznacza polski. Wszystkie 26 promptów zachowano bez zmian.
[Zakres kodu i testów](multilingual-13-languages.pl.md).

- Cloud Build `85a52d80-dee8-4ae6-897d-964e365db142`: SUCCESS.
- Obraz: `europe-central2-docker.pkg.dev/sednoapp-79241/backend/api@sha256:089832ae7fb0385b21e6b2802bc459614ab4e05fb75b22fcfb5c75ec30331527`.
- Tag: `20261023-133147-multilingual17`; sprawdzono 76 plików wysyłanych do Cloud Build,
  wszystkie prompty, bez mobilnej konfiguracji lokalnej i kluczy podpisu.
- Hosting wskazuje nową rewizję; stare tagowane adresy zostały wycofane.
- Cleanup zaktualizowano do tego samego obrazu i wykonano pomyślnie.
  Pierwszy przebieg procedury wykonał cleanup na poprzednim obrazie;
  po przełączeniu API powtórzono aktualizację i wykonanie na nowym obrazie.
- Konto usługi, zmienne i odwołania do sekretów, zasoby, sondy, woluminy,
  współbieżność 80 i timeout 30 s zachowano. Nie tworzono nowej bazy ani usług.
  Billing pozostaje włączony do testów, produkt `subscription_full`, plan `monthly`.
- Oba indeksy Firestore były READY. Harmonogram cleanup pozostaje godzinowy w UTC.
- Kontrole po wdrożeniu: 15 odpowiedzi HTTP przez Hosting, Cloud Run i nowy tag;
  zdrowie i gotowość 200 z `no-store`, chronione endpointy bez poświadczeń 401.
  Kontrole nie wywoływały AI i nie tworzyły danych testowych w bazie.

Przed wydaniem zaliczono 325 testów Flutter, 135 jednostkowych backendu,
110 integracyjnych z emulatorem Firestore, 38 narzędzi benchmarkowych,
9 Kotlin i 20 Python; analiza Fluttera bez uwag. Generatory polityk są spójne.
Po zmianie numeru wersji wykonano budowę release i walidację AAB.
Nie wykonywano prób telefonu, rzeczywistych zakupów, poczty ani oceny AI.

Aplikacja: [podpisany AAB 0.2.0 (17)](../mobile/docs/google_play_release_17.md).
Nie publikowano w Google Play ani strony marketingowej sedno.xyz.
Źródłem jest roboczy stan `feature/multilingual-app`, z zachowaniem wcześniejszych
zmian właściciela; nie wykonywano commita. Manifesty: ignorowany
`backend/deploy/generated/release17/`. Numer zwiększono w `mobile/pubspec.yaml`;
raporty i odnośniki zaktualizowano w README repozytorium, mobile, backendu i docs.
