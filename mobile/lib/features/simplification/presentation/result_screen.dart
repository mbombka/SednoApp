import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sedno_app/features/simplification/domain/simplification_result.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({
    required this.result,
    required this.originalText,
    required this.onNewText,
    super.key,
  });

  final SimplificationResult result;
  final String originalText;
  final VoidCallback onNewText;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _showOriginal = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.result.text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Skopiowano uproszczony tekst.')),
    );
  }

  void _newText() {
    widget.onNewText();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Uproszczony tekst')),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SelectableText(
              widget.result.text,
              key: const Key('simplifiedText'),
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            const Text(
              'Uwaga: AI może popełniać błędy. Sprawdź ważne informacje w oryginale.',
              key: Key('aiErrorWarning'),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _copy,
              icon: const Icon(Icons.copy_outlined, semanticLabel: 'Kopiuj'),
              label: const Text('Kopiuj'),
              style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => setState(() => _showOriginal = !_showOriginal),
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
              child: Text(_showOriginal ? 'Ukryj oryginał' : 'Pokaż oryginał'),
            ),
            if (_showOriginal) ...[
              const SizedBox(height: 16),
              Text(
                'Oryginalny tekst',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              SelectableText(
                widget.originalText,
                key: const Key('originalText'),
              ),
            ],
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _newText,
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
              child: const Text('Nowy tekst'),
            ),
          ],
        ),
      ),
    ),
  );
}
