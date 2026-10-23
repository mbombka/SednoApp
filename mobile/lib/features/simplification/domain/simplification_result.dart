import 'package:sedno_app/features/shared/domain/app_language.dart';
import 'package:sedno_app/features/simplification/domain/input_text.dart';
import 'package:sedno_app/features/simplification/domain/text_mode.dart';
import 'package:sedno_app/features/shared/domain/json_values.dart';

class SimplificationResult {
  SimplificationResult({
    required this.id,
    required this.text,
    required this.createdAt,
    this.mode = TextMode.simplify,
    this.language = AppLanguage.polish,
  }) {
    if (id.trim().isEmpty || text.trim().isEmpty) {
      throw const FormatException('Nieprawidłowy wynik uproszczenia.');
    }
  }

  final String id;
  final String text;
  final DateTime createdAt;
  final TextMode mode;
  final AppLanguage language;

  Map<String, Object?> toJson() => {
    'id': id,
    'text': text,
    'createdAt': createdAt.toUtc().toIso8601String(),
    if (mode != TextMode.simplify) 'mode': mode.name,
    if (language != AppLanguage.polish) 'language': language.code,
  };

  factory SimplificationResult.fromJson(Map<String, dynamic> json) =>
      SimplificationResult(
        id: requiredString(json, 'id'),
        text: requiredString(json, 'text'),
        createdAt: requiredUtcDate(json, 'createdAt'),
        mode: TextMode.fromJson(json['mode']),
        language: AppLanguage.fromCode(json['language'] as String?),
      );
}

class SimplificationRequest {
  SimplificationRequest({
    required this.input,
    required this.requestId,
    this.mode = TextMode.simplify,
    this.language = AppLanguage.polish,
  }) {
    if (requestId.trim().isEmpty) {
      throw const FormatException('Brak identyfikatora żądania.');
    }
  }

  final InputText input;
  final String requestId;
  final TextMode mode;
  final AppLanguage language;

  Map<String, Object?> toJson() => {
    'text': input.value,
    'requestId': requestId,
    if (mode != TextMode.simplify) 'mode': mode.name,
    if (language != AppLanguage.polish) 'language': language.code,
  };

  factory SimplificationRequest.fromJson(Map<String, dynamic> json) =>
      SimplificationRequest(
        input: InputText.fromJson(json),
        requestId: requiredString(json, 'requestId'),
        mode: TextMode.fromJson(json['mode']),
        language: AppLanguage.fromCode(json['language'] as String?),
      );
}
