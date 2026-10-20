import 'package:flutter/material.dart';
import 'package:sedno_app/app/app_information.dart';
import 'package:sedno_app/features/quota/domain/quota_reset.dart';
import 'package:sedno_app/features/shared/presentation/link_text.dart';
import 'package:sedno_app/features/shared/presentation/website_information.dart';
import 'package:sedno_app/features/privacy/presentation/privacy_screen.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({this.openUrl = openExternalUrl, super.key});

  final UrlOpener openUrl;

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
          // Plain Polish: short sections, one sentence per line.
          const _Heading('Do czego służy'),
          const Text('Sedno upraszcza trudne polskie teksty.'),
          const Text(
            'Powstało dla osób słabosłyszących i osób, którym trudno zrozumieć złożony tekst.',
          ),
          const Text('Aplikacja jest dla osób od 13 lat.'),
          const _Heading('Jak to działa'),
          const Text('Wpisz lub wklej tekst albo zrób zdjęcie tekstu.'),
          const Text('Przed wysłaniem możesz poprawić odczytany tekst.'),
          const Text('Tekst może mieć najwyżej 4000 znaków.'),
          const Text('Możesz zacząć bez zakładania konta.'),
          const _Heading('Dzienny limit'),
          const Text('Bez subskrypcji: 5 tekstów dziennie.'),
          const Text('Z subskrypcją: 400 tekstów dziennie.'),
          const Text(
            'Cenę subskrypcji zobaczysz w menu Konto i w Google Play.',
          ),
          // Local clock time first; UTC for users comparing with other sources.
          Text(
            'Nowy limit codziennie o ${QuotaReset.localTime()} (00:00 UTC).',
          ),
          const _Heading('Ważne'),
          const Text('AI może popełniać błędy.'),
          const Text('Sprawdź wynik, zanim go wykorzystasz.'),
          const _Heading('Kontakt'),
          const Text('Autor: Mariusz Bąbka'),
          const SizedBox(height: 8),
          const Text('Kontakt: ${AppInformation.contact}'),
          const SizedBox(height: 16),
          WebsiteInformation(opener: openUrl),
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

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 8),
    child: Semantics(
      header: true,
      child: Text(text, style: Theme.of(context).textTheme.titleMedium),
    ),
  );
}
