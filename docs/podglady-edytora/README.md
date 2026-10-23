# Podglądy aktualnego edytora

Wygenerowane z rzeczywistych widgetów Flutter, w rozmiarze logicznym 412 × 892.
Teksty są przykładowe; generowanie podglądów nie wywołuje AI.
Nie są to zdjęcia telefonu — nie zawierają systemowych pasków Androida.

![Trzy ekrany Sedno](sedno-trzy-ekrany.png)

- [Edytor z gumką](01-edytor-z-gumka.png)
- [Tekst uproszczony](02-tekst-uproszczony.png)
- [Tekst poprawiony](03-tekst-poprawiony.png)

Nagłówek wyniku i systemowy Wstecz przywracają oryginał ostatniej operacji.
Gumka jest po prawej stronie przełącznika trybu i usuwa tekst oraz zapamiętany oryginał.

Podglądy po zmianie komunikatu z 23.10.2026:

- [Krótki wynik uproszczenia](04-uproszczony-krotki.png)
- [Długi wynik uproszczenia — początek tekstu](05-uproszczony-dlugi.png)

Komunikat „AI może się mylić” jest pod polem, w białym obszarze edytora.
Długi wynik przewija się wewnątrz pola; komunikat i przyciski pozostają na miejscu.
W obu podglądach zakres przewijania całego ekranu wynosi 0 dp;
długi tekst ma dodatkowo 556 dp przewijania wewnątrz pola.

Odtworzenie podglądów z katalogu `mobile/` (zmień ścieżkę SDK na własną):

```sh
flutter build bundle --debug --target=tool/render_home_preview.dart --dart-define=FLUTTER_SDK=/home/user/develop/flutter
/home/user/develop/flutter/bin/cache/artifacts/engine/linux-x64/flutter_tester --disable-vm-service --run-forever --flutter-assets-dir=build/flutter_assets build/flutter_assets/kernel_blob.bin
```

Narzędzie zapisuje obrazy w `mobile/build/previews/`.
