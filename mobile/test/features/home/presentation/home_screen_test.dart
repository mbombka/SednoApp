import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simplifier_app/features/home/presentation/home_screen.dart';
import 'package:simplifier_app/features/home/presentation/text_input_view_model.dart';

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
          appName: 'Simplyfi_it',
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
    expect(find.text('0/4000'), findsOneWidget);
    expect(find.text('Aparat'), findsOneWidget);
    expect(find.text('Uprość'), findsOneWidget);
    expect(find.textContaining('dostawcy AI'), findsOneWidget);
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
    expect(find.text('2/4000'), findsOneWidget);
  });

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

    await tester.tap(find.text('Uprość'));
    await tester.pump();
    expect(find.text('Tekst nie może być pusty.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), ' \n ');
    await tester.tap(find.text('Uprość'));
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
    expect(find.text('4001/4000'), findsOneWidget);
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
    await tester.tap(find.text('Uprość'));
    await tester.pump();

    expect(find.text('Upraszczanie…'), findsOneWidget);
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

    await tester.tap(find.text('Uprość'));
    await tester.pump();
    expect(
      find.text('Nie udało się uprościć tekstu. Spróbuj ponownie.'),
      findsOneWidget,
    );
    expect(controller.text, 'Trudny tekst');
    await tester.tap(find.text('Uprość'));
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
    await tester.tap(find.text('Aparat'));
    expect(cameraCalls, 1);

    await showScreen(tester, controller: controller);
    await tester.tap(find.text('Aparat'));
    await tester.pump();
    expect(find.text('Aparat będzie dostępny wkrótce.'), findsOneWidget);
  });

  testWidgets('default submit reports unavailable feature', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await showScreen(tester, controller: controller);
    await tester.enterText(find.byType(TextField), 'Tekst');
    await tester.tap(find.text('Uprość'));
    await tester.pump();
    expect(
      find.text('Upraszczanie tekstu nie jest jeszcze dostępne.'),
      findsOneWidget,
    );
  });
}
