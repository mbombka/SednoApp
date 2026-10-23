import 'dart:async';

import 'package:sedno_app/features/simplification/domain/text_mode.dart';

import 'package:characters/characters.dart';
import 'package:flutter/foundation.dart';
import 'package:sedno_app/features/quota/domain/quota_reset.dart';
import 'package:sedno_app/features/shared/data/development_mocks.dart';
import 'package:sedno_app/features/simplification/data/http_simplification_repository.dart';
import 'package:sedno_app/features/simplification/domain/input_text.dart';

typedef SubmitText = Future<void> Function(InputText input);

enum TextInputStatus { idle, loading, success, error }

class TextInputViewModel extends ChangeNotifier {
  TextInputViewModel({required this.onSubmit});

  final SubmitText onSubmit;
  TextMode mode = TextMode.simplify;
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

  void setMode(TextMode value) {
    if (isLoading || mode == value) return;
    mode = value;
    _status = TextInputStatus.idle;
    _errorMessage = isOverLimit
        ? 'Tekst może mieć maksymalnie 4000 znaków.'
        : null;
    notifyListeners();
  }

  void setText(String value) {
    if (isLoading || value == _text) return;
    _text = value;
    _status = TextInputStatus.idle;
    _errorMessage = isOverLimit
        ? 'Tekst może mieć maksymalnie 4000 znaków.'
        : null;
    notifyListeners();
  }

  // The view receives the result before the submission Future completes.
  void replaceWithResult(String value) {
    _text = value;
    _errorMessage = null;
    notifyListeners();
  }

  void clear() {
    if (isLoading) return;
    _text = '';
    _status = TextInputStatus.idle;
    _errorMessage = null;
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
      _errorMessage = mode == TextMode.correct
          ? 'Poprawianie tekstu nie jest jeszcze dostępne.'
          : 'Upraszczanie tekstu nie jest jeszcze dostępne.';
    } on TimeoutException {
      if (_disposed) return;
      _status = TextInputStatus.error;
      _errorMessage = 'Przekroczono czas oczekiwania. Spróbuj ponownie.';
    } on QuotaExceededException {
      if (_disposed) return;
      _status = TextInputStatus.error;
      _errorMessage =
          'Dzisiejszy limit został wykorzystany.\n'
          'Nowy limit o ${QuotaReset.localTime()}.';
    } on SimplificationApiException catch (error) {
      if (_disposed) return;
      _status = TextInputStatus.error;
      _errorMessage = switch (error.kind) {
        SimplificationFailure.offline =>
          'Brak połączenia z internetem. Spróbuj ponownie.',
        SimplificationFailure.timeout =>
          'Przekroczono czas oczekiwania. Spróbuj ponownie.',
        SimplificationFailure.unauthorized =>
          'Sesja wygasła. Sprawdź konto i spróbuj ponownie.',
        SimplificationFailure.rateLimited =>
          'Dzisiejszy limit został wykorzystany. Sprawdź czas odnowienia.',
        SimplificationFailure.unavailable =>
          'Usługa jest chwilowo niedostępna. Spróbuj ponownie.',
        SimplificationFailure.rejected =>
          mode == TextMode.correct
              ? 'Nie można poprawić tego tekstu. Sprawdź dane i spróbuj ponownie.'
              : 'Nie można uprościć tego tekstu. Sprawdź dane i spróbuj ponownie.',
      };
    } catch (_) {
      if (_disposed) return;
      _status = TextInputStatus.error;
      _errorMessage = mode == TextMode.correct
          ? 'Nie udało się poprawić tekstu. Spróbuj ponownie.'
          : 'Nie udało się uprościć tekstu. Spróbuj ponownie.';
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
