import 'dart:io';

import 'package:sedno_app/l10n/localization.dart';
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
      final resetTime = context.l10n.resetDaily(
        QuotaReset.localTime(resetAt: quota?.value?.resetAt),
      );
      // Plain Polish: one sentence per line.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Separates the subscription from the account actions above it.
          const SizedBox(height: 40),
          const Divider(),
          const SizedBox(height: 16),
          Text(context.l10n.subscription, style: textTheme.titleLarge),
          const SizedBox(height: 8),
          if (active) ...[
            _Benefit(context.l10n.subscriptionActive),
            _Benefit(context.l10n.subscriptionAllowance),
            _Benefit(resetTime),
            const SizedBox(height: 16),
            if (model.managedElsewhere)
              Text(context.l10n.subscriptionOtherStore)
            else
              Text(
                (Platform.isIOS
                    ? context.l10n.appleManageSubscriptionNotice
                    : context.l10n.manageSubscriptionNotice),
              ),
            const SizedBox(height: 8),
            if (!model.managedElsewhere)
              TextButton(
                onPressed: model.busy ? null : model.manage,
                child: Text(
                  (Platform.isIOS
                      ? context.l10n.appleManageSubscription
                      : context.l10n.manageSubscription),
                ),
              ),
          ] else if (tester) ...[
            Text(context.l10n.testerAccessNotice),
            OutlinedButton(
              onPressed: model.busy ? null : model.restore,
              child: Text(context.l10n.restorePurchases),
            ),
            TextButton(
              onPressed: model.busy ? null : model.refresh,
              child: Text(context.l10n.refreshAccess),
            ),
          ] else ...[
            if (model.offer != null) ...[
              Text(
                context.l10n.monthlyPrice(model.offer!.price),
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
            ],
            _Benefit(context.l10n.subscriptionBenefits),
            _Benefit(resetTime),
            const SizedBox(height: 16),
            if (!signedIn) ...[
              Text(context.l10n.subscriptionSignInNotice),
              const SizedBox(height: 8),
            ],
            FilledButton(
              onPressed: model.busy || model.offer == null ? null : model.buy,
              child: Text(context.l10n.buySubscription),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: model.busy ? null : model.restore,
              child: Text(context.l10n.restorePurchases),
            ),
            TextButton(
              onPressed: model.busy ? null : model.refresh,
              child: Text(context.l10n.refreshSubscription),
            ),
            const SizedBox(height: 8),
            Text(context.l10n.subscriptionRenewalNotice),
            Text(
              (Platform.isIOS
                  ? context.l10n.appleSubscriptionCancelNotice
                  : context.l10n.subscriptionCancelNotice),
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
