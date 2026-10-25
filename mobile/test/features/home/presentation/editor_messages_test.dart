import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedno_app/features/home/presentation/home_screen.dart';
import 'package:sedno_app/features/photo/domain/photo_text_repository.dart';
import 'package:sedno_app/features/speech/domain/speech_service.dart';
import 'package:sedno_app/features/speech_output/domain/text_playback_service.dart';

import '../../../helpers.dart';
import '../../photo/presentation/photo_input_widget_test.dart'
    show FakePhotoRepository;

class _Speech implements SpeechService {
  _Speech(this.action);
  final Future<String?> Function() action;
  @override
  Future<String?> listen() => action();
  @override
  Future<void> cancel() async {}
}

class _Playback implements TextPlaybackService {
  @override
  Future<void> speak(String text) async => throw StateError('private details');
  @override
  Future<void> stop() async {}
}

void main() {
  for (final source in [
    'no text',
    'camera permission',
    'OCR failure',
    'camera unavailable',
    'no speech',
    'speech permission',
    'speech failure',
    'empty playback',
    'long playback',
    'playback failure',
  ]) {
    for (final action in ['eraser', 'submission', 'mode change']) {
      testWidgets('$source clears on $action', (tester) async {
        final controller = TextEditingController();
        addTearDown(controller.dispose);
        final pending = Completer<void>();
        final playback = source.contains('playback');
        final speech = source.contains('speech');
        final messageKey = playback
            ? 'playbackMessage'
            : speech
            ? 'speechMessage'
            : source == 'camera unavailable'
            ? 'cameraUnavailableMessage'
            : 'photoMessage';
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HomeScreen(
                appName: 'Sedno',
                textController: controller,
                photoRepository: source == 'camera unavailable'
                    ? null
                    : FakePhotoRepository(() async {
                        if (source == 'camera permission') {
                          throw const CameraPermissionDenied();
                        }
                        if (source == 'OCR failure') {
                          throw StateError('private details');
                        }
                        return '   ';
                      }),
                speechService: _Speech(() async {
                  if (source == 'speech permission') {
                    throw const SpeechException('Brak modelu języka.');
                  }
                  if (source == 'speech failure') {
                    throw StateError('private details');
                  }
                  return ' ';
                }),
                playbackService: _Playback(),
                onSubmit: (_) => pending.future,
              ),
            ),
          ),
        );
        if (playback) {
          await tester.tap(find.byKey(const Key('modeSwitch')));
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byType(TextField),
            source == 'empty playback'
                ? ''
                : source == 'long playback'
                ? 'a' * 4001
                : 'Tekst do odczytu',
          );
        }
        await tester.tap(
          find.byKey(
            Key(
              playback
                  ? 'speakerButton'
                  : speech
                  ? 'microphoneButton'
                  : 'cameraButton',
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byKey(Key(messageKey)), findsOneWidget);
        expect(find.textContaining('private details'), findsNothing);
        if (action == 'eraser') {
          await tester.tap(find.byKey(const Key('clearTextButton')));
          await tester.pumpAndSettle();
          expect(controller.text, isEmpty);
        } else if (action == 'mode change') {
          // Returning to the original mode must not bring the message back.
          for (var i = 0; i < 2; i++) {
            await tester.tap(find.byKey(const Key('modeSwitch')));
            await tester.pumpAndSettle();
          }
        } else {
          await tester.enterText(find.byType(TextField), 'Nowy tekst');
          await tester.pumpAndSettle();
          await tester.tap(find.text(playback ? 'Popraw' : 'Uprość'));
          await tester.pumpAndSettle();
          // Clear before consent, while pending, and after success.
          expect(find.byKey(Key(messageKey)), findsNothing);
          await tester.tap(find.text('Rozumiem, wyślij'));
          await tester.pump();
          expect(find.byKey(Key(messageKey)), findsNothing);
          pending.complete();
          await tester.pumpAndSettle();
          expect(controller.text, 'Nowy tekst');
        }
        expect(find.byKey(Key(messageKey)), findsNothing);
      });
    }
  }

  for (final nextInput in ['cameraButton', 'microphoneButton']) {
    testWidgets('starting $nextInput clears the other input error', (
      tester,
    ) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      var photoCalls = 0;
      var speechCalls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeScreen(
              appName: 'Sedno',
              textController: controller,
              photoRepository: FakePhotoRepository(
                () async => photoCalls++ == 0 ? ' ' : null,
              ),
              speechService: _Speech(
                () async => speechCalls++ == 0 ? ' ' : null,
              ),
            ),
          ),
        ),
      );
      final firstInput = nextInput == 'cameraButton'
          ? 'microphoneButton'
          : 'cameraButton';
      final firstMessage = nextInput == 'cameraButton'
          ? 'speechMessage'
          : 'photoMessage';
      await tester.tap(find.byKey(Key(firstInput)));
      await tester.pumpAndSettle();
      expect(find.byKey(Key(firstMessage)), findsOneWidget);
      await tester.tap(find.byKey(Key(nextInput)));
      await tester.pumpAndSettle();
      expect(find.byKey(Key(firstMessage)), findsNothing);
      // Cancelled capture clears the previous error from the same source too.
      await tester.tap(find.byKey(Key(nextInput)));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('speechMessage')), findsNothing);
      expect(find.byKey(const Key('photoMessage')), findsNothing);
    });
  }

  testWidgets('validation and submission errors replace an old OCR error', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeScreen(
            appName: 'Sedno',
            textController: controller,
            photoRepository: FakePhotoRepository(() async => ' '),
            onSubmit: (_) async => throw TimeoutException('private details'),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const Key('cameraButton')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Uprość'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('photoMessage')), findsNothing);
    expect(find.text('Tekst nie może być pusty.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Zachowaj tekst');
    await submitText(tester);
    await tester.pumpAndSettle();
    expect(find.text('Tekst nie może być pusty.'), findsNothing);
    expect(
      find.text('Przekroczono czas oczekiwania. Spróbuj ponownie.'),
      findsOneWidget,
    );
    expect(controller.text, 'Zachowaj tekst');
    await tester.tap(find.byKey(const Key('clearTextButton')));
    await tester.pumpAndSettle();
    expect(
      find.text('Przekroczono czas oczekiwania. Spróbuj ponownie.'),
      findsNothing,
    );
  });
}
