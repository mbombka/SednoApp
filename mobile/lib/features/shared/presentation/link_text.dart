import 'package:sedno_app/l10n/localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

typedef UrlOpener = Future<bool> Function(Uri uri);

/// Opens web pages in the browser, outside the app.
Future<bool> openExternalUrl(Uri uri) =>
    launchUrl(uri, mode: LaunchMode.externalApplication);

/// Opens [uri] and tells the user when no browser could open it.
Future<void> openLink(BuildContext context, Uri uri, UrlOpener opener) async {
  var opened = false;
  try {
    opened = await opener(uri);
  } catch (_) {
    opened = false;
  }
  if (opened || !context.mounted) return;
  ScaffoldMessenger.maybeOf(context)
      ?.showSnackBar(SnackBar(content: Text(context.l10n.websiteOpenFailed)));
}

/// Text in which every https:// address is a tappable link.
class LinkText extends StatefulWidget {
  const LinkText(this.text, {this.opener = openExternalUrl, super.key});

  final String text;
  final UrlOpener opener;

  // Sentence punctuation after an address is not part of it.
  static final _address = RegExp(r'https://[^\s]+?(?=[.,;:)]*(\s|$))');

  @override
  State<LinkText> createState() => _LinkTextState();
}

class _LinkTextState extends State<LinkText> {
  final _recognizers = <TapGestureRecognizer>[];

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    final matches = LinkText._address.allMatches(widget.text).toList();
    if (matches.isEmpty) return Text(widget.text);
    final linkStyle = TextStyle(
      color: Theme.of(context).colorScheme.primary,
      decoration: TextDecoration.underline,
    );
    final spans = <InlineSpan>[];
    var start = 0;
    for (final match in matches) {
      spans.add(TextSpan(text: widget.text.substring(start, match.start)));
      final address = match.group(0)!;
      final recognizer = TapGestureRecognizer()
        ..onTap = () => openLink(context, Uri.parse(address), widget.opener);
      _recognizers.add(recognizer);
      spans.add(
        TextSpan(text: address, style: linkStyle, recognizer: recognizer),
      );
      start = match.end;
    }
    spans.add(TextSpan(text: widget.text.substring(start)));
    return Text.rich(TextSpan(children: spans));
  }
}
