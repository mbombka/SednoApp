import 'package:simplifier_app/features/simplification/domain/input_text.dart';
import 'package:simplifier_app/features/shared/domain/json_values.dart';

class SimplificationResult {
  SimplificationResult({
    required this.id,
    required this.text,
    required this.createdAt,
  }) {
    if (id.trim().isEmpty || text.trim().isEmpty) {
      throw const FormatException('Nieprawidłowy wynik uproszczenia.');
    }
  }

  final String id;
  final String text;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'text': text,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };

  factory SimplificationResult.fromJson(Map<String, dynamic> json) =>
      SimplificationResult(
        id: requiredString(json, 'id'),
        text: requiredString(json, 'text'),
        createdAt: requiredUtcDate(json, 'createdAt'),
      );
}

class SimplificationRequest {
  SimplificationRequest({required this.input, required this.requestId}) {
    if (requestId.trim().isEmpty) {
      throw const FormatException('Brak identyfikatora żądania.');
    }
  }

  final InputText input;
  final String requestId;

  Map<String, Object?> toJson() => {
    'text': input.value,
    'requestId': requestId,
  };

  factory SimplificationRequest.fromJson(Map<String, dynamic> json) =>
      SimplificationRequest(
        input: InputText.fromJson(json),
        requestId: requiredString(json, 'requestId'),
      );
}
