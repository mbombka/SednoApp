import 'package:sedno_app/l10n/localization.dart';
import 'package:flutter/foundation.dart';
import 'package:sedno_app/features/speech/domain/speech_service.dart';

class SpeechInputViewModel extends ChangeNotifier {
  AppLocalizations Function() localizations = polishStrings;
  AppLocalizations get strings => localizations();

  SpeechInputViewModel(this._service);
  final SpeechService _service;
  bool busy = false;
  String? message;
  int _generation = 0;
  bool _disposed = false;

  Future<String?> listen() async {
    if (busy || _disposed) return null;
    final generation = ++_generation;
    busy = true;
    message = null;
    notifyListeners();
    try {
      final text = await _service.listen();
      if (_disposed || generation != _generation) return null;
      if (text == null) return null;
      if (text.trim().isEmpty) {
        message = strings.speechNotRecognised;
        return null;
      }
      return text.trim();
    } on SpeechException catch (error) {
      if (!_disposed && generation == _generation) message = error.message;
      return null;
    } catch (_) {
      if (!_disposed && generation == _generation) {
        message = strings.speechFailed;
      }
      return null;
    } finally {
      if (!_disposed && generation == _generation) {
        busy = false;
        notifyListeners();
      }
    }
  }

  Future<void> cancel() async {
    if (!busy) return;
    ++_generation;
    // Keep actions blocked until the native microphone has been released.
    await _cancelService();
    if (_disposed) return;
    busy = false;
    notifyListeners();
  }

  Future<void> _cancelService() async {
    try {
      await _service.cancel();
    } catch (_) {
      // Cancellation must not surface platform details or update a disposed view.
    }
  }

  @override
  void dispose() {
    _disposed = true;
    ++_generation;
    if (busy) _cancelService();
    super.dispose();
  }
}
