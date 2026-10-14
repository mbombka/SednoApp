import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:simplifier_app/features/account/domain/account.dart';
import 'package:simplifier_app/features/history/domain/history_entry.dart';
import 'package:simplifier_app/features/quota/domain/quota_state.dart';
import 'package:simplifier_app/features/simplification/domain/input_text.dart';
import 'package:simplifier_app/features/simplification/domain/simplification_repository.dart';
import 'package:simplifier_app/features/simplification/domain/simplification_result.dart';

void main() {
  final now = DateTime.utc(2026, 10, 14, 12);
  final quota = QuotaState(
    tier: QuotaTier.free,
    limit: 2,
    used: 1,
    remaining: 1,
    serverTime: now,
    resetAt: DateTime.utc(2026, 10, 15),
  );

  test('counts grapheme clusters, including combining marks and emoji', () {
    expect(InputText('e\u0301👨‍👩‍👧‍👦🇵🇱').characterCount, 3);
    expect(InputText('🙂' * 4000).characterCount, 4000);
    expect(() => InputText('🙂' * 4001), throwsFormatException);
    expect(() => InputText(' \n\t '), throwsFormatException);
  });

  test('round trips request and response JSON', () {
    final request = SimplificationRequest(
      input: InputText('Zażółć gęślą jaźń'),
      requestId: 'req-1',
    );
    final result = SimplificationResult(
      id: 'result-1',
      text: 'Prostszy tekst.',
      createdAt: now,
    );
    final response = SimplificationResponse(result: result, quota: quota);
    final decodedRequest = SimplificationRequest.fromJson(
      jsonDecode(jsonEncode(request.toJson())) as Map<String, dynamic>,
    );
    final decodedResponse = SimplificationResponse.fromJson(
      jsonDecode(jsonEncode(response.toJson())) as Map<String, dynamic>,
    );
    expect(decodedRequest.input.value, request.input.value);
    expect(decodedRequest.requestId, request.requestId);
    expect(decodedResponse.result.text, result.text);
    expect(decodedResponse.result.createdAt, now);
    expect(decodedResponse.quota.remaining, 1);
  });

  test('round trips account and local history JSON', () {
    final account = Account(
      id: 'u-1',
      provider: IdentityProvider.google,
      email: 'a@example.pl',
      displayName: 'Ala',
    );
    final entry = HistoryEntry(
      original: InputText('Oryginał'),
      result: SimplificationResult(id: 'r-1', text: 'Wynik', createdAt: now),
    );
    final decodedAccount = Account.fromJson(
      jsonDecode(jsonEncode(account.toJson())) as Map<String, dynamic>,
    );
    final decodedEntry = HistoryEntry.fromJson(
      jsonDecode(jsonEncode(entry.toJson())) as Map<String, dynamic>,
    );
    expect(decodedAccount.provider, IdentityProvider.google);
    expect(decodedAccount.email, 'a@example.pl');
    expect(decodedEntry.original.value, 'Oryginał');
    expect(decodedEntry.id, 'r-1');
    expect(entry.isExpiredAt(now.add(const Duration(days: 7))), isTrue);
    expect(
      entry.isExpiredAt(now.add(const Duration(days: 7, microseconds: -1))),
      isFalse,
    );
  });

  test('rejects malformed and inconsistent server responses', () {
    expect(
      () => SimplificationResponse.fromJson({'result': {}, 'quota': {}}),
      throwsFormatException,
    );
    expect(
      () => SimplificationResult.fromJson({
        'id': 'r',
        'text': 'ok',
        'createdAt': '2026-02-30T00:00:00Z',
      }),
      throwsFormatException,
    );
    expect(
      () => SimplificationResult.fromJson({
        'id': 'r',
        'text': 'ok',
        'createdAt': '2026-10-14T12:00:00+02:00',
      }),
      throwsFormatException,
    );
    expect(
      () => QuotaState.fromJson({...quota.toJson(), 'remaining': 2}),
      throwsFormatException,
    );
    expect(
      () => QuotaState.fromJson({...quota.toJson(), 'tier': 'unknown'}),
      throwsFormatException,
    );
    expect(
      () => Account.fromJson({'id': 'u', 'provider': 'unknown'}),
      throwsFormatException,
    );
    expect(
      () => HistoryEntry.fromJson({'original': 'tekst', 'result': []}),
      throwsFormatException,
    );
  });
}
