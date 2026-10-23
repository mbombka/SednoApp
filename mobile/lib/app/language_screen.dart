import 'package:flutter/material.dart';
import 'package:sedno_app/app/app_language.dart';
import 'package:sedno_app/l10n/localization.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({required this.controller, super.key});
  final LanguageController controller;
  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  bool _saving = false;
  String? _error;

  Future<void> _select(AppLanguage? language) async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.controller.select(language);
    } catch (_) {
      if (mounted) _error = context.l10n.languageSaveFailed;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.l10n.language)),
    body: ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) => ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(context.l10n.languageNotice),
          const SizedBox(height: 16),
          for (final choice in <AppLanguage?>[null, ...AppLanguage.values])
            ListTile(
              key: ValueKey('language-${choice?.code ?? 'system'}'),
              minVerticalPadding: 16,
              title: Text(
                choice == null
                    ? context.l10n.systemLanguage
                    : choice == AppLanguage.polish
                    ? 'Polski'
                    : 'English (UK)',
              ),
              selected: widget.controller.selected == choice,
              trailing: widget.controller.selected == choice
                  ? const Icon(Icons.check)
                  : null,
              onTap: _saving ? null : () => _select(choice),
            ),
          if (_error != null) Semantics(liveRegion: true, child: Text(_error!)),
        ],
      ),
    ),
  );
}
