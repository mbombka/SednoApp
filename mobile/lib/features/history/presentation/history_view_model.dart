import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:simplifier_app/features/history/domain/history_entry.dart';
import 'package:simplifier_app/features/history/domain/history_repository.dart';

class HistoryViewModel extends ChangeNotifier {
  HistoryViewModel(this.repository);

  final HistoryRepository repository;
  List<HistoryEntry> entries = [];
  bool isLoading = true;
  bool hasError = false;
  bool _disposed = false;
  Timer? _expirationTimer;

  Future<void> refresh() async {
    if (_disposed) return;
    _expirationTimer?.cancel();
    isLoading = true;
    notifyListeners();
    try {
      final loaded = await repository.readAll();
      if (_disposed) return;
      entries = loaded;
      hasError = false;
      if (entries.isNotEmpty) {
        final nextExpiration = entries
            .map((entry) => entry.createdAt.add(const Duration(days: 7)))
            .reduce((a, b) => a.isBefore(b) ? a : b);
        final delay = nextExpiration.difference(DateTime.now().toUtc());
        if (delay > Duration.zero) {
          _expirationTimer = Timer(delay, refresh);
        }
      }
    } catch (_) {
      entries = [];
      hasError = true;
    } finally {
      isLoading = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> delete(String id) async {
    try {
      await repository.delete(id);
      await refresh();
    } catch (_) {
      hasError = true;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _expirationTimer?.cancel();
    super.dispose();
  }
}
