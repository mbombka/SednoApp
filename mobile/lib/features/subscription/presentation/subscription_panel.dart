import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sedno_app/features/quota/domain/quota_reset.dart';
import 'package:sedno_app/features/quota/domain/quota_state.dart';
import 'package:sedno_app/features/subscription/presentation/subscription_view_model.dart';

class SubscriptionPanel extends StatelessWidget {
  const SubscriptionPanel({
    required this.model,
    this.signedIn = false,
    this.quota,
    super.key,
  });
  final SubscriptionViewModel model;
  final bool signedIn;

  /// Server quota with the next reset moment; null before the first read.
  final ValueListenable<QuotaState?>? quota;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: Listenable.merge([model, quota]),
    builder: (context, _) {
      final textTheme = Theme.of(context).textTheme;
      final active = model.status?.active == true;
      final tester = signedIn && quota?.value?.tier == QuotaTier.tester;
      final resetTime =
          'Nowy limit codziennie o '
          '${QuotaReset.localTime(resetAt: quota?.value?.resetAt)}.';
      // Plain Polish: one sentence per line.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Separates the subscription from the account actions above it.
          const SizedBox(height: 40),
          const Divider(),
          const SizedBox(height: 16),
          Text('Subskrypcja', style: textTheme.titleLarge),
          const SizedBox(height: 8),
          if (active) ...[
            const _Benefit('Subskrypcja jest aktywna.'),
            const _Benefit('Możesz uprościć do 400 tekstów dziennie.'),
            _Benefit(resetTime),
            const SizedBox(height: 16),
            const Text(
              'Aby zmienić płatność lub anulować subskrypcję, przejdź do Google Play.',
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: model.busy ? null : model.manage,
              child: const Text('Zarządzaj subskrypcją w Google Play'),
            ),
          ] else if (tester) ...[
            const Text('Korzystasz z bezpłatnego dostępu testerskiego.'),
            OutlinedButton(
              onPressed: model.busy ? null : model.restore,
              child: const Text('Przywróć zakupy'),
            ),
            TextButton(
              onPressed: model.busy ? null : model.refresh,
              child: const Text('Odśwież dostęp'),
            ),
          ] else ...[
            if (model.offer != null) ...[
              Text(
                '${model.offer!.price} miesięcznie',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
            ],
            const _Benefit(
              'Możesz uprościć do 400 tekstów dziennie (bez subskrypcji: 5).',
            ),
            _Benefit(resetTime),
            const SizedBox(height: 16),
            if (!signedIn) ...[
              const Text(
                'Aby kupić lub przywrócić subskrypcję, zaloguj się na swoje konto Sedno.',
              ),
              const SizedBox(height: 8),
            ],
            FilledButton(
              onPressed: model.busy || model.offer == null ? null : model.buy,
              child: const Text('Kup subskrypcję'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: model.busy ? null : model.restore,
              child: const Text('Przywróć zakupy'),
            ),
            TextButton(
              onPressed: model.busy ? null : model.refresh,
              child: const Text('Odśwież subskrypcję'),
            ),
            const SizedBox(height: 8),
            const Text('Subskrypcja odnawia się automatycznie co miesiąc.'),
            const Text('Możesz ją anulować w każdej chwili w Google Play.'),
          ],
          if (model.busy) const Center(child: CircularProgressIndicator()),
          if (model.message != null)
            Text(model.message!, semanticsLabel: model.message),
        ],
      );
    },
  );
}

/// A benefit line with a decorative check mark that TalkBack does not read.
class _Benefit extends StatelessWidget {
  const _Benefit(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Icon(
            Icons.check,
            // Grows with the system text size, like the text next to it.
            size: MediaQuery.textScalerOf(context).scale(20),
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    ),
  );
}
