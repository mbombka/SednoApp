import 'package:flutter/foundation.dart';
import 'package:sedno_app/features/simplification/domain/text_mode.dart';

/// One undo step for the latest AI result; history is stored independently.
class EditorResultViewModel extends ChangeNotifier {
  String? _originalText;
  TextMode? _mode;
  bool _busy = false;

  TextMode? get mode => _mode;
  bool get hasOriginal => _originalText != null;
  bool get busy => _busy;

  void setBusy(bool value) {
    if (_busy == value) return;
    _busy = value;
    notifyListeners();
  }

  void show({required String originalText, required TextMode mode}) {
    _originalText = originalText;
    _mode = mode;
    notifyListeners();
  }

  String? restoreOriginal() {
    if (_busy) return null;
    final original = _originalText;
    clear();
    return original;
  }

  void clear() {
    if (!hasOriginal) return;
    _originalText = null;
    _mode = null;
    notifyListeners();
  }
}
