import 'dart:io';

import 'package:sedno_app/l10n/localization.dart';
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
      final dates = MaterialLocalizations.of(context);
      final until =
          '${dates.formatCompactDate(date)}, ${dates.formatTimeOfDay(TimeOfDay.fromDateTime(date), alwaysUse24HourFormat: true)}';
      final active = expiresAt.isAfter(value.serverTime);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 24),
          Text(
            context.l10n.testerAccess,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          if (active) ...[
            Text(context.l10n.testerUntil(until)),
            Text(context.l10n.testerAllowance),
            Text(context.l10n.testerExpiryNotice),
            if (value.tier == QuotaTier.subscription)
              Text(
                (Platform.isIOS
                    ? context.l10n.appleTesterHasSubscription
                    : context.l10n.testerHasSubscription),
              ),
          ] else ...[
            Text(context.l10n.testerExpired),
            Text(
              value.tier == QuotaTier.subscription
                  ? (Platform.isIOS
                        ? context.l10n.appleSubscriptionStillActive
                        : context.l10n.subscriptionStillActive)
                  : context.l10n.freeLimitRestored,
            ),
          ],
        ],
      );
    },
  );
}
