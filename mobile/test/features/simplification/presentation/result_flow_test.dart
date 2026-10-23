import '../../../helpers.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedno_app/app/app.dart';
import 'package:sedno_app/features/quota/domain/quota_state.dart';
import 'package:sedno_app/features/simplification/domain/simplification_repository.dart';
import 'package:sedno_app/features/simplification/domain/simplification_result.dart';

class StubRepository implements SimplificationRepository {
  StubRepository(this.action);
  final Future<SimplificationResponse> Function(SimplificationRequest) action;
  @override
  Future<SimplificationResponse> simplify(SimplificationRequest request) =>
      action(request);
}

SimplificationResponse response(String id) => SimplificationResponse(
  result: SimplificationResult(
    id: id,
    text: 'To jest prosty tekst.',
    createdAt: DateTime.utc(2026, 10, 14),
  ),
  quota: QuotaState(
    tier: QuotaTier.free,
    limit: 5,
    used: 1,
    remaining: 4,
    serverTime: DateTime.utc(2026, 10, 14),
    resetAt: DateTime.utc(2026, 10, 15),
  ),
);

void main() {
  testWidgets('success replaces editor text and header restores original', (
    tester,
  ) async {
    String? sentText;
    await tester.pumpWidget(
      SednoApp(
        simplificationRepository: StubRepository((request) async {
          sentText = request.input.value;
          return response(request.requestId);
        }),
      ),
    );
    await tester.enterText(find.byType(TextField), 'Trudny tekst');
    await submitText(tester);
    await tester.pumpAndSettle();

    expect(sentText, 'Trudny tekst');
    expect(tester.testTextInput.isVisible, isFalse);
    expect(find.text('Uproszczony tekst'), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'To jest prosty tekst.',
    );
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);
    expect(find.byKey(const Key('aiErrorWarning')), findsOneWidget);
    expect(find.text('Pokaż oryginał'), findsNothing);
    expect(find.text('Nowy tekst'), findsNothing);
    expect(find.text('Kopiuj'), findsNothing);

    await tester.tap(find.byKey(const Key('restoreOriginalButton')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Trudny tekst',
    );
    expect(find.text('Sedno - uprość tekst:'), findsOneWidget);
    expect(find.byKey(const Key('restoreOriginalButton')), findsNothing);
  });

  testWidgets('error keeps input and retry replaces it with result', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      SednoApp(
        simplificationRepository: StubRepository((request) async {
          if (calls++ == 0) throw StateError('private detail');
          return response(request.requestId);
        }),
      ),
    );
    await tester.enterText(find.byType(TextField), 'Zachowaj tekst');
    await submitText(tester);
    await tester.pump();
    expect(
      find.text('Nie udało się uprościć tekstu. Spróbuj ponownie.'),
      findsOneWidget,
    );
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Zachowaj tekst',
    );
    await submitText(tester);
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.text('To jest prosty tekst.'), findsOneWidget);
  });

  testWidgets('back from result preserves the original editor text', (
    tester,
  ) async {
    await tester.pumpWidget(
      SednoApp(
        simplificationRepository: StubRepository(
          (request) async => response(request.requestId),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'Tekst do poprawy');
    await submitText(tester);
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'Tekst do poprawy',
    );
  });
}
