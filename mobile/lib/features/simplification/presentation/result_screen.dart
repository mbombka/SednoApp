import 'package:flutter/material.dart';
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
            const SizedBox(height: 24),
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
            FilledButton(
              onPressed: _newText,
              style: FilledButton.styleFrom(
                minimumSize: const Size(0, 56),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
              child: const Text('Nowy tekst'),
            ),
          ],
        ),
      ),
    ),
  );
}
