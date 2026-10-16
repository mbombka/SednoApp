import 'package:flutter_test/flutter_test.dart';
import 'package:sedno_app/features/account/domain/account.dart';
import 'package:sedno_app/features/history/domain/history_entry.dart';
import 'package:sedno_app/features/shared/data/development_mocks.dart';
import 'package:sedno_app/features/simplification/domain/input_text.dart';
import 'package:sedno_app/features/simplification/domain/simplification_result.dart';

void main() {
  test(
    'mock quota resets at midnight UTC and retries do not consume it',
    () async {
      var now = DateTime.utc(2026, 10, 14, 23, 59);
      final quota = MockQuotaRepository(clock: () => now);
      final mock = MockSimplificationRepository(quota: quota, clock: () => now);
      final first = SimplificationRequest(
        input: InputText('Tekst pierwszy'),
        requestId: 'one',
      );
      final response = await mock.simplify(first);
      expect(response.quota.remaining, 4);
      expect((await mock.simplify(first)).result.id, 'one');
      expect((await quota.current()).remaining, 4);
      expect(
        () => mock.simplify(
          SimplificationRequest(
            input: InputText('Inny tekst'),
            requestId: 'one',
          ),
        ),
        throwsFormatException,
      );
      for (var i = 2; i <= 5; i++) {
        final response = await mock.simplify(
          SimplificationRequest(
            input: InputText('Tekst $i'),
            requestId: 'request-$i',
          ),
        );
        expect(response.quota.remaining, 5 - i);
      }
      expect(
        () => mock.simplify(
          SimplificationRequest(input: InputText('Szósty'), requestId: 'six'),
        ),
        throwsA(isA<QuotaExceededException>()),
      );
      now = DateTime.utc(2026, 10, 15);
      expect((await quota.current()).remaining, 5);
    },
  );

  test('mock history removes expired entries and sign-out clears it', () async {
    var now = DateTime.utc(2026, 10, 14, 12);
    final history = MockHistoryRepository(clock: () => now);
    final account = MockAccountRepository(history: history);
    await history.save(
      HistoryEntry(
        original: InputText('Oryginał'),
        result: SimplificationResult(id: 'r', text: 'Wynik', createdAt: now),
      ),
    );
    expect((await history.readAll()).length, 1);
    await account.signOut();
    expect(await history.readAll(), isEmpty);
    expect((await account.current()).provider, IdentityProvider.guest);
    await history.save(
      HistoryEntry(
        original: InputText('Oryginał'),
        result: SimplificationResult(id: 'r', text: 'Wynik', createdAt: now),
      ),
    );
    now = now.add(const Duration(days: 7));
    expect(await history.readAll(), isEmpty);
  });
}
