import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  static const aiNotice =
      'Twój tekst trafi przez serwer Sedno do dostawcy AI, aby go uprościć. '
      'Nie wpisuj danych, których nie chcesz przekazywać. '
      'Zdjęcia zostają na urządzeniu. AI może popełniać błędy. Sprawdź wynik.';
  static const deletionNotice =
      'Usuniemy konto Sedno, jego dane na serwerze i lokalną historię na tym urządzeniu. '
      'Tej czynności nie można cofnąć. '
      'Usunięcie konta nie anuluje subskrypcji. '
      'Aby zatrzymać opłaty, otwórz Google Play → Płatności i subskrypcje → '
      'Subskrypcje → Sedno → Anuluj subskrypcję.';

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Prywatność i dane')),
    body: const SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(aiNotice),
          SizedBox(height: 16),
          Text(
            'Serwer nie zapisuje tekstu ani wyniku. Zdjęcia i rozpoznawanie tekstu pozostają na urządzeniu. Historia jest szyfrowana, przechowywana lokalnie przez 7 dni i wyłączona z kopii zapasowych. Możesz usuwać wpisy w zakładce Historia. Wylogowanie czyści historię.',
          ),
          SizedBox(height: 16),
          Text(
            'Identyfikator instalacji jest pseudonimowy. Serwer zapisuje dane sesji, konta, limitów i zakupów. Logowanie nie odnawia darmowego limitu. Metadane żądań są usuwane po 8 dniach, wygasłe sesje podczas okresowego czyszczenia.',
          ),
          SizedBox(height: 16),
          Text(deletionNotice),
          SizedBox(height: 16),
          Text(
            'Usunięcie przez stronę internetową nie czyści historii na urządzeniach. Usuń ją w aplikacji lub usuń dane aplikacji w ustawieniach Androida. Dane Google Play podlegają zasadom Google.',
          ),
          SizedBox(height: 16),
          Text(
            'Projekt informacji o prywatności — DO UZUPEŁNIENIA przed publikacją: administrator i kontakt, dostawca AI, podmioty przetwarzające, podstawy prawne, transfery, okresy przechowywania kont i kopii serwera oraz adres publicznej polityki i strony usuwania konta. Produkcyjne AI jest obecnie wyłączone; model demonstracyjny działa tylko w środowisku deweloperskim.',
          ),
        ],
      ),
    ),
  );
}
