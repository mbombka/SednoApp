import 'package:flutter_test/flutter_test.dart';
import 'package:sedno_app/features/quota/domain/quota_reset.dart';

// Polish time without depending on the test machine's time zone:
// UTC+2 from the last Sunday of March to the last Sunday of October 2026.
DateTime _poland(DateTime utc) {
  final summer =
      !utc.isBefore(DateTime.utc(2026, 3, 29, 1)) &&
      utc.isBefore(DateTime.utc(2026, 10, 25, 1));
  return utc.add(Duration(hours: summer ? 2 : 1));
}

void main() {
  test('next reset is the following 00:00 UTC', () {
    expect(
      QuotaReset.next(DateTime.utc(2026, 10, 20, 23, 59)),
      DateTime.utc(2026, 10, 21),
    );
    expect(
      QuotaReset.next(DateTime.utc(2026, 12, 31, 0, 0, 1)),
      DateTime.utc(2027, 1, 1),
    );
  });

  test('shows the server reset moment as Polish clock time', () {
    expect(
      QuotaReset.localTime(resetAt: DateTime.utc(2026, 7, 1), toLocal: _poland),
      '2:00',
    );
    expect(
      QuotaReset.localTime(
        resetAt: DateTime.utc(2026, 12, 1),
        toLocal: _poland,
      ),
      '1:00',
    );
    // The night of the change to winter time uses winter time for that reset.
    expect(
      QuotaReset.localTime(
        resetAt: DateTime.utc(2026, 10, 26),
        toLocal: _poland,
      ),
      '1:00',
    );
  });

  test('without server data uses the next reset after now', () {
    expect(
      QuotaReset.localTime(
        now: DateTime.utc(2026, 10, 20, 12),
        toLocal: _poland,
      ),
      '2:00',
    );
    expect(
      QuotaReset.localTime(
        resetAt: DateTime.utc(2026, 10, 21),
        toLocal: (utc) => utc.add(const Duration(hours: 5, minutes: 30)),
      ),
      '5:30',
    );
  });
}
