import 'package:sedno_app/l10n/localization.dart';
import 'package:flutter/foundation.dart';
import 'package:sedno_app/features/photo/domain/photo_text_repository.dart';

class PhotoInputViewModel extends ChangeNotifier {
  AppLocalizations Function() localizations = polishStrings;
  AppLocalizations get strings => localizations();

  PhotoInputViewModel(this.repository);

  final PhotoTextRepository repository;
  bool _isLoading = false;
  bool _disposed = false;
  String? _message;

  bool get isLoading => _isLoading;
  String? get message => _message;

  void clearMessage() => _message = null;

  Future<String?> scan() async {
    if (_isLoading) return null;
    _isLoading = true;
    _message = null;
    notifyListeners();
    try {
      final text = await repository.recognizeFromCamera();
      if (_disposed) return null;
      if (text == null) return null;
      if (text.trim().isEmpty) {
        _message = strings.photoNoText;
        return null;
      }
      return text;
    } on CameraPermissionDenied {
      if (!_disposed) {
        _message = strings.cameraPermission;
      }
      return null;
    } catch (_) {
      if (!_disposed) {
        _message = strings.readTextFailed;
      }
      return null;
    } finally {
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
