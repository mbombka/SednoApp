# Pierwszy test Sedno przez Google Play

Projekt: `sednoapp-79241` (numer `1003558402460`), pakiet: `xyz.sedno.app`.
API: `https://sednoapp-79241-api.web.app`. Płatności pozostają wyłączone.

Serwer przełączono na Firestore 19.10.2026. Zachowano testowe sesje i metadane limitów.
Przed kolejnym testem sprawdź [aktualny stan wdrożenia](../../backend/deploy/firebase/README.pl.md).

Stan 19.10.2026: Play Integrity API jest włączone w Google Cloud;
właściciel potwierdził powiązanie projektu w Play Console. Test aplikacji
zainstalowanej z Google Play pozostaje do wykonania.

## 1. Przygotuj plik AAB

Z katalogu `mobile/`, z lokalną konfiguracją Firebase i kluczem przesyłania:

```sh
flutter build appbundle --release --build-number=7 --dart-define-from-file=config/firebase.local.json
```

Plik: `mobile/build/app/outputs/bundle/release/app-release.aab`.
Ostatni przygotowany pakiet to **6** (`0.1.0+6`), po wcześniej przygotowanym wydaniu 5.
Powstał przed ujednoliceniem polityki dla odbiorców 13+ z 20.10.2026.
Kolejny pakiet z aktualną treścią zbuduj z numerem co najmniej 7;
jeśli ten numer został już użyty w Play Console, wybierz wyższy.
Zachowaj zabezpieczoną kopię `mobile/android/key.properties` oraz
`mobile/android/keystore/sedno-upload.jks` poza projektem. Zawierają hasła i klucz
potrzebne do kolejnych wydań. Nie przesyłaj ich do Play Console ani do rozmowy.
Publiczny certyfikat przesyłania jest w `mobile/android/keystore/sedno-upload-certificate.pem`.

## 2. Prześlij wydanie i dodaj testera

1. W Play Console wybierz Sedno → **Testuj i publikuj → Testowanie → Test wewnętrzny**.
2. Utwórz wydanie i prześlij AAB. Dla nowej aplikacji Google domyślnie konfiguruje
   podpisywanie własnymi kluczami. Wykonaj wymagane kroki panelu.
   To kanał testowy, dostępny wybranym testerom.
3. Dodaj adres konta Google używanego na telefonie do listy testerów, zapisz listę
   i udostępnij wydanie. Otwórz link dołączenia na tym koncie i zaakceptuj udział.

## 3. Dodaj certyfikat Google Play do Firebase

W Play Console najpierw wybierz **Sedno**, a następnie w lewym menu:
**Chronione przez Google Play → Dystrybucja w Sklepie Play →
Przejdź do podpisywania aplikacji przez Google Play**.
W części widoków karta ma nazwę **Ochrona w Sklepie Play**, a przycisk
**Zarządzaj podpisywaniem aplikacji przez Google Play**.
To ta sama część panelu, w której znajduje się Play Integrity API.

Skopiuj SHA-1 i SHA-256 z sekcji **Certyfikat klucza podpisywania aplikacji**
(App signing key certificate). W Firebase otwórz
[ustawienia projektu sednoapp-79241](https://console.firebase.google.com/project/sednoapp-79241/settings/general).
Możesz też kliknąć koło zębate przy przeglądzie projektu → **Ustawienia projektu
/ Project settings → Ogólne / General**. Przewiń do **Twoje aplikacje / Your apps**,
wybierz Android `xyz.sedno.app`, a pod **Odciski certyfikatów SHA / SHA certificate
fingerprints** kliknij **Dodaj odcisk / Add fingerprint**. Wklej SHA-1 i zapisz,
następnie dodaj SHA-256 jako osobny wpis.
Certyfikat klucza przesyłania jest osobnym certyfikatem; do logowania wersji
zainstalowanej z Play potrzebny jest podpis używany przez Google Play.
Jeśli panel pokazuje kilka kluczy podpisywania dla różnych wersji Androida,
dodaj odciski każdego z nich. [Instrukcja Google](https://support.google.com/googleplay/android-developer/answer/9842756?hl=pl).

Projekt powiąż w **Chronione przez Google Play → Play Integrity API
→ Link Cloud project**. Wybierz `sednoapp-79241`. Pozostaw sprawdzanie tokenów
przez serwery Google. Nie ustawiaj wymuszonych odpowiedzi testowych dla końcowej próby.

## 4. Sprawdź na telefonie

Zainstaluj aplikację z linku Google Play na certyfikowanym telefonie.
Jeśli Android odrzuca aktualizację wersji debug, usuń ją wcześniej — stracisz jej
lokalną historię. Instalacja APK przez USB nie zastępuje tej próby.

1. Bez logowania wpisz sztuczny tekst, np. „Spotkanie odbędzie się jutro o 12:00”.
   Zaakceptuj informację o AI. Sprawdź wynik, kopiowanie przez zaznaczenie tekstu
   i menu systemowe oraz zapis w Historii. Nie ma osobnego przycisku „Kopiuj”.
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
