import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedno_app/features/account/presentation/tester_access_panel.dart';
import 'package:sedno_app/features/quota/domain/quota_state.dart';

void main() {
  final now = DateTime.utc(2026, 10, 22, 12);
  QuotaState quota({QuotaTier tier = QuotaTier.tester, bool expired = false}) =>
      QuotaState(
        tier: tier,
        limit: tier == QuotaTier.free ? 5 : 400,
        used: 30,
        remaining: tier == QuotaTier.free ? 0 : 370,
        serverTime: now,
        resetAt: DateTime.utc(2026, 10, 23),
        testerAccessExpiresAt: expired
            ? now
            : now.add(const Duration(days: 14)),
      );

  testWidgets(
    'shows free access and reacts to expiry, subscription and removal',
    (tester) async {
      final state = ValueNotifier<QuotaState?>(quota());
      addTearDown(state.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TesterAccessPanel(quota: state)),
        ),
      );
      expect(find.text('Dostęp testerski'), findsOneWidget);
      expect(
        find.text('Dostęp jest bezpłatny i wygaśnie automatycznie.'),
        findsOneWidget,
      );
      expect(find.textContaining('400 tekstów'), findsOneWidget);
      expect(find.textContaining('Kup'), findsNothing);

      state.value = quota(tier: QuotaTier.subscription);
      await tester.pump();
      expect(
        find.text('Masz też aktywną subskrypcję Google Play.'),
        findsOneWidget,
      );

      state.value = quota(tier: QuotaTier.subscription, expired: true);
      await tester.pump();
      expect(find.text('Dostęp testerski wygasł.'), findsOneWidget);
      expect(find.textContaining('nadal zapewnia'), findsOneWidget);

      state.value = quota(tier: QuotaTier.free, expired: true);
      await tester.pump();
      expect(
        find.textContaining('Dzisiejsze użycie pozostaje bez zmian.'),
        findsOneWidget,
      );

      state.value = null;
      await tester.pump();
      expect(find.text('Dostęp testerski'), findsNothing);
    },
  );

  testWidgets('supports large text and TalkBack labels', (tester) async {
    final state = ValueNotifier<QuotaState?>(quota());
    addTearDown(state.dispose);
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: SingleChildScrollView(child: TesterAccessPanel(quota: state)),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.bySemanticsLabel('Dostęp testerski'), findsOneWidget);
    semantics.dispose();
  });
}
