import 'package:flutter/material.dart';
import 'package:sedno_app/features/shared/presentation/link_text.dart';
import 'package:sedno_app/features/shared/presentation/website_information.dart';
import 'package:sedno_app/features/privacy/domain/privacy_policy.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({this.openUrl = openExternalUrl, super.key});

  /// Opens web addresses from the policy in the browser.
  final UrlOpener openUrl;

  static const aiNotice = PrivacyPolicy.aiNotice;
  static const deletionNotice = PrivacyPolicy.deletionNotice;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Prywatność i dane'),
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Wersja: ${PrivacyPolicy.versionLabel}'),
            const SizedBox(height: 16),
            WebsiteInformation(opener: openUrl),
            for (final section in PrivacyPolicy.sections) ...[
              const SizedBox(height: 24),
              _Heading(section.title),
              for (final paragraph in section.paragraphs) ...[
                LinkText(paragraph, opener: openUrl),
                const SizedBox(height: 16),
              ],
            ],
          ],
        ),
      ),
    ),
  );
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Semantics(
      header: true,
      child: Text(text, style: Theme.of(context).textTheme.titleLarge),
    ),
  );
}
