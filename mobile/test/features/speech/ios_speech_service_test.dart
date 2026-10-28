import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedno_app/app/app_language.dart';
import 'package:sedno_app/features/speech/data/ios_speech_service.dart';
import 'package:sedno_app/features/speech/domain/speech_service.dart';
import 'package:sedno_app/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('sedno/speech');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test(
    'passes the exact regional language for all supported languages',
    () async {
      for (final language in AppLanguage.values) {
        final calls = <MethodCall>[];
        messenger.setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          return 'synthetic recognition fixture';
        });
        final service = IosSpeechService(language: () => language);
        expect(await service.listen(), 'synthetic recognition fixture');
        expect(calls.single.method, 'listen');
        expect(calls.single.arguments, {'language': language.speechTag});
      }
    },
  );

  test(
    'cancel resolves an active native listen with no recognised text',
    () async {
      final nativeResult = Completer<String?>();
      final listening = Completer<void>();
      final calls = <String>[];
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls.add(call.method);
        if (call.method == 'listen') {
          listening.complete();
          return nativeResult.future;
        }
        if (call.method == 'cancel') nativeResult.complete(null);
        return null;
      });
      const service = IosSpeechService();
      final text = service.listen();
      await listening.future;
      await service.cancel();
      expect(await text, isNull);
      expect(calls, ['listen', 'cancel']);
    },
  );

  test(
    'maps offline, permission and recognition errors in every locale',
    () async {
      for (final language in AppLanguage.values) {
        final strings = lookupAppLocalizations(language.locale);
        final service = IosSpeechService(
          language: () => language,
          localizations: () => strings,
        );
        for (final entry in {
          'permission': strings.microphonePermission,
          'unavailable': strings.localSpeechUnavailable,
          'language': strings.localSpeechModelMissing,
          'language_unsupported': strings.speechLanguageUnsupported,
          'no_speech': strings.speechNotRecognised,
          'timeout': strings.speechTimeout,
          'recognition_failed': strings.speechFailed,
        }.entries) {
          messenger.setMockMethodCallHandler(
            channel,
            (_) async => throw PlatformException(
              code: entry.key,
              message: 'private native engine details',
            ),
          );
          await expectLater(
            service.listen(),
            throwsA(
              isA<SpeechException>().having(
                (error) => error.message,
                'safe localised message',
                entry.value,
              ),
            ),
          );
        }
      }
    },
  );

  test(
    'missing native implementation reports platform neutral message',
    () async {
      final strings = lookupAppLocalizations(AppLanguage.polish.locale);
      await expectLater(
        const IosSpeechService().listen(),
        throwsA(
          isA<SpeechException>().having(
            (error) => error.message,
            'message',
            strings.deviceFeatureUnavailable,
          ),
        ),
      );
      await const IosSpeechService().cancel();
    },
  );

  test('cancellation tolerates a native lifecycle error', () async {
    messenger.setMockMethodCallHandler(
      channel,
      (_) async => throw PlatformException(code: 'interrupted'),
    );
    await const IosSpeechService().cancel();
  });
}
