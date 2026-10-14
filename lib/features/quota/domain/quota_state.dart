import 'package:simplifier_app/features/shared/domain/json_values.dart';

enum QuotaTier { free, subscription }

class QuotaState {
  QuotaState({
    required this.tier,
    required this.limit,
    required this.used,
    required this.remaining,
    required this.serverTime,
    required this.resetAt,
  }) {
    if (limit != (tier == QuotaTier.free ? 2 : 400) ||
        used < 0 ||
        used > limit ||
        remaining != limit - used ||
        !serverTime.isUtc ||
        !resetAt.isUtc ||
        !resetAt.isAfter(serverTime) ||
        resetAt.hour != 0 ||
        resetAt.minute != 0 ||
        resetAt.second != 0 ||
        resetAt.millisecond != 0 ||
        resetAt.microsecond != 0 ||
        resetAt.difference(serverTime) > const Duration(days: 1)) {
      throw const FormatException('Nieprawidłowy limit.');
    }
  }

  final QuotaTier tier;
  final int limit;
  final int used;
  final int remaining;
  final DateTime serverTime;
  final DateTime resetAt;

  Map<String, Object?> toJson() => {
    'tier': tier.name,
    'limit': limit,
    'used': used,
    'remaining': remaining,
    'serverTime': serverTime.toIso8601String(),
    'resetAt': resetAt.toIso8601String(),
  };

  factory QuotaState.fromJson(Map<String, dynamic> json) {
    final tierName = requiredString(json, 'tier');
    final tier = QuotaTier.values.where((value) => value.name == tierName);
    if (tier.isEmpty) throw const FormatException('Nieznany pakiet.');
    return QuotaState(
      tier: tier.single,
      limit: requiredInt(json, 'limit'),
      used: requiredInt(json, 'used'),
      remaining: requiredInt(json, 'remaining'),
      serverTime: requiredUtcDate(json, 'serverTime'),
      resetAt: requiredUtcDate(json, 'resetAt'),
    );
  }
}
