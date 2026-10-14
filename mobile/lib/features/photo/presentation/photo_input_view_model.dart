import 'package:flutter/foundation.dart';
import 'package:simplifier_app/features/photo/domain/photo_text_repository.dart';

class PhotoInputViewModel extends ChangeNotifier {
  PhotoInputViewModel(this.repository);

  final PhotoTextRepository repository;
  bool _isLoading = false;
  bool _disposed = false;
  String? _message;

  bool get isLoading => _isLoading;
  String? get message => _message;

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
        _message = 'Nie wykryto tekstu. Zrób wyraźniejsze zdjęcie.';
        return null;
      }
      return text;
    } on CameraPermissionDenied {
      if (!_disposed) {
        _message = 'Brak dostępu do aparatu. Zezwól na dostęp w ustawieniach telefonu.';
      }
      return null;
    } catch (_) {
      if (!_disposed) {
        _message = 'Nie udało się odczytać tekstu. Spróbuj ponownie.';
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
