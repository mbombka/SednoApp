# Upraszczanie mowy — zadania

Gałąź: `work-2026-10-21`.

- [x] Sprawdzić ekran główny, przepływ OCR, walidację i limity.
- [x] Dodać natywne rozpoznawanie Androida na urządzeniu z kontrolą lokalnego modelu polskiego.
- [x] Dodać uprawnienie mikrofonu i komunikaty o braku dostępu lub obsługi.
- [x] Dodać przycisk mikrofonu po lewej stronie „Uprość”, stan sesji i anulowanie.
- [x] Kończyć strumień po 1500 ms ciszy po mowie oraz bezwarunkowo po 60 s rejestracji.
- [x] Łączyć segmenty transkrypcji i przekazywać je do obecnego przepływu upraszczania.
- [x] Obsłużyć anulowanie, zmianę ekranu i przejście aplikacji do tła.
- [x] Przygotować testy jednostkowe i widżetowe oraz opis prób na urządzeniu.
- [x] Uzupełnić informacje o przetwarzaniu mowy i dokumentację.
- [x] Uruchomić `dart format` i `flutter analyze` — analiza bez uwag.
- [x] Skompilować bundle Fluttera dla podglądu i wyrenderować ekran główny do PNG.
- [ ] Uruchomić testy Fluttera — próba została zablokowana przez zakaz otwierania lokalnego portu w sandboxie (`Operation not permitted`, 127.0.0.1).
- [ ] Uruchomić testy Androida i kompilację APK — brak Android SDK i skryptu Gradle wrapper w środowisku.
- [ ] Wykonać próby na urządzeniu według `android_speech_manual_check.md`, w tym 60 s ciągłej mowy, polski model offline i dokładność detekcji ciszy.
