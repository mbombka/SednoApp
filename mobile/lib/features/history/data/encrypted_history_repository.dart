import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:sedno_app/features/history/domain/history_entry.dart';
import 'package:sedno_app/features/history/domain/history_repository.dart';

/// Android encrypts this document with a Keystore key in the no-backup directory.
abstract interface class HistoryDocumentStore {
  Future<String?> read();
  Future<void> write(String document);
  Future<void> clear();
}

class PlatformHistoryDocumentStore implements HistoryDocumentStore {
  const PlatformHistoryDocumentStore();

  static const _channel = MethodChannel('pl.sedno/history');

  @override
  Future<String?> read() => _channel.invokeMethod<String>('read');

  @override
  Future<void> write(String document) =>
      _channel.invokeMethod<void>('write', document);

  @override
  Future<void> clear() => _channel.invokeMethod<void>('clear');
}

/// Android implements the document contract using Keystore and no-backup files.
class AndroidHistoryDocumentStore extends PlatformHistoryDocumentStore {
  const AndroidHistoryDocumentStore();
}

/// The iOS host implements the same document contract using CryptoKit and Keychain.
class IosHistoryDocumentStore extends PlatformHistoryDocumentStore {
  const IosHistoryDocumentStore();
}

class EncryptedHistoryRepository implements HistoryRepository {
  EncryptedHistoryRepository({required this.store, required this.clock});

  final HistoryDocumentStore store;
  final DateTime Function() clock;
  Future<void> _tail = Future<void>.value();

  Future<T> _serialized<T>(Future<T> Function() operation) {
    final result = _tail.then((_) => operation());
    _tail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace stackTrace) {},
    );
    return result;
  }

  Future<List<HistoryEntry>> _readLive() async {
    String? document;
    try {
      document = await store.read();
    } on PlatformException catch (error) {
      if (error.code != 'CORRUPT') rethrow;
      await store.clear();
      return [];
    }
    if (document == null) return [];

    try {
      final decoded = jsonDecode(document);
      if (decoded is! List) {
        throw const FormatException('Nieprawidłowa historia.');
      }
      final entries = decoded.map((value) {
        if (value is! Map<String, dynamic>) {
          throw const FormatException('Nieprawidłowa historia.');
        }
        return HistoryEntry.fromJson(value);
      }).toList();
      final now = clock().toUtc();
      final live = entries.where((entry) => !entry.isExpiredAt(now)).toList();
      if (live.length != entries.length) await _write(live);
      live.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return live;
    } on FormatException {
      await store.clear();
      return [];
    } on TypeError {
      await store.clear();
      return [];
    }
  }

  Future<void> _write(List<HistoryEntry> entries) => entries.isEmpty
      ? store.clear()
      : store.write(
          jsonEncode(entries.map((entry) => entry.toJson()).toList()),
        );

  @override
  Future<void> save(HistoryEntry entry) => _serialized(() async {
    final entries = await _readLive();
    if (entry.isExpiredAt(clock())) return;
    entries.removeWhere((existing) => existing.id == entry.id);
    entries.add(entry);
    await _write(entries);
  });

  @override
  Future<List<HistoryEntry>> readAll() => _serialized(_readLive);

  @override
  Future<void> delete(String id) => _serialized(() async {
    final entries = await _readLive();
    entries.removeWhere((entry) => entry.id == id);
    await _write(entries);
  });

  @override
  Future<void> clear() => _serialized(store.clear);
}
