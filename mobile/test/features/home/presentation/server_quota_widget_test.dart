import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedno_app/features/home/presentation/home_screen.dart';
import 'package:sedno_app/features/quota/domain/quota_repository.dart';
import 'package:sedno_app/features/quota/domain/quota_state.dart';
import 'package:sedno_app/features/simplification/domain/simplification_repository.dart';
import 'package:sedno_app/features/simplification/domain/simplification_result.dart';

class _ServerQuotaRepository
    implements SimplificationRepository, QuotaStateSource {
  final ValueNotifier<QuotaState?> state = ValueNotifier(null);

  @override
  ValueListenable<QuotaState?> get quotaListenable => state;

  @override
  Future<QuotaState> current() async => state.value!;

  @override
  Future<SimplificationResponse> simplify(SimplificationRequest request) =>
      Future.error(StateError('unavailable'));
}

QuotaState _quota(int used, {int day = 14}) => QuotaState(
  tier: QuotaTier.free,
  limit: 2,
  used: used,
  remaining: 2 - used,
  serverTime: DateTime.utc(2026, 10, day, 12),
  resetAt: DateTime.utc(2026, 10, day + 1),
);

void main() {
  testWidgets(
    'server quota hides full counter, blocks at zero, and reopens after reset',
    (tester) async {
      final repository = _ServerQuotaRepository();
      repository.state.value = _quota(0);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeScreen(
              appName: 'Sedno',
              textController: TextEditingController(text: 'Tekst'),
              simplificationRepository: repository,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byKey(const Key('quotaMessage')), findsNothing);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Uprość'))
            .onPressed,
        isNotNull,
      );

      repository.state.value = _quota(1);
      await tester.pump();
      expect(find.byKey(const Key('quotaMessage')), findsNothing);
      await tester.tap(find.text('Uprość'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Pozostało 1 uproszczenie'), findsOneWidget);
      expect(find.textContaining('za 12 godz.'), findsOneWidget);
      await tester.tap(find.text('Zamknij'));
      await tester.pumpAndSettle();

      repository.state.value = _quota(2);
      await tester.pump();
      await tester.tap(find.text('Uprość'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Wykorzystano dzienny limit'), findsOneWidget);
      expect(find.text('Dalej'), findsNothing);
      expect(find.text('Rozumiem, wyślij'), findsNothing);
      await tester.tap(find.text('Zamknij'));
      await tester.pumpAndSettle();

      repository.state.value = _quota(0, day: 15);
      await tester.pump();
      expect(find.byKey(const Key('quotaMessage')), findsNothing);
      expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, 'Uprość'))
            .onPressed,
        isNotNull,
      );
    },
  );
}
