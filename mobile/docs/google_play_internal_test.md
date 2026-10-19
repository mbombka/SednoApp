# Pierwszy test Sedno przez Google Play

Projekt: `sednoapp-79241` (numer `1003558402460`), pakiet: `xyz.sedno.app`.
API: `https://sednoapp-79241-api.web.app`. Płatności pozostają wyłączone.

Stan 19.10.2026: Play Integrity API jest włączone w Google Cloud;
właściciel potwierdził powiązanie projektu w Play Console. Test aplikacji
zainstalowanej z Google Play pozostaje do wykonania.

## 1. Przygotuj plik AAB

Z katalogu `mobile/`, z lokalną konfiguracją Firebase i kluczem przesyłania:

```sh
flutter build appbundle --release --dart-define-from-file=config/firebase.local.json
```

Plik: `mobile/build/app/outputs/bundle/release/app-release.aab`.
Przy następnym przesłaniu zwiększ numer wydania, np. dodając `--build-number=2`.
Zachowaj zabezpieczoną kopię `mobile/android/key.properties` oraz
`mobile/android/keystore/sedno-upload.jks` poza projektem. Zawierają hasła i klucz
potrzebne do kolejnych wydań. Nie przesyłaj ich do Play Console ani do rozmowy.
Publiczny certyfikat przesyłania jest w `mobile/android/keystore/sedno-upload-certificate.pem`.

## 2. Prześlij wydanie i dodaj testera

1. W Play Console wybierz Sedno → **Testuj i publikuj → Testowanie → Test wewnętrzny**.
2. Utwórz wydanie, włącz podpisywanie aplikacji przez Google Play i prześlij AAB.
   Wykonaj wymagane kroki panelu. To kanał testowy, dostępny wybranym testerom.
3. Dodaj adres konta Google używanego na telefonie do listy testerów, zapisz listę
   i udostępnij wydanie. Otwórz link dołączenia na tym koncie i zaakceptuj udział.

## 3. Dodaj certyfikat Google Play do Firebase

W Play Console otwórz **Podpisywanie aplikacji / App signing**.
Skopiuj SHA-1 i SHA-256 z sekcji **Certyfikat klucza podpisywania aplikacji**
(App signing key certificate). Dodaj je w Firebase → Ustawienia projektu →
Twoje aplikacje → Android `xyz.sedno.app` → Odciski certyfikatów SHA.
Certyfikat klucza przesyłania jest osobnym certyfikatem; do logowania wersji
zainstalowanej z Play potrzebny jest podpis używany przez Google Play.

Projekt powiąż w **Protected with Play / Integralność aplikacji → Play Integrity API
→ Link Cloud project**. Wybierz `sednoapp-79241`. Pozostaw sprawdzanie tokenów
przez serwery Google. Nie ustawiaj wymuszonych odpowiedzi testowych dla końcowej próby.

## 4. Sprawdź na telefonie

Zainstaluj aplikację z linku Google Play na certyfikowanym telefonie.
Jeśli Android odrzuca aktualizację wersji debug, usuń ją wcześniej — stracisz jej
lokalną historię. Instalacja APK przez USB nie zastępuje tej próby.

1. Bez logowania wpisz sztuczny tekst, np. „Spotkanie odbędzie się jutro o 12:00”.
   Zaakceptuj informację o AI. Sprawdź wynik, kopiowanie i zapis w Historii.
2. Zaloguj się przez Google. Sprawdź Konto i kolejne uproszczenie.
   Wykorzystany limit gościa musi pozostać wykorzystany po zalogowaniu.
3. Sprawdź logowanie e-mail/hasło na koncie testowym i ponowne uruchomienie aplikacji.
4. Wyloguj się. Lokalna historia powinna zostać usunięta. Ponownie sprawdź logowanie.

Każde udane uproszczenie zużywa darmowy limit 5 dziennie; reset jest o 00:00 UTC.
Nie zapisuj tokenów, haseł ani treści użytkowników. Zanotuj wersję, model telefonu,
czas UTC i wynik każdego kroku. Dopiero po tych próbach zaznacz zadanie jako zakończone.

Przy błędzie sesji sprawdź projekt Integrity, instalację z Play i certyfikację
telefonu. Przy błędzie logowania Google sprawdź podpis Google Play w Firebase.

Źródła: [konfiguracja Integrity](https://developer.android.com/google/play/integrity/setup),
[testy wewnętrzne](https://support.google.com/googleplay/android-developer/answer/9845334?hl=pl),
[podpisywanie Flutter](https://docs.flutter.dev/deployment/android).
