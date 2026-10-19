import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedno_app/features/home/presentation/home_screen.dart';
import 'package:sedno_app/features/home/presentation/text_input_view_model.dart';
import 'package:sedno_app/features/photo/domain/photo_text_repository.dart';

class FakePhotoRepository implements PhotoTextRepository {
  FakePhotoRepository(this.action);
  final Future<String?> Function() action;
  @override
  Future<String?> recognizeFromCamera() => action();
}

void main() {
  Future<void> showScreen(
    WidgetTester tester,
    TextEditingController controller,
    PhotoTextRepository repository, {
    SubmitText? onSubmit,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: HomeScreen(
          appName: 'Sedno',
          textController: controller,
          photoRepository: repository,
          onSubmit: onSubmit,
        ),
      ),
    ),
  );

  testWidgets('recognized Polish text is submitted without a second tap', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'Stary tekst');
    addTearDown(controller.dispose);
    final submitted = <String>[];
    await showScreen(
      tester,
      controller,
      FakePhotoRepository(() async => 'Zażółć gęślą jaźń'),
      onSubmit: (input) async => submitted.add(input.value),
    );

    await tester.tap(find.byKey(const Key('cameraButton')));
    await tester.pumpAndSettle();
    expect(controller.text, 'Zażółć gęślą jaźń');
    // The AI processing notice is still required before the first submission.
    expect(find.byKey(const Key('aiProcessingNotice')), findsOneWidget);
    expect(submitted, isEmpty);

    await tester.tap(find.text('Rozumiem, wyślij'));
    await tester.pumpAndSettle();
    expect(submitted, ['Zażółć gęślą jaźń']);
  });

  testWidgets('declined AI notice keeps recognized text editable', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final submitted = <String>[];
    await showScreen(
      tester,
      controller,
      FakePhotoRepository(() async => 'Zażółć gęślą jaźń'),
      onSubmit: (input) async => submitted.add(input.value),
    );

    await tester.tap(find.byKey(const Key('cameraButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Anuluj'));
    await tester.pumpAndSettle();
    expect(submitted, isEmpty);
    expect(controller.text, 'Zażółć gęślą jaźń');

    await tester.enterText(find.byType(TextField), 'Poprawiony tekst');
    await tester.pump();
    expect(controller.text, 'Poprawiony tekst');
  });

  testWidgets('too much recognized text is not submitted and stays editable', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    final submitted = <String>[];
    await showScreen(
      tester,
      controller,
      FakePhotoRepository(() async => 'x' * 4001),
      onSubmit: (input) async => submitted.add(input.value),
    );

    await tester.tap(find.byKey(const Key('cameraButton')));
    await tester.pumpAndSettle();
    expect(submitted, isEmpty);
    expect(find.byKey(const Key('aiProcessingNotice')), findsNothing);
    expect(controller.text.length, 4001);
    expect(
      find.text('Tekst może mieć maksymalnie 4000 znaków.'),
      findsOneWidget,
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    await tester.enterText(find.byType(TextField), 'Poprawiony tekst');
    await tester.pump();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('no text, denial and processing failure preserve current input', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'Zachowaj');
    addTearDown(controller.dispose);
    for (final scenario in <(PhotoTextRepository, String)>[
      (FakePhotoRepository(() async => '   '), 'Nie wykryto tekstu'),
      (
        FakePhotoRepository(() async => throw const CameraPermissionDenied()),
        'Brak dostępu do aparatu',
      ),
      (
        FakePhotoRepository(() async => throw StateError('secret')),
        'Nie udało się odczytać tekstu',
      ),
    ]) {
      await showScreen(tester, controller, scenario.$1);
      await tester.tap(find.byKey(const Key('cameraButton')));
      await tester.pump();
      expect(controller.text, 'Zachowaj');
      expect(find.textContaining(scenario.$2), findsOneWidget);
    }
  });

  testWidgets('cancellation preserves input and scanning disables actions', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'Zachowaj');
    addTearDown(controller.dispose);
    final pending = Completer<String?>();
    await showScreen(
      tester,
      controller,
      FakePhotoRepository(() => pending.future),
    );

    await tester.tap(find.byKey(const Key('cameraButton')));
    await tester.pump();
    expect(find.bySemanticsLabel('Odczytywanie…'), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    pending.complete(null);
    await tester.pump();
    expect(controller.text, 'Zachowaj');
    expect(find.bySemanticsLabel('Aparat'), findsOneWidget);
    expect(find.byKey(const Key('photoMessage')), findsNothing);
  });
}
