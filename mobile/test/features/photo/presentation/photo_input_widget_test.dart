import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedno_app/features/home/presentation/home_screen.dart';
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
    PhotoTextRepository repository,
  ) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: HomeScreen(
          appName: 'Sedno',
          textController: controller,
          photoRepository: repository,
        ),
      ),
    ),
  );

  testWidgets('recognized Polish text enters editable field', (tester) async {
    final controller = TextEditingController(text: 'Stary tekst');
    addTearDown(controller.dispose);
    await showScreen(
      tester,
      controller,
      FakePhotoRepository(() async => 'Zażółć gęślą jaźń'),
    );

    await tester.tap(find.byKey(const Key('cameraButton')));
    await tester.pump();
    expect(controller.text, 'Zażółć gęślą jaźń');
    expect(find.byKey(const Key('characterCounter')), findsNothing);

    await tester.enterText(find.byType(TextField), 'Poprawiony tekst');
    await tester.pump();
    expect(controller.text, 'Poprawiony tekst');
  });

  testWidgets('too much recognized text stays editable and blocks submit', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await showScreen(
      tester,
      controller,
      FakePhotoRepository(() async => 'x' * 4001),
    );

    await tester.tap(find.byKey(const Key('cameraButton')));
    await tester.pump();
    expect(controller.text.length, 4001);
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
