import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sedno_app/features/simplification/domain/input_text.dart';
import 'package:sedno_app/features/speech_output/domain/text_playback_service.dart';

class TextPlaybackViewModel extends ChangeNotifier {
  TextPlaybackViewModel(this.service);
  final TextPlaybackService service;
  bool isPlaying = false;
  String? message;
  bool _disposed = false;
  int _revision = 0;

  Future<void> play(String text) async {
    if (isPlaying) return;
    try {
      InputText(text);
    } on FormatException catch (error) {
      message = error.message;
      notifyListeners();
      return;
    }
    final revision = ++_revision;
    isPlaying = true;
    message = null;
    notifyListeners();
    try {
      await service.speak(text);
    } catch (error) {
      if (!_disposed && revision == _revision) {
        message = error is FormatException
            ? error.message
            : 'Nie udało się odczytać tekstu. Spróbuj ponownie.';
      }
    } finally {
      if (!_disposed && revision == _revision) {
        isPlaying = false;
        notifyListeners();
      }
    }
  }

  Future<void> stop() async {
    _revision++;
    isPlaying = false;
    await service.stop();
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(stop());
    super.dispose();
  }
}
