abstract interface class TextPlaybackService {
  /// Completes when playback finishes or is stopped.
  Future<void> speak(String text);
  Future<void> stop();
}
