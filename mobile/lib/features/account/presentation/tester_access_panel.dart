import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sedno_app/features/quota/domain/quota_state.dart';

/// The server decides access; the device clock is used only to format the date.
class TesterAccessPanel extends StatelessWidget {
  const TesterAccessPanel({required this.quota, super.key});

  final ValueListenable<QuotaState?> quota;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<QuotaState?>(
    valueListenable: quota,
    builder: (context, value, _) {
      final expiresAt = value?.testerAccessExpiresAt;
      if (value == null || expiresAt == null) return const SizedBox.shrink();
      final date = expiresAt.toLocal();
      String two(int number) => number.toString().padLeft(2, '0');
      final until =
          '${two(date.day)}.${two(date.month)}.${date.year} r., '
          '${two(date.hour)}:${two(date.minute)}';
      final active = expiresAt.isAfter(value.serverTime);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Text(
            'Dostęp testerski',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          if (active) ...[
            Text('Dostęp testerski do $until (czas lokalny).'),
            const Text('Możesz przetworzyć do 400 tekstów dziennie.'),
            const Text('Dostęp jest bezpłatny i wygaśnie automatycznie.'),
            if (value.tier == QuotaTier.subscription)
              const Text('Masz też aktywną subskrypcję Google Play.'),
          ] else ...[
            const Text('Dostęp testerski wygasł.'),
            Text(
              value.tier == QuotaTier.subscription
                  ? 'Twoja subskrypcja Google Play nadal zapewnia większy limit.'
                  : 'Obowiązuje darmowy limit 5 tekstów dziennie. Dzisiejsze użycie pozostaje bez zmian.',
            ),
          ],
        ],
      );
    },
  );
}
