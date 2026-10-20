# Dokumenty na stronie Sedno

Publiczne adresy:

- [Pełna polityka prywatności](https://sedno.xyz/prywatnosc/).
- [Instrukcja usunięcia konta](https://sedno.xyz/usun-konto/).
- [Podsumowanie na stronie głównej](https://sedno.xyz/#prywatnosc).

Obie podstrony odpowiadały przez HTTPS podczas kontroli 16.10.2026.
Przed publikacją aplikacji porównaj ich treść z bieżącymi plikami i sprawdź dostęp bez logowania.

20.10.2026 sprawdzono publiczną politykę: zawiera zapis o osobach 13–17 lat,
z datą wersji 19.10.2026. Lokalne pliki strony w osobnym repozytorium
`/home/user/workspace/SednoWebsite/SednoWebsite/public/` ujednolicono z wersją
20.10.2026 i jawnym zapisem „od 13. roku życia”. Dotyczy to polityki i instrukcji
usuwania konta. Te dwa pliki wymagają jeszcze przesłania przez SFTP na hosting OVH;
ich edycja lokalna nie aktualizuje domeny.

## Aktualizacja treści

Edytuj tylko [wspólne źródło JSON](../privacy-policy.pl.json), a następnie z katalogu
głównego projektu uruchom (potrzebne Python 3 i `dart`):

```sh
python3 tools/generate_privacy_policy.py
python3 tools/generate_privacy_policy.py --check
```

Generator aktualizuje politykę Markdown, treść w aplikacji oraz
[prywatnosc/index.html](prywatnosc/index.html) i [usun-konto/index.html](usun-konto/index.html).
Pełnej polityki nie skracaj przez usuwanie informacji o danych, prawach i dostawcach.

Opublikuj HTML w hostingu domeny `sedno.xyz`; osobno zaktualizuj odnośnik w sekcji
`#prywatnosc`. Generowanie plików i wdrożenie API nie aktualizują tej domeny.
Backend osadza te dokumenty przy budowie, więc jego kopia wymaga przebudowania
oraz wdrożenia. Strona usuwania otwiera e-mail — nie usuwa konta automatycznie.
