using System.Net;

public static class DeletionPage
{
    public static string Render(string? email)
    {
        var contact = !string.IsNullOrWhiteSpace(email) && System.Net.Mail.MailAddress.TryCreate(email, out _)
            ? $"<p><a href=\"mailto:{WebUtility.HtmlEncode(Uri.EscapeDataString(email))}?subject=Pro%C5%9Bba%20o%20usuni%C4%99cie%20konta%20Sedno\">Wyślij prośbę o usunięcie konta i danych</a></p><p>Podaj adres e-mail konta Sedno. Nie wysyłaj hasła, zdjęć ani tekstów. Zweryfikujemy, że konto należy do Ciebie, zanim usuniemy dane. Samo wysłanie wiadomości nie usuwa konta.</p>"
            : "<p>Wersja robocza: BRAK adresu kontaktowego. Zgłoszenia przez stronę są niedostępne.</p>";
        return $$"""
            <!doctype html><html lang="pl"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
            <title>Sedno — usunięcie konta i danych</title>
            <style>body{background:#f8fafc;color:#132440;font:1.125rem/1.6 system-ui;margin:0}main{max-width:42rem;margin:auto;padding:24px}a{color:#064ea1;display:inline-block;min-height:48px}h1{line-height:1.3}</style>
            <main><h1>Sedno: usuń konto i dane</h1>
            <p>Strona aplikacji: <a href="https://sedno.xyz">sedno.xyz</a>.</p>
            <p>Możesz poprosić o usunięcie konta bez instalowania aplikacji.</p>{{contact}}
            <p>W aplikacji: otwórz Konto, wybierz Usuń konto i potwierdź.</p>
            <h2>Co usuwamy</h2><p>Usuwamy konto logowania Sedno w Firebase, sesje, powiązane identyfikatory instalacji, metadane żądań i zapis zakupu na serwerze. Nie przechowujemy tekstów ani zdjęć na serwerze. Historia jest tylko na urządzeniu: w aplikacji usuń historię lub dane aplikacji w ustawieniach Androida. Usunięcie przez aplikację czyści jej lokalną historię.</p>
            <p>Usunięcie konta nie anuluje subskrypcji. Aby zatrzymać opłaty, otwórz Google Play → Płatności i subskrypcje → Subskrypcje → Sedno → Anuluj subskrypcję. Konto Google pozostaje aktywne.</p>
            <p>Informacje o zakupie przechowywane przez Google podlegają zasadom Google. Odpowiadamy bez zbędnej zwłoki, co do zasady w ciągu miesiąca; możliwe jest przedłużenie zgodnie z RODO, o którym poinformujemy w pierwszym miesiącu. Dla planowanego wdrożenia przyjmujemy kopie serwera do 30 dni; wymaga to konfiguracji hostingu. Korespondencję przechowujemy według przyjętej zasady do 90 dni od zamknięcia sprawy, a minimalne potwierdzenie obsługi praw do 12 miesięcy.</p>
            <p><a href="/prywatnosc">Pełna polityka prywatności Sedno</a></p>
            </main></html>
            """;
    }
}
