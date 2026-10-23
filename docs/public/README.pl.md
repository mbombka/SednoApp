# Dokumenty na stronie Sedno

Publiczne adresy:

- [Pełna polityka prywatności](https://sedno.xyz/prywatnosc/).
- [Instrukcja usunięcia konta](https://sedno.xyz/usun-konto/).
- [Podsumowanie na stronie głównej](https://sedno.xyz/#prywatnosc).

Dokumenty w `docs/public/` są osadzane w backendzie. Ich identyczne kopie w
`website/SednoWebsite/public/` są przeznaczone do publikacji na OVH przez SFTP.
Wszystkie cztery pliki tworzy wspólny generator. Edycja repozytorium nie zmienia
strony `sedno.xyz`. Przed publikacją sprawdź dostępność i wersję dokumentów online.

## Aktualizacja treści

Edytuj tylko [wspólne źródło JSON](../privacy-policy.pl.json), a następnie z katalogu
głównego projektu uruchom (potrzebne Python 3 i `dart`):

```sh
python3 tools/generate_privacy_policy.py
python3 tools/generate_privacy_policy.py --check
```

Generator aktualizuje politykę Markdown, treść w aplikacji oraz
[prywatnosc/index.html](prywatnosc/index.html) i [usun-konto/index.html](usun-konto/index.html), a także ich kopie w
`website/SednoWebsite/public/`. Kontrola `--check` obejmuje również te kopie.
Pełnej polityki nie skracaj przez usuwanie informacji o danych, prawach i dostawcach.

Opublikuj HTML w hostingu domeny `sedno.xyz`. Sekcja `#prywatnosc` na stronie
głównej zawiera podsumowanie i link do pełnej polityki. Generowanie plików
i wdrożenie API nie aktualizują tej domeny.
Backend osadza te dokumenty przy budowie, więc jego kopia wymaga przebudowania
oraz wdrożenia. Strona usuwania otwiera e-mail — nie usuwa konta automatycznie.
