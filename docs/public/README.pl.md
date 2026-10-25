# Dokumenty na stronie Sedno

Publiczne adresy:

- [Pełna polityka prywatności](https://sedno.xyz/prywatnosc/).
- [Instrukcja usunięcia konta](https://sedno.xyz/usun-konto/).
- [Podsumowanie na stronie głównej](https://sedno.xyz/#prywatnosc).

Dokumenty w `docs/public/` są osadzane w backendzie. Strona OVH w
`website/SednoWebsite/public/` korzysta z tych samych źródeł polityki, ale ma
własny układ i przełącznik języka. Generator polskiej polityki tworzy dokumenty
backendu i stare polskie adresy strony. Pozostałe wersje strony tworzy
`python3 tools/generate_website.py`. Edycja repozytorium nie zmienia
strony `sedno.xyz`. Przed publikacją sprawdź dostępność i wersję dokumentów online.

## Aktualizacja treści

Edytuj tylko [wspólne źródło JSON](../privacy-policy.pl.json), a następnie z katalogu
głównego projektu uruchom (potrzebne Python 3 i `dart`):

```sh
python3 tools/generate_privacy_policy.py
python3 tools/generate_privacy_policy.py --check
```

Generator aktualizuje politykę Markdown, treść w aplikacji oraz
[prywatnosc/index.html](prywatnosc/index.html) i [usun-konto/index.html](usun-konto/index.html), a także polskie strony pod starymi adresami w
`website/SednoWebsite/public/`. Kontrola `--check` obejmuje również te strony.
Po zmianie dowolnego źródła polityki uruchom też generator całej strony:

```sh
python3 tools/generate_website.py
python3 tools/generate_website.py --check
```

[Opis wszystkich adresów i źródeł tłumaczeń](../../website/SednoWebsite/README.md).
Pełnej polityki nie skracaj przez usuwanie informacji o danych, prawach i dostawcach.

Opublikuj HTML w hostingu domeny `sedno.xyz`. Sekcja `#prywatnosc` na stronie
głównej zawiera podsumowanie i link do pełnej polityki. Generowanie plików
i wdrożenie API nie aktualizują tej domeny.
Backend osadza te dokumenty przy budowie, więc jego kopia wymaga przebudowania
oraz wdrożenia. Strona usuwania otwiera e-mail — nie usuwa konta automatycznie.
