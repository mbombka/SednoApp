import 'dart:async';

import 'package:characters/characters.dart';
import 'package:flutter/foundation.dart';
import 'package:simplifier_app/features/shared/data/development_mocks.dart';
import 'package:simplifier_app/features/simplification/domain/input_text.dart';

typedef SubmitText = Future<void> Function(InputText input);

enum TextInputStatus { idle, loading, success, error }

class TextInputViewModel extends ChangeNotifier {
  TextInputViewModel({required this.onSubmit});

  final SubmitText onSubmit;
  String _text = '';
  String? _errorMessage;
  TextInputStatus _status = TextInputStatus.idle;
  bool _disposed = false;

  int get characterCount => _text.characters.length;
  String get characterCounter => '$characterCount/${InputText.maxCharacters}';
  String? get errorMessage => _errorMessage;
  TextInputStatus get status => _status;
  bool get isLoading => _status == TextInputStatus.loading;
  bool get isOverLimit => characterCount > InputText.maxCharacters;
  bool get canSubmit => !isLoading && !isOverLimit;

  void setText(String value) {
    if (isLoading || value == _text) return;
    _text = value;
    _status = TextInputStatus.idle;
    _errorMessage = isOverLimit
        ? 'Tekst może mieć maksymalnie 4000 znaków.'
        : null;
    notifyListeners();
  }

  Future<void> submit() async {
    if (isLoading) return;
    InputText input;
    try {
      input = InputText(_text);
    } on FormatException catch (error) {
      _status = TextInputStatus.error;
      _errorMessage = error.message;
      notifyListeners();
      return;
    }

    _status = TextInputStatus.loading;
    _errorMessage = null;
    notifyListeners();
    try {
      await onSubmit(input);
      if (_disposed) return;
      _status = TextInputStatus.success;
    } on SubmissionUnavailableException {
      if (_disposed) return;
      _status = TextInputStatus.error;
      _errorMessage = 'Upraszczanie tekstu nie jest jeszcze dostępne.';
    } on TimeoutException {
      if (_disposed) return;
      _status = TextInputStatus.error;
      _errorMessage = 'Przekroczono czas oczekiwania. Spróbuj ponownie.';
    } on QuotaExceededException {
      if (_disposed) return;
      _status = TextInputStatus.error;
      _errorMessage =
          'Dzisiejszy limit został wykorzystany. Spróbuj po północy UTC.';
    } catch (_) {
      if (_disposed) return;
      _status = TextInputStatus.error;
      _errorMessage = 'Nie udało się uprościć tekstu. Spróbuj ponownie.';
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class SubmissionUnavailableException implements Exception {
  const SubmissionUnavailableException();
}
