import 'package:sedno_app/features/shared/domain/json_values.dart';
import 'package:sedno_app/features/simplification/domain/input_text.dart';
import 'package:sedno_app/features/simplification/domain/simplification_result.dart';

/// This model is for local encrypted storage only; the API never accepts history.
class HistoryEntry {
  HistoryEntry({required this.original, required this.result});

  final InputText original;
  final SimplificationResult result;

  String get id => result.id;
  DateTime get createdAt => result.createdAt;

  bool isExpiredAt(DateTime now) =>
      !createdAt.add(const Duration(days: 7)).isAfter(now.toUtc());

  Map<String, Object?> toJson() => {
    'original': original.value,
    'result': result.toJson(),
  };

  factory HistoryEntry.fromJson(Map<String, dynamic> json) {
    final rawResult = json['result'];
    if (rawResult is! Map<String, dynamic>) {
      throw const FormatException('Nieprawidłowa historia.');
    }
    return HistoryEntry(
      original: InputText(requiredString(json, 'original')),
      result: SimplificationResult.fromJson(rawResult),
    );
  }
}
