import 'package:flutter/material.dart';
import 'package:sedno_app/features/subscription/presentation/subscription_view_model.dart';

class SubscriptionPanel extends StatelessWidget {
  const SubscriptionPanel({required this.model, super.key});
  final SubscriptionViewModel model;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model,
    builder: (context, _) {
      final active = model.status?.active == true;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Separates the subscription from the account actions above it.
          const SizedBox(height: 40),
          const Divider(),
          const SizedBox(height: 16),
          Text('Subskrypcja', style: Theme.of(context).textTheme.titleLarge),
          const Text('400 uproszczeń dziennie. Limit odnawia się o 00:00 UTC.'),
          if (active) ...[
            const Text('Subskrypcja jest aktywna.'),
            const Text(
              'W Google Play możesz zmienić płatność lub anulować odnawianie subskrypcji.',
            ),
            TextButton(
              onPressed: model.busy ? null : model.manage,
              child: const Text('Zarządzaj subskrypcją w Google Play'),
            ),
          ] else ...[
            if (model.offer != null)
              Text(
                '${model.offer!.price} miesięcznie. Subskrypcja odnawia się automatycznie. Możesz ją anulować w Google Play.',
              ),
            const Text(
              'Aby kupić lub przywrócić subskrypcję, zaloguj się na swoje konto Sedno.',
            ),
            FilledButton(
              onPressed: model.busy || model.offer == null ? null : model.buy,
              child: const Text('Kup subskrypcję'),
            ),
            OutlinedButton(
              onPressed: model.busy ? null : model.restore,
              child: const Text('Przywróć zakupy'),
            ),
            TextButton(
              onPressed: model.busy ? null : model.refresh,
              child: const Text('Odśwież subskrypcję'),
            ),
          ],
          if (model.busy) const Center(child: CircularProgressIndicator()),
          if (model.message != null)
            Text(model.message!, semanticsLabel: model.message),
        ],
      );
    },
  );
}
