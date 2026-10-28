import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedno_app/app/app_language.dart';
import 'package:sedno_app/features/speech_output/data/ios_text_playback_service.dart';
import 'package:sedno_app/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('sedno/text-playback');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('speaks in the selected regional language and sends stop', () async {
    for (final language in AppLanguage.values) {
      final calls = <MethodCall>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call);
        return null;
      });
      final service = IosTextPlaybackService(language: () => language);
      await service.speak('synthetic playback fixture');
      await service.stop();
      expect(calls.map((call) => call.method), ['speak', 'stop']);
      expect(calls.first.arguments, {
        'text': 'synthetic playback fixture',
        'language': language.speechTag,
      });
    }
  });

  test('missing voices and audio errors use safe localised messages', () async {
    for (final language in AppLanguage.values) {
      final strings = lookupAppLocalizations(language.locale);
      final service = IosTextPlaybackService(
        language: () => language,
        localizations: () => strings,
      );
      for (final code in ['voice_missing', 'playback_failed']) {
        messenger.setMockMethodCallHandler(
          channel,
          (_) async => throw PlatformException(
            code: code,
            message: 'private native voice details',
          ),
        );
        await expectLater(
          service.speak('synthetic fixture'),
          throwsA(
            isA<FormatException>().having(
              (error) => error.message,
              'safe localised message',
              strings.voiceMissing,
            ),
          ),
        );
        await service.stop();
      }
    }
  });

  test(
    'missing native implementation reports platform neutral message',
    () async {
      final strings = lookupAppLocalizations(AppLanguage.polish.locale);
      await expectLater(
        const IosTextPlaybackService().speak('synthetic fixture'),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            strings.deviceFeatureUnavailable,
          ),
        ),
      );
      await const IosTextPlaybackService().stop();
    },
  );
}
