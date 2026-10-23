import 'package:sedno_app/features/shared/domain/app_language.dart';
import 'package:sedno_app/l10n/localization.dart';
import 'package:flutter/services.dart';
import 'package:sedno_app/features/speech/domain/speech_service.dart';

class AndroidSpeechService implements SpeechService {
  final AppLocalizations Function() localizations;
  final AppLanguage Function() language;
  AppLocalizations get strings => localizations();

  const AndroidSpeechService({
    this.localizations = polishStrings,
    this.language = polishLanguage,
  });
  static const _channel = MethodChannel('sedno/speech');

  @override
  Future<String?> listen() async {
    try {
      return await _channel.invokeMethod<String>('listen', {
        'language': language().speechTag,
      });
    } on PlatformException catch (error) {
      throw SpeechException(switch (error.code) {
        'permission' => strings.microphonePermission,
        'unavailable' => strings.speechRequirements,
        'language' => strings.speechModelMissing,
        'no_speech' => strings.speechNotRecognised,
        'timeout' => strings.speechTimeout,
        _ => strings.speechFailed,
      });
    } on MissingPluginException {
      throw SpeechException(strings.speechAndroidOnly);
    }
  }

  @override
  Future<void> cancel() async {
    try {
      await _channel.invokeMethod<void>('cancel');
    } on PlatformException {
      // Native lifecycle cleanup also releases the microphone.
    } on MissingPluginException {
      // No microphone can be open on an unsupported platform.
    }
  }
}
