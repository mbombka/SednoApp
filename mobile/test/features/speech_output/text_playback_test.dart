import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedno_app/features/speech_output/domain/text_playback_service.dart';
import 'package:sedno_app/features/speech_output/data/android_text_playback_service.dart';
import 'package:sedno_app/features/speech_output/presentation/text_playback_view_model.dart';

class FakePlayback implements TextPlaybackService {
  final calls = <String>[];
  Completer<void>? pending;
  bool fail = false;
  @override
  Future<void> speak(String text) {
    calls.add(text);
    if (fail) throw StateError('private engine error');
    return (pending = Completer<void>()).future;
  }

  @override
  Future<void> stop() async {
    if (pending?.isCompleted == false) pending!.complete();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('validates text, stops playback and hides engine errors', () async {
    final service = FakePlayback();
    final model = TextPlaybackViewModel(service);
    await model.play('  ');
    expect(service.calls, isEmpty);
    expect(model.message, 'Tekst nie może być pusty.');
    await model.play('x' * 4001);
    expect(service.calls, isEmpty);
    final playing = model.play('Cześć');
    expect(model.isPlaying, isTrue);
    await model.stop();
    await playing;
    expect(model.isPlaying, isFalse);
    service.fail = true;
    await model.play('Tekst');
    expect(model.message, isNot(contains('private')));
    model.dispose();
  });

  test(
    'native channel receives text and stop; safe unsupported error',
    () async {
      const channel = MethodChannel('sedno/text-playback');
      final messenger =
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return null;
      });
      addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
      const service = AndroidTextPlaybackService();
      await service.speak('Polski tekst');
      await service.stop();
      expect(calls.map((c) => c.method), ['speak', 'stop']);
      expect(calls.first.arguments, 'Polski tekst');
      messenger.setMockMethodCallHandler(
        channel,
        (_) async =>
            throw PlatformException(code: 'unavailable', message: 'secret'),
      );
      await expectLater(
        service.speak('Tekst'),
        throwsA(
          isA<FormatException>().having(
            (e) => e.message,
            'message',
            isNot(contains('secret')),
          ),
        ),
      );
      await service.stop();
    },
  );
}
