import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sedno_app/features/history/data/encrypted_history_repository.dart';
import 'package:sedno_app/features/history/domain/history_entry.dart';
import 'package:sedno_app/features/simplification/domain/input_text.dart';
import 'package:sedno_app/features/simplification/domain/simplification_result.dart';

class MemoryDocumentStore implements HistoryDocumentStore {
  String? document;
  int clears = 0;
  PlatformException? readError;

  @override
  Future<String?> read() async {
    if (readError case final error?) throw error;
    return document;
  }

  @override
  Future<void> write(String value) async => document = value;

  @override
  Future<void> clear() async {
    document = null;
    clears++;
    readError = null;
  }
}

HistoryEntry entry(String id, DateTime createdAt) => HistoryEntry(
  original: InputText('Oryginał $id'),
  result: SimplificationResult(id: id, text: 'Wynik $id', createdAt: createdAt),
);

void main() {
  late MemoryDocumentStore store;
  late DateTime now;
  late EncryptedHistoryRepository repository;

  setUp(() {
    store = MemoryDocumentStore();
    now = DateTime.utc(2026, 10, 14, 12);
    repository = EncryptedHistoryRepository(store: store, clock: () => now);
  });

  test('saves and loads entries across repository instances', () async {
    await repository.save(entry('a', now));
    final reopened = EncryptedHistoryRepository(store: store, clock: () => now);
    final loaded = await reopened.readAll();
    expect(loaded.single.id, 'a');
    expect(loaded.single.original.value, 'Oryginał a');
    expect(loaded.single.result.text, 'Wynik a');
  });

  test(
    'expires exactly at seven days and purges the stored document',
    () async {
      final createdAt = now;
      await repository.save(entry('a', createdAt));
      now = createdAt.add(const Duration(days: 7, microseconds: -1));
      expect((await repository.readAll()).single.id, 'a');
      now = createdAt.add(const Duration(days: 7));
      expect(await repository.readAll(), isEmpty);
      expect(store.document, isNull);
    },
  );

  test(
    'filters expired entries while retaining and sorting live entries',
    () async {
      final old = entry('old', now.subtract(const Duration(days: 7)));
      final newest = entry('new', now);
      final older = entry('live', now.subtract(const Duration(days: 6)));
      store.document = jsonEncode([
        old.toJson(),
        older.toJson(),
        newest.toJson(),
      ]);
      expect((await repository.readAll()).map((e) => e.id), ['new', 'live']);
      expect(store.document, isNot(contains('old')));
    },
  );

  test('deletes one entry and clears all entries', () async {
    await repository.save(entry('a', now));
    await repository.save(entry('b', now));
    await repository.delete('a');
    expect((await repository.readAll()).map((e) => e.id), ['b']);
    await repository.clear();
    expect(await repository.readAll(), isEmpty);
    expect(store.document, isNull);
  });

  test(
    'corrupted JSON or entry clears history without displaying data',
    () async {
      store.document = '{broken';
      expect(await repository.readAll(), isEmpty);
      expect(store.document, isNull);
      store.document = '[{"result":{}}]';
      expect(await repository.readAll(), isEmpty);
      expect(store.document, isNull);
    },
  );

  test('native authentication failure clears unreadable ciphertext', () async {
    store.readError = PlatformException(code: 'CORRUPT');
    expect(await repository.readAll(), isEmpty);
    expect(store.clears, 1);
  });

  test(
    'other native failures are reported and not treated as corruption',
    () async {
      store.readError = PlatformException(code: 'STORAGE');
      await expectLater(
        repository.readAll(),
        throwsA(isA<PlatformException>()),
      );
      expect(store.clears, 0);
    },
  );
}
