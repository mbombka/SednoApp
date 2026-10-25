import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedno_app/app/app.dart';
import 'package:sedno_app/features/home/presentation/home_screen.dart';
import 'package:sedno_app/features/privacy/data/local_ai_notice_repository.dart';

import '../../simplification/presentation/result_flow_test.dart'
    show StubRepository, response;

void main() {
  late String? saved;
  late int calls;
  setUp(() {
    saved = null;
    calls = 0;
  });

  LocalAiNoticeRepository repository() => LocalAiNoticeRepository(
    read: () async => saved,
    write: (value) async => saved = value,
  );

  Future<void> launch(
    WidgetTester tester, {
    bool failSubmission = false,
  }) async {
    await tester.pumpWidget(const SizedBox.shrink());
    final controller = TextEditingController(text: 'Tekst do wysłania');
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeScreen(
            appName: 'Sedno',
            textController: controller,
            aiNoticeRepository: repository(),
            onSubmit: (_) async {
              calls++;
              if (failSubmission) throw StateError('network failure');
            },
          ),
        ),
      ),
    );
  }

  testWidgets('acceptance survives restarting the entire app', (tester) async {
    Future<void> launchApp() async {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        SednoApp(
          aiNoticeRepository: repository(),
          simplificationRepository: StubRepository((request) async {
            calls++;
            return response(request.requestId);
          }),
        ),
      );
      await tester.enterText(find.byType(TextField), 'Tekst do wysłania');
    }

    await launchApp();
    await tester.tap(find.text('Uprość'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('aiProcessingNotice')), findsOneWidget);
    expect(calls, 0);
    expect(saved, isNull);
    await tester.tap(find.text('Rozumiem, wyślij'));
    await tester.pumpAndSettle();
    expect(saved, 'true');
    expect(calls, 1);
    await launchApp();
    await tester.tap(find.text('Uprość'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('aiProcessingNotice')), findsNothing);
    expect(calls, 2);
    expect(find.text('Uproszczony tekst'), findsOneWidget);
  });

  for (final dismissal in ['cancel', 'back', 'barrier']) {
    testWidgets('$dismissal does not save acceptance, even after restart', (
      tester,
    ) async {
      await launch(tester);
      await tester.tap(find.text('Uprość'));
      await tester.pumpAndSettle();
      if (dismissal == 'cancel') {
        await tester.tap(find.text('Anuluj'));
      } else if (dismissal == 'back') {
        await tester.binding.handlePopRoute();
      } else {
        await tester.tapAt(const Offset(5, 5));
      }
      await tester.pumpAndSettle();
      expect(saved, isNull);
      expect(calls, 0);
      expect(find.byKey(const Key('aiProcessingNotice')), findsNothing);
      await launch(tester);
      await tester.tap(find.text('Uprość'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('aiProcessingNotice')), findsOneWidget);
      expect(calls, 0);
    });
  }

  testWidgets('both text modes share acceptance, including after AI failure', (
    tester,
  ) async {
    await launch(tester, failSubmission: true);
    await tester.tap(find.byKey(const Key('modeSwitch')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Tekst do poprawienia');
    await tester.tap(find.text('Popraw'));
    await tester.pumpAndSettle();
    expect(find.text('Zanim poprawisz tekst'), findsOneWidget);
    await tester.tap(find.text('Rozumiem, wyślij'));
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(saved, 'true');
    await launch(tester);
    await tester.tap(find.text('Uprość'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('aiProcessingNotice')), findsNothing);
    expect(calls, 2);
    await tester.tap(find.byKey(const Key('modeSwitch')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Nowy tekst');
    await tester.tap(find.text('Popraw'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('aiProcessingNotice')), findsNothing);
    expect(calls, 3);
  });

  testWidgets('pending preference read blocks sending and duplicate taps', (
    tester,
  ) async {
    final pending = Completer<String?>();
    final controller = TextEditingController(text: 'Tekst');
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeScreen(
            appName: 'Sedno',
            textController: controller,
            aiNoticeRepository: LocalAiNoticeRepository(
              read: () => pending.future,
              write: (_) async {},
            ),
            onSubmit: (_) async => calls++,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Uprość'));
    await tester.pump();
    await tester.tap(find.text('Uprość'));
    await tester.pump();
    expect(calls, 0);
    pending.complete('true');
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.byKey(const Key('aiProcessingNotice')), findsNothing);
  });
}
