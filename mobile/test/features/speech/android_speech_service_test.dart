import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedno_app/features/speech/data/android_speech_service.dart';
import 'package:sedno_app/features/speech/domain/speech_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('sedno/speech');
  const service = AndroidSpeechService();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('returns native text and invokes cancellation', () async {
    final calls = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      return call.method == 'listen' ? 'Polska mowa' : null;
    });
    expect(await service.listen(), 'Polska mowa');
    await service.cancel();
    expect(calls, ['listen', 'cancel']);
  });

  for (final code in [
    'permission',
    'language',
    'unavailable',
    'no_speech',
    'timeout',
  ]) {
    test('maps $code to a safe user message', () async {
      messenger.setMockMethodCallHandler(channel, (_) async {
        throw PlatformException(code: code, message: 'private engine details');
      });
      await expectLater(
        service.listen(),
        throwsA(
          isA<SpeechException>().having(
            (error) => error.message,
            'message',
            isNot(contains('private engine details')),
          ),
        ),
      );
    });
  }
}
