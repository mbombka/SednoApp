import '../../../helpers.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedno_app/features/home/presentation/home_screen.dart';
import 'package:sedno_app/features/home/presentation/text_input_view_model.dart';

void main() {
  Future<void> showScreen(
    WidgetTester tester, {
    required TextEditingController controller,
    SubmitText? onSubmit,
    VoidCallback? onCameraPressed,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: HomeScreen(
          appName: 'Sedno',
          textController: controller,
          onSubmit: onSubmit,
          onCameraPressed: onCameraPressed,
        ),
      ),
    ),
  );

  testWidgets('shows editor, counter, camera and submit in idle state', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await showScreen(tester, controller: controller);

    expect(find.byType(TextField), findsOneWidget);
    expect(find.byKey(const Key('characterCounter')), findsNothing);
    expect(find.bySemanticsLabel('Aparat'), findsOneWidget);
    expect(find.text('Uprość'), findsOneWidget);
    expect(find.textContaining('dostawcy AI'), findsNothing);
    expect(
      tester.getSize(find.byType(OutlinedButton)).height,
      greaterThanOrEqualTo(48),
    );
    expect(
      tester.getSize(find.byType(FilledButton)).height,
      greaterThanOrEqualTo(48),
    );

    await tester.enterText(find.byType(TextField), 'A👨‍👩‍👧‍👦');
    await tester.pump();
    expect(controller.text, 'A👨‍👩‍👧‍👦');
  });

  testWidgets('notice gates first submission and cancellation preserves text', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'Tekst do uproszczenia');
    addTearDown(controller.dispose);
    var calls = 0;
    await showScreen(
      tester,
      controller: controller,
      onSubmit: (_) async {
        calls++;
      },
    );
    expect(find.byKey(const Key('aiProcessingNotice')), findsNothing);
    await tester.tap(find.text('Uprość'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('aiProcessingNotice')), findsOneWidget);
    expect(find.textContaining('OpenAI'), findsOneWidget);
    expect(calls, 0);
    await tester.tap(find.text('Anuluj'));
    await tester.pumpAndSettle();
    expect(calls, 0);
    expect(controller.text, 'Tekst do uproszczenia');
    await submitText(tester);
    await tester.pumpAndSettle();
    expect(calls, 1);
    await tester.tap(find.text('Uprość'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('aiProcessingNotice')), findsNothing);
    expect(calls, 2);
  });

  testWidgets(
    'editor is rounded and action buttons are circles with centered submit',
    (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await showScreen(tester, controller: controller);
      final submit = find.byKey(const Key('simplifyButton'));
      final camera = find.byKey(const Key('cameraButton'));
      expect(tester.getCenter(submit).dx, closeTo(400, 1));
      expect(
        tester.getCenter(camera).dx,
        greaterThan(tester.getCenter(submit).dx),
      );
      final submitSize = tester.getSize(submit);
      final cameraSize = tester.getSize(camera);
      expect(
        tester.widget<FilledButton>(submit).style!.shape!.resolve({}),
        isA<CircleBorder>(),
      );
      expect(cameraSize.width, cameraSize.height);
      expect(submitSize.width, greaterThan(cameraSize.width));
      expect(find.text('Witaj w Sedno'), findsNothing);
      expect(find.text('Prywatność i dane'), findsNothing);
    },
  );

  testWidgets('empty input shows an error and does not submit', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    var calls = 0;
    await showScreen(
      tester,
      controller: controller,
      onSubmit: (_) async {
        calls++;
      },
    );

    await submitText(tester);
    await tester.pump();
    expect(find.text('Tekst nie może być pusty.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), ' \n ');
    await submitText(tester);
    await tester.pump();
    expect(find.text('Tekst nie może być pusty.'), findsOneWidget);
    expect(calls, 0);
  });

  testWidgets('overlong input shows count and blocks submit until edited', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    var calls = 0;
    await showScreen(
      tester,
      controller: controller,
      onSubmit: (_) async {
        calls++;
      },
    );

    await tester.enterText(find.byType(TextField), 'x' * 4001);
    await tester.pump();
    expect(controller.text.length, 4001);
    expect(
      find.text('Tekst może mieć maksymalnie 4000 znaków.'),
      findsOneWidget,
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(calls, 0);

    await tester.enterText(find.byType(TextField), 'Poprawiony tekst');
    await tester.pump();
    expect(find.text('Tekst może mieć maksymalnie 4000 znaków.'), findsNothing);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('loading disables editor and actions; completion shows success', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final pending = Completer<void>();
    var calls = 0;
    var cameraCalls = 0;
    await showScreen(
      tester,
      controller: controller,
      onSubmit: (_) {
        calls++;
        return pending.future;
      },
      onCameraPressed: () => cameraCalls++,
    );
    await tester.enterText(find.byType(TextField), 'Tekst');
    await submitText(tester);
    await tester.pump();

    expect(find.bySemanticsLabel('Upraszczanie…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).onPressed,
      isNull,
    );
    expect(calls, 1);
    expect(cameraCalls, 0);

    pending.complete();
    await tester.pump();
    expect(
      find.text('Tekst został przekazany do uproszczenia.'),
      findsOneWidget,
    );
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);
  });

  testWidgets('failure keeps text and allows retry', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    var calls = 0;
    await showScreen(
      tester,
      controller: controller,
      onSubmit: (_) async {
        if (calls++ == 0) throw StateError('secret');
      },
    );
    await tester.enterText(find.byType(TextField), 'Trudny tekst');

    await submitText(tester);
    await tester.pump();
    expect(
      find.text('Nie udało się uprościć tekstu. Spróbuj ponownie.'),
      findsOneWidget,
    );
    expect(controller.text, 'Trudny tekst');
    await submitText(tester);
    await tester.pump();
    expect(calls, 2);
    expect(
      find.text('Tekst został przekazany do uproszczenia.'),
      findsOneWidget,
    );
  });

  testWidgets('camera action is injectable and placeholder is honest', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    var cameraCalls = 0;
    await showScreen(
      tester,
      controller: controller,
      onCameraPressed: () => cameraCalls++,
    );
    await tester.tap(find.byKey(const Key('cameraButton')));
    expect(cameraCalls, 1);

    await showScreen(tester, controller: controller);
    await tester.tap(find.byKey(const Key('cameraButton')));
    await tester.pump();
    expect(find.text('Aparat będzie dostępny wkrótce.'), findsOneWidget);
  });

  testWidgets('default submit reports unavailable feature', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await showScreen(tester, controller: controller);
    await tester.enterText(find.byType(TextField), 'Tekst');
    await submitText(tester);
    await tester.pump();
    expect(
      find.text('Upraszczanie tekstu nie jest jeszcze dostępne.'),
      findsOneWidget,
    );
  });
}
