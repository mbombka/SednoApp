import 'package:flutter_test/flutter_test.dart';
import 'package:sedno_app/features/shared/domain/json_values.dart';

void main() {
  test('accepts equivalent UTC representations from Dart and ASP.NET', () {
    for (final suffix in ['Z', '+00:00']) {
      expect(
        requiredUtcDate({'date': '2026-10-15T20:05:30.4732661$suffix'}, 'date'),
        DateTime.utc(2026, 10, 15, 20, 5, 30, 473, 266),
      );
    }
  });

  test('still rejects non-UTC, missing offsets and invalid calendar dates', () {
    for (final value in [
      '2026-10-15T20:05:30+02:00',
      '2026-10-15T20:05:30',
      '2026-10-15T20:05:30-00:00',
      '2026-02-30T20:05:30+00:00',
      '2026-10-15T25:05:30+00:00',
    ]) {
      expect(
        () => requiredUtcDate({'date': value}, 'date'),
        throwsFormatException,
      );
    }
  });
}
