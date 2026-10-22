import 'package:flutter_test/flutter_test.dart';
import 'package:sedno_app/features/quota/domain/quota_state.dart';

void main() {
  Map<String, dynamic> quota() => {
    'tier': 'tester',
    'limit': 400,
    'used': 30,
    'remaining': 370,
    'serverTime': '2026-10-22T12:00:00Z',
    'resetAt': '2026-10-23T00:00:00Z',
    'testerAccessExpiresAt': '2026-11-15T19:00:00Z',
  };

  test('tester access round trips with server expiry', () {
    final value = QuotaState.fromJson(quota());
    expect(value.tier, QuotaTier.tester);
    expect(value.testerAccessExpiresAt, DateTime.utc(2026, 11, 15, 19));
    expect(QuotaState.fromJson(value.toJson()).remaining, 370);
  });

  test('downgrade keeps usage above the free limit and blocks submission', () {
    final data = quota()
      ..['tier'] = 'free'
      ..['limit'] = 5
      ..['remaining'] = 0
      ..['testerAccessExpiresAt'] = '2026-10-22T12:00:00Z';
    final value = QuotaState.fromJson(data);
    expect(value.used, 30);
    expect(value.remaining, 0);
    data['remaining'] = 1;
    expect(() => QuotaState.fromJson(data), throwsFormatException);
  });

  test('rejects a tester tier without a future UTC expiry', () {
    for (final expiry in [
      null,
      '2026-10-22T12:00:00Z',
      '2026-11-15T20:00:00+01:00',
      '2026-02-30T12:00:00Z',
    ]) {
      final data = quota()..['testerAccessExpiresAt'] = expiry;
      expect(() => QuotaState.fromJson(data), throwsFormatException);
    }
  });

  test('older server responses without a tester grant still work', () {
    final data = quota()
      ..['tier'] = 'subscription'
      ..remove('testerAccessExpiresAt');
    expect(QuotaState.fromJson(data).testerAccessExpiresAt, isNull);
  });
}
