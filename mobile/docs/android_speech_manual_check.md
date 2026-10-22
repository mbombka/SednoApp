# Próby upraszczania mowy na Androidzie

Implementacja wymaga Androida 13 (API 33) lub nowszego, natywnego silnika
rozpoznawania on-device oraz pobranego lokalnego modelu `pl-PL` lub `pl`.
Starsze systemy nadal obsługują tekst i zdjęcia. Nie stosujemy rozpoznawania
sieciowego ani automatycznego pobierania modelu.

Mikrofon znajduje się po lewej stronie „Uprość”, ma obszar dotyku 56 dp.
Podczas sesji zmienia się w stop, który **anuluje** sesję bez wysłania tekstu.
Po zakończeniu automatycznym tekst zastępuje zawartość edytora i przechodzi przez
ten sam przepływ co OCR: walidację 4000 znaków, limity i informację o AI.
Anulowanie informacji o AI lub błąd upraszczania pozostawia tekst w edytorze.

Audio PCM 16 kHz, mono, 16 bitów przechodzi z `AudioRecord` przez potok w pamięci
do `SpeechRecognizer.createOnDeviceSpeechRecognizer`. Sesja segmentowana trwa
do zamknięcia potoku; wyniki segmentów są łączone w kolejności. Silnik, który
odrzuca tę konfigurację, zgłasza błąd. Nie ma zapisu pliku ani fallbacku sieciowego.

Wykrywanie ciszy jest lokalne, oparte na energii ramek PCM po 20 ms,
z progiem tła i co najmniej 100 ms aktywności przed uzbrojeniem końca wypowiedzi.
Po aktywności 1500 ms ciszy zamyka strumień. Niezależny zegar kończy nagrywanie
po 60 s od rozpoczęcia rejestracji, także gdy nie padnie żadne słowo.
Dekodowanie po wyłączeniu mikrofonu może potrwać do kolejnych 10 s.
Detektor energii może traktować hałas jako mowę; próg trzeba sprawdzić na
telefonach, szczególnie przy cichej mowie i w głośnym otoczeniu.

## Lista prób przed wydaniem

- [ ] Zezwolenie na mikrofon, odmowa i trwała odmowa; brak zawieszenia i brak żądania uproszczenia po odmowie.
- [ ] Polski tekst, liczby, kilka zdań; cały tekst i kolejność segmentów w edytorze oraz wyniku.
- [ ] Pauza 1 s nie kończy sesji; około 1,5 s ciszy po mowie kończy ją i uruchamia uproszczenie.
- [ ] Ciągła mowa kończy się po 60 s; wskaźnik mikrofonu Androida gaśnie, ostatnie słowa są dekodowane.
- [ ] Całkowita cisza: mikrofon wyłącza się najpóźniej po 60 s, komunikat zamiast pustego żądania.
- [ ] Pojedyncze kliknięcie mikrofonu bez mowy nie uzbraja zakończenia po ciszy.
- [ ] Mowa cicha i hałas otoczenia: brak obcięcia cichych słów; w hałasie działa limit 60 s.
- [ ] Stop, menu użytkownika, przejście do tła, blokada ekranu i zamknięcie aplikacji zwalniają mikrofon; spóźniony wynik nie jest wysyłany.
- [ ] Brak modelu polskiego, brak lokalnego silnika i Android 12: czytelny komunikat, tekst i aparat nadal działają.
- [ ] Tryb samolotowy z pobranym modelem: transkrypcja działa; błąd backendu pozostawia tekst do ponowienia.
- [ ] Pierwsza informacja o AI, jej anulowanie, limit 0 i 1 oraz tekst ponad 4000 znaków.
- [ ] TalkBack, duża czcionka i mały ekran: przycisk opisany, stan i błędy odczytywane, brak przepełnienia.

Flutter 3.47.7 i Dart 3.13.5 są dostępne lokalnie. `dart format` oraz
`flutter analyze` wykonano poprawnie; skompilowano też bundle do podglądu ekranu.
Uruchomienie testów Fluttera blokuje zakaz otwierania lokalnego portu w sandboxie
(`Operation not permitted`, 127.0.0.1). Nie ma Android SDK, skryptu `gradlew`
ani telefonu/emulatora. Należy odtworzyć narzędzia Androida i Gradle wrapper.
Powyższe próby na telefonie **nie zostały wykonane**. Przed wydaniem uruchom:

```sh
cd mobile
dart format lib test
flutter analyze
flutter test
flutter build apk --debug
cd android
./gradlew :app:testDebugUnitTest
```

## Odtworzenie podglądu głównego ekranu

Narzędzie `tool/render_home_preview.dart` renderuje rzeczywisty `SednoApp`
bez połączenia z backendem. Z katalogu `mobile/`, na Linuksie z Flutter SDK
wskazanym przez zmienną `FLUTTER_SDK`, uruchom:

```sh
flutter build bundle --no-pub --debug --target-platform=linux-x64 \
  --dart-define=FLUTTER_SDK="$FLUTTER_SDK" --target=tool/render_home_preview.dart
"$FLUTTER_SDK/bin/cache/artifacts/engine/linux-x64/flutter_tester" \
  --disable-vm-service --enable-software-rendering --non-interactive --run-forever \
  --flutter-assets-dir=build/flutter_assets --packages=.dart_tool/package_config.json \
  build/flutter_assets/kernel_blob.bin
```

Pliki `build/previews/home.png` i `build/previews/home-with-text.png` pokazują
ekran pusty oraz z przykładowym tekstem. To render widżetów, bez systemowych
pasków Androida i bez weryfikacji działania mikrofonu.
