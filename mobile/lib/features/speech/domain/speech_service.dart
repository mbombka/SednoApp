/// Audio is recognized locally. Only the returned text may reach the backend.
abstract interface class SpeechService {
  Future<String?> listen();
  Future<void> cancel();
}

class SpeechException implements Exception {
  const SpeechException(this.message);
  final String message;
}
