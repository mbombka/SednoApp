import 'package:sedno_app/l10n/localization.dart';

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
  AppLocalizations Function() localizations = polishStrings;
  AppLocalizations get strings => localizations();

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

  // Locale changes keep the text and loading state, but discard old translated errors.
  void updateLocalizations(AppLocalizations value) {
    final changed = strings.localeName != value.localeName;
    localizations = () => value;
    if (changed && !isLoading) {
      _errorMessage = isOverLimit ? strings.textTooLong : null;
      if (_status == TextInputStatus.error) _status = TextInputStatus.idle;
    }
  }

  void setMode(TextMode value) {
    if (isLoading || mode == value) return;
    mode = value;
    _status = TextInputStatus.idle;
    _errorMessage = isOverLimit ? strings.textTooLong : null;
    notifyListeners();
  }

  void setText(String value) {
    if (isLoading || value == _text) return;
    _text = value;
    _status = TextInputStatus.idle;
    _errorMessage = isOverLimit ? strings.textTooLong : null;
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
    } on FormatException {
      _status = TextInputStatus.error;
      _errorMessage = _text.trim().isEmpty
          ? strings.emptyText
          : strings.textTooLong;
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
          ? strings.correctionUnavailable
          : strings.simplificationUnavailable;
    } on TimeoutException {
      if (_disposed) return;
      _status = TextInputStatus.error;
      _errorMessage = strings.requestTimeout;
    } on QuotaExceededException {
      if (_disposed) return;
      _status = TextInputStatus.error;
      _errorMessage =
          '${strings.quotaUsed}\n${strings.resetAt(QuotaReset.localTime())}';
    } on SimplificationApiException catch (error) {
      if (_disposed) return;
      _status = TextInputStatus.error;
      _errorMessage = switch (error.kind) {
        SimplificationFailure.offline => strings.offline,
        SimplificationFailure.timeout => strings.requestTimeout,
        SimplificationFailure.unauthorized => strings.sessionExpired,
        SimplificationFailure.rateLimited => strings.quotaExhausted,
        SimplificationFailure.unavailable => strings.serviceUnavailable,
        SimplificationFailure.rejected =>
          mode == TextMode.correct
              ? strings.correctionRejected
              : strings.simplificationRejected,
      };
    } catch (_) {
      if (_disposed) return;
      _status = TextInputStatus.error;
      _errorMessage = mode == TextMode.correct
          ? strings.correctionFailed
          : strings.simplificationFailed;
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
