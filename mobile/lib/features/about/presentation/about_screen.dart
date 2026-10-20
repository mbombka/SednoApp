import 'package:flutter/material.dart';
import 'package:sedno_app/app/app_information.dart';
import 'package:sedno_app/features/shared/presentation/website_information.dart';
import 'package:sedno_app/features/privacy/presentation/privacy_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('O aplikacji'),
      leading: Navigator.of(context).canPop()
          ? IconButton(
              tooltip: 'Wróć',
              style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(Icons.arrow_back),
            )
          : null,
    ),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Semantics(
            header: true,
            child: Text(
              'Sedno',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Sedno pomaga zrozumieć trudne polskie teksty. Powstało z myślą '
            'o osobach słabosłyszących i osobach, którym trudno zrozumieć złożony tekst. '
            'Aplikacja jest przeznaczona dla osób od 13. roku życia.',
          ),
          const SizedBox(height: 16),
          const Text(
            'Wpisz lub wklej tekst albo zrób zdjęcie. Możesz poprawić odczytany tekst '
            'przed wysłaniem. Maksymalna długość to 4000 znaków. '
            'Możesz zacząć bez konta.',
          ),
          const SizedBox(height: 16),
          const Text(
            'Bezpłatnie możesz uprościć 5 tekstów dziennie. Subskrypcja Sedno '
            'kosztuje 9,99 zł miesięcznie i pozwala uprościć łącznie 400 tekstów dziennie. '
            'Przed zakupem sprawdź cenę w Google Play. Limity odnawiają się '
            'o 00:00 UTC według czasu serwera.',
          ),
          const SizedBox(height: 16),
          const Text(
            'AI może popełniać błędy. Sprawdź wynik, zanim go wykorzystasz.',
          ),
          const SizedBox(height: 24),
          const Text('Autor: Mariusz Bąbka'),
          const SizedBox(height: 8),
          const Text('Kontakt: ${AppInformation.contact}'),
          const SizedBox(height: 16),
          const WebsiteInformation(),
          const SizedBox(height: 16),
          TextButton(
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(builder: (_) => const PrivacyScreen()),
            ),
            child: const Text('Prywatność i dane'),
          ),
        ],
      ),
    ),
  );
}
