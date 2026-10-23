import 'package:sedno_app/features/shared/domain/app_language.dart';
import 'package:sedno_app/l10n/localization.dart';
import 'package:flutter/services.dart';
import 'package:sedno_app/features/speech_output/domain/text_playback_service.dart';

class AndroidTextPlaybackService implements TextPlaybackService {
  final AppLocalizations Function() localizations;
  final AppLanguage Function() language;
  AppLocalizations get strings => localizations();

  const AndroidTextPlaybackService({
    this.localizations = polishStrings,
    this.language = polishLanguage,
  });
  static const _channel = MethodChannel('sedno/text-playback');

  @override
  Future<void> speak(String text) async {
    try {
      await _channel.invokeMethod<void>('speak', {
        'text': text,
        'language': language().speechTag,
      });
    } on PlatformException {
      throw FormatException(strings.voiceMissing);
    } on MissingPluginException {
      throw FormatException(strings.playbackAndroidOnly);
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _channel.invokeMethod<void>('stop');
    } on PlatformException {
      // Android also stops playback when the activity is hidden.
    } on MissingPluginException {
      // No playback exists on an unsupported platform.
    }
  }
}
