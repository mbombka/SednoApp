# Niedostępne przetwarzanie tekstu — 23.10.2026

Zgłoszenie: aplikacja pokazuje timeout lub brak połączenia przy próbie operacji.
Podczas kontroli działa rewizja `sedno-api-00014-mmh`.

## Potwierdzone ustalenia

- Hosting API i bezpośredni Cloud Run odpowiadają: `/health/live` i
  `/health/ready` 200; chroniony `/v1/quota` bez uwierzytelnienia 401.
- Metadane produkcyjnych żądań potwierdzają udane logowanie i odczyt limitu,
  a dla przetwarzania tekstu odpowiedzi 503 na etapie wywołania modelu.
- Jednorazowe zadanie diagnostyczne na istniejącym koncie usługi backendu,
  z tym samym odwołaniem do sekretu OpenAI, wykonało próbę na syntetycznym
  tekście. Wynik: **HTTP 429**, `type=insufficient_quota`,
  **`code=credit_balance_exhausted`**.
- Przyczyną potwierdzoną w tym teście jest wyczerpane saldo API OpenAI.
  Nie odczytywano wartości sekretu lokalnie i nie logowano treści ani odpowiedzi AI.
- Tymczasowe zadanie `sedno-model-diagnostic` usunięto po diagnostyce.
  Nie zmieniono kodu, obrazu produkcyjnego, ustawień bezpieczeństwa ani AAB.

## Przywrócenie działania

Właściciel konta rozliczeniowego musi uzupełnić saldo organizacji OpenAI,
z której pochodzi używany przez backend klucz. Sama kolejna próba nie usuwa
tego błędu. Znaczenie kodu potwierdza
[oficjalna dokumentacja OpenAI](https://developers.openai.com/api/docs/guides/error-codes).

Po uzupełnieniu salda należy ponowić test syntetyczny i operację w aplikacji.
Na moment tego raportu przywrócenie przetwarzania nie zostało potwierdzone;
nie wykonano żadnej płatności ani zmiany limitów rozliczeniowych.
