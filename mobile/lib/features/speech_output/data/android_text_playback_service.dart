import 'package:flutter/services.dart';
import 'package:sedno_app/features/speech_output/domain/text_playback_service.dart';

class AndroidTextPlaybackService implements TextPlaybackService {
  const AndroidTextPlaybackService();
  static const _channel = MethodChannel('sedno/text-playback');

  @override
  Future<void> speak(String text) async {
    try {
      await _channel.invokeMethod<void>('speak', text);
    } on PlatformException {
      throw const FormatException(
        'Nie można odczytać tekstu. Sprawdź, czy w ustawieniach telefonu jest pobrany polski głos do odczytu bez internetu.',
      );
    } on MissingPluginException {
      throw const FormatException('Odczyt tekstu jest dostępny na Androidzie.');
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
