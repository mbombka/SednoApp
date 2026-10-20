# Wdrożenie diagnostyki Play Integrity — 19.10.2026

Wdrożono backend z logowaniem powodów odrzucenia Play Integrity. Aktualizacja
nie zmienia warunków akceptacji ani kontraktu API. Nie wymaga aktualizacji Androida.

- Projekt: `sednoapp-79241`, region: `europe-central2`.
- Cloud Build: `739056a8-fadf-40c8-b3a0-99b97b106285`, wynik `SUCCESS`.
- Obraz: `europe-central2-docker.pkg.dev/sednoapp-79241/backend/api@sha256:825c14d3e893a5b6778afb8df016748187490a6494da694569f0dc98a7469059`.
- Rewizja API: `sedno-api-00004-w5q`, ruch Cloud Run 100%.
- Wersja Firebase Hosting API: `4c0f36a1f1e95b7f`, publikacja zakończona sukcesem.
- Publiczne API: `https://sednoapp-79241-api.web.app`.

Zachowano zmienne konfiguracji, odwołania do wersji sekretów, konto usługi
oraz zasoby kontenera. Zadanie cleanup pozostało na poprzednim obrazie;
zmiana dotyczy obsługi żądań API. Nie zmieniano bazy, indeksów ani reguł dostępu.

## Weryfikacja

Przed wdrożeniem wszystkie 175 testów backendu przeszło: 80 jednostkowych,
57 integracyjnych i 38 narzędzia benchmarkowego.

Po wdrożeniu publiczne `/health/live` i `/health/ready` zwróciły HTTP 200.
Kontrolne żądanie utworzenia sesji bez tokenu Integrity zwróciło oczekiwane
HTTP 403 z `integrity_failed`. Na nowej rewizji o `2026-10-19T18:49:01.641677Z`
zapisano `Play Integrity rejected. Reason=missing_token`, co potwierdza działanie
diagnostyki również przez adres Firebase Hosting. Żądanie nie utworzyło sesji.

Do ustalenia przyczyny wcześniejszych błędów pozostaje powtórzenie logowania
na telefonie. Starsze odpowiedzi nie zawierały informacji pozwalającej odtworzyć
konkretny warunek odrzucenia. Instrukcja odczytu kodów `Reason` jest w
[README backendu](../../backend/README.md#diagnostyka-odrzucenia-play-integrity).

## Potwierdzona przyczyna i poprawka tolerancji zegarów

Ponowna próba na telefonie o 18:49:34–18:49:41 UTC (20:49 czasu polskiego)
wykazała `Reason=token_from_future`. Wiek tokenów wynosił odpowiednio
`-0.2529206`, `-0.5916464` i `-0.6042255` sekundy. To potwierdza odrzucenie
z powodu niewielkiej różnicy między czasem tokenu i zegarem backendu.
Nie potwierdza problemu z instalacją APK ani certyfikacją urządzenia.

Backend dopuszcza teraz token do 5 sekund z przyszłości. Maksymalny wiek nadal
wynosi 5 minut; pozostałe warunki są sprawdzane również po zaakceptowaniu różnicy
czasu. Testy obejmują zaobserwowane różnice, granice -5 s i +5 min oraz odmowę
przy niezgodnym hashu mimo czasu mieszczącego się w tolerancji.

- Wszystkie 182 testy przeszły: 87 jednostkowych, 57 integracyjnych, 38 benchmarkowych.
- Cloud Build: `50314253-7dc2-42ae-a72a-1f3ebd256e25`, wynik `SUCCESS`.
- Obraz: `europe-central2-docker.pkg.dev/sednoapp-79241/backend/api@sha256:38a000fe734202f3a96951ba9f12a26c894ecec9d4e01ceaf35c41f15b0b4e8b`.
- Rewizja: `sedno-api-00005-5g5`, ruch Cloud Run 100%.
- Firebase Hosting: `b452257d0d97801f`, publikacja zakończona sukcesem.
- Publiczne `/health/live` i `/health/ready`: HTTP 200.
- Żądanie bez tokenu: nadal HTTP 403, `integrity_failed`.
- Konfiguracja i odwołania do sekretów pozostały bez zmian.

Końcowe potwierdzenie całego logowania wymaga kolejnej próby na telefonie;
kontrola gotowości API nie zastępuje testu z rzeczywistym tokenem Google.
