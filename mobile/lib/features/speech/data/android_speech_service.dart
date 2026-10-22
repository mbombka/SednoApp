import 'package:flutter/services.dart';
import 'package:sedno_app/features/speech/domain/speech_service.dart';

class AndroidSpeechService implements SpeechService {
  const AndroidSpeechService();
  static const _channel = MethodChannel('sedno/speech');

  @override
  Future<String?> listen() async {
    try {
      return await _channel.invokeMethod<String>('listen');
    } on PlatformException catch (error) {
      throw SpeechException(switch (error.code) {
        'permission' => 'Aby użyć mowy, zezwól na dostęp do mikrofonu w ustawieniach aplikacji.',
        'unavailable' => 'Lokalne rozpoznawanie mowy wymaga Androida 13 lub nowszego i obsługującego je silnika mowy.',
        'language' => 'Brak lokalnego modelu języka polskiego. Pobierz go w ustawieniach rozpoznawania mowy Androida.',
        'no_speech' => 'Nie rozpoznano mowy. Spróbuj ponownie.',
        'timeout' => 'Rozpoznawanie trwało zbyt długo. Spróbuj ponownie.',
        _ => 'Nie udało się rozpoznać mowy. Spróbuj ponownie.',
      });
    } on MissingPluginException {
      throw const SpeechException(
        'Lokalne rozpoznawanie mowy jest dostępne na Androidzie 13 lub nowszym.',
      );
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
