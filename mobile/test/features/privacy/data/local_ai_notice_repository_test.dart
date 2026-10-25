import 'package:flutter_test/flutter_test.dart';
import 'package:sedno_app/features/privacy/data/local_ai_notice_repository.dart';

void main() {
  test(
    'acceptance survives a new repository using the same local storage',
    () async {
      String? saved;
      LocalAiNoticeRepository repository() => LocalAiNoticeRepository(
        read: () async => saved,
        write: (value) async => saved = value,
      );
      expect(await repository().hasAccepted(), isFalse);
      await repository().accept();
      expect(await repository().hasAccepted(), isTrue);
      saved =
          null; // Clearing app data or reinstalling starts a new installation.
      expect(await repository().hasAccepted(), isFalse);
    },
  );

  for (final value in [null, '', 'false', 'invalid']) {
    test('unaccepted stored value $value does not skip notice', () async {
      final repository = LocalAiNoticeRepository(
        read: () async => value,
        write: (_) async {},
      );
      expect(await repository.hasAccepted(), isFalse);
    });
  }

  test('read failure requires acceptance', () async {
    final repository = LocalAiNoticeRepository(
      read: () async => throw StateError('storage unavailable'),
      write: (_) async {},
    );
    expect(await repository.hasAccepted(), isFalse);
  });

  test(
    'write failure keeps acceptance for this run and asks on next run',
    () async {
      LocalAiNoticeRepository repository() => LocalAiNoticeRepository(
        read: () async => null,
        write: (_) async => throw StateError('storage unavailable'),
      );
      final first = repository();
      await first.accept();
      expect(await first.hasAccepted(), isTrue);
      expect(await repository().hasAccepted(), isFalse);
    },
  );
}
