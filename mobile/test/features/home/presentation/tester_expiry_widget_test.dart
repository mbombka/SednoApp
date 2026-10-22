import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedno_app/features/home/presentation/home_screen.dart';
import 'package:sedno_app/features/quota/domain/quota_repository.dart';
import 'package:sedno_app/features/quota/domain/quota_state.dart';
import 'package:sedno_app/features/simplification/domain/simplification_repository.dart';
import 'package:sedno_app/features/simplification/domain/simplification_result.dart';

class _QuotaRepository implements SimplificationRepository, QuotaStateSource {
  final state = ValueNotifier<QuotaState?>(null);
  QuotaState? next;
  int calls = 0;

  @override
  ValueListenable<QuotaState?> get quotaListenable => state;
  @override
  Future<QuotaState> current() async {
    calls++;
    if (next != null) state.value = next;
    return state.value!;
  }

  @override
  Future<SimplificationResponse> simplify(SimplificationRequest request) =>
      throw StateError('Unexpected AI request');
}

void main() {
  testWidgets(
    'refreshes at tester expiry using server time without periodic polling',
    (tester) async {
      final now = DateTime.utc(2026, 10, 22, 12);
      final expiry = now.add(const Duration(seconds: 5));
      final repository = _QuotaRepository();
      repository.state.value = QuotaState(
        tier: QuotaTier.tester,
        limit: 400,
        used: 30,
        remaining: 370,
        serverTime: now,
        resetAt: DateTime.utc(2026, 10, 23),
        testerAccessExpiresAt: expiry,
      );
      final controller = TextEditingController(text: 'Tekst');
      addTearDown(controller.dispose);
      addTearDown(repository.state.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeScreen(
              appName: 'Sedno',
              textController: controller,
              simplificationRepository: repository,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(repository.calls, 1);
      repository.next = QuotaState(
        tier: QuotaTier.free,
        limit: 5,
        used: 30,
        remaining: 0,
        serverTime: expiry,
        resetAt: DateTime.utc(2026, 10, 23),
        testerAccessExpiresAt: expiry,
      );
      await tester.pump(const Duration(seconds: 6));
      await tester.pump();
      expect(repository.calls, 2);
      expect(repository.state.value!.tier, QuotaTier.free);
      await tester.pump(const Duration(minutes: 1));
      expect(repository.calls, 2);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
