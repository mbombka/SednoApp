import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedno_app/features/home/presentation/home_screen.dart';
import 'package:sedno_app/features/speech/domain/speech_service.dart';

import 'fake_speech_service.dart';

void main() {
  late TextEditingController controller;
  late FakeSpeechService service;
  late List<String> submitted;

  setUp(() {
    controller = TextEditingController(text: 'Poprzedni tekst');
    service = FakeSpeechService();
    submitted = [];
  });
  tearDown(() => controller.dispose());

  Future<void> showScreen(
    WidgetTester tester, {
    bool active = true,
    bool failSubmission = false,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: HomeScreen(
          appName: 'Sedno',
          textController: controller,
          speechService: service,
          isActive: active,
          onSubmit: (input) async {
            if (failSubmission) throw StateError('private backend details');
            submitted.add(input.value);
          },
        ),
      ),
    ),
  );

  Future<void> start(WidgetTester tester) async {
    await showScreen(tester);
    final mic = find.byKey(const Key('microphoneButton'));
    expect(tester.getSize(mic).shortestSide, greaterThanOrEqualTo(48));
    expect(
      tester.getCenter(mic).dx,
      lessThan(tester.getCenter(find.byKey(const Key('simplifyButton'))).dx),
    );
    await tester.tap(mic);
    await tester.pump();
  }

  testWidgets('recording locks editor, camera and submit; stop cancels', (
    tester,
  ) async {
    await start(tester);
    expect(find.byKey(const Key('speechStatus')), findsOneWidget);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('simplifyButton')))
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<OutlinedButton>(find.byKey(const Key('cameraButton')))
          .onPressed,
      isNull,
    );
    await tester.tap(find.byTooltip('Anuluj nagrywanie'));
    await tester.pumpAndSettle();
    expect(service.cancellations, 1);
    expect(controller.text, 'Poprzedni tekst');
    expect(submitted, isEmpty);
  });

  testWidgets(
    'final speech enters the existing AI notice and auto submission',
    (tester) async {
      await start(tester);
      service.pending.complete('Rozpoznana mowa');
      await tester.pumpAndSettle();
      expect(controller.text, 'Rozpoznana mowa');
      expect(find.byKey(const Key('aiProcessingNotice')), findsOneWidget);
      expect(submitted, isEmpty);
      await tester.tap(find.text('Rozumiem, wyślij'));
      await tester.pumpAndSettle();
      expect(submitted, ['Rozpoznana mowa']);
    },
  );

  testWidgets('cancelling AI notice keeps recognized speech in editor', (
    tester,
  ) async {
    await start(tester);
    service.pending.complete('Rozpoznany tekst');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Anuluj'));
    await tester.pumpAndSettle();
    expect(controller.text, 'Rozpoznany tekst');
    expect(submitted, isEmpty);
  });

  testWidgets('speech exceeding 4000 characters stays editable', (
    tester,
  ) async {
    await start(tester);
    service.pending.complete('a' * 4001);
    await tester.pumpAndSettle();
    expect(controller.text.length, 4001);
    expect(
      find.text('Tekst może mieć maksymalnie 4000 znaków.'),
      findsOneWidget,
    );
    expect(submitted, isEmpty);
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);
  });

  testWidgets('recognition error preserves the previous input', (tester) async {
    await start(tester);
    service.pending.completeError(
      const SpeechException('Brak modelu polskiego.'),
    );
    await tester.pumpAndSettle();
    expect(controller.text, 'Poprzedni tekst');
    expect(find.text('Brak modelu polskiego.'), findsOneWidget);
    expect(submitted, isEmpty);
  });

  testWidgets('backend failure keeps recognized text available for retry', (
    tester,
  ) async {
    await showScreen(tester, failSubmission: true);
    await tester.tap(find.byKey(const Key('microphoneButton')));
    service.pending.complete('Tekst do ponowienia');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rozumiem, wyślij'));
    await tester.pumpAndSettle();
    expect(controller.text, 'Tekst do ponowienia');
    expect(
      find.text('Nie udało się uprościć tekstu. Spróbuj ponownie.'),
      findsOneWidget,
    );
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isTrue);
  });

  testWidgets('leaving home cancels speech without submitting', (tester) async {
    await start(tester);
    await showScreen(tester, active: false);
    await tester.pumpAndSettle();
    expect(service.cancellations, 1);
    expect(submitted, isEmpty);
    expect(controller.text, 'Poprzedni tekst');
  });

  testWidgets('backgrounding cancels speech', (tester) async {
    await start(tester);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pumpAndSettle();
    expect(service.cancellations, 1);
    expect(submitted, isEmpty);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  });
}
