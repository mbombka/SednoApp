import 'package:simplifier_app/features/quota/domain/quota_state.dart';
import 'package:simplifier_app/features/simplification/domain/simplification_result.dart';

class SimplificationResponse {
  SimplificationResponse({required this.result, required this.quota});

  final SimplificationResult result;
  final QuotaState quota;

  Map<String, Object?> toJson() => {
    'result': result.toJson(),
    'quota': quota.toJson(),
  };

  factory SimplificationResponse.fromJson(Map<String, dynamic> json) {
    final result = json['result'];
    final quota = json['quota'];
    if (result is! Map<String, dynamic> || quota is! Map<String, dynamic>) {
      throw const FormatException('Nieprawidłowa odpowiedź serwera.');
    }
    return SimplificationResponse(
      result: SimplificationResult.fromJson(result),
      quota: QuotaState.fromJson(quota),
    );
  }
}

abstract interface class SimplificationRepository {
  Future<SimplificationResponse> simplify(SimplificationRequest request);
}
