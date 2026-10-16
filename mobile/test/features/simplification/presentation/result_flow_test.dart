import '../../../helpers.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  testWidgets(
    'success opens result, copies, shows original and starts new text',
    (tester) async {
      String? sentText;
      String? copiedText;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copiedText =
                (call.arguments as Map<Object?, Object?>)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
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
      expect(find.text('Uproszczony tekst'), findsOneWidget);
      expect(find.text('To jest prosty tekst.'), findsOneWidget);
      expect(find.byKey(const Key('aiErrorWarning')), findsOneWidget);
      expect(find.byType(TabBar), findsNothing);
      expect(find.byKey(const Key('originalText')), findsNothing);

      await tester.tap(find.text('Pokaż oryginał'));
      await tester.pump();
      expect(find.text('Trudny tekst'), findsOneWidget);
      await tester.tap(find.text('Ukryj oryginał'));
      await tester.pump();
      expect(find.byKey(const Key('originalText')), findsNothing);

      await tester.tap(find.text('Kopiuj'));
      await tester.pump();
      expect(copiedText, 'To jest prosty tekst.');
      expect(find.text('Skopiowano uproszczony tekst.'), findsOneWidget);

      await tester.tap(find.text('Nowy tekst'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
    },
  );

  testWidgets('error keeps input and retry opens result', (tester) async {
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
