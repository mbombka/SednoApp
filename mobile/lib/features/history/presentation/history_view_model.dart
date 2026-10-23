import 'package:sedno_app/l10n/localization.dart';

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sedno_app/features/history/domain/history_entry.dart';
import 'package:sedno_app/features/history/domain/history_repository.dart';

class HistoryViewModel extends ChangeNotifier {
  AppLocalizations Function() localizations = polishStrings;
  AppLocalizations get strings => localizations();

  HistoryViewModel(this.repository);

  final HistoryRepository repository;
  List<HistoryEntry> entries = [];
  bool isLoading = true;
  bool hasError = false;
  bool isClearing = false;
  String? actionError;
  int _readRevision = 0;
  bool _disposed = false;
  Timer? _expirationTimer;

  Future<void> refresh() async {
    if (_disposed || isClearing) return;
    final revision = ++_readRevision;
    _expirationTimer?.cancel();
    isLoading = true;
    notifyListeners();
    try {
      final loaded = await repository.readAll();
      if (_disposed || revision != _readRevision) return;
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
      if (_disposed || revision != _readRevision) return;
      entries = [];
      hasError = true;
    } finally {
      if (!_disposed && revision == _readRevision) {
        isLoading = false;
        notifyListeners();
      }
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

  Future<bool> clearAll() async {
    if (_disposed || isClearing || isLoading) return false;
    ++_readRevision;
    _expirationTimer?.cancel();
    isClearing = true;
    actionError = null;
    notifyListeners();
    var cleared = false;
    try {
      await repository.clear();
      if (_disposed) return false;
      entries = [];
      hasError = false;
      cleared = true;
      return true;
    } catch (_) {
      if (!_disposed) {
        actionError = strings.historyClearFailed;
      }
      return false;
    } finally {
      isClearing = false;
      if (!_disposed) {
        if (cleared) {
          notifyListeners();
        } else {
          // Re-read after a failure to enforce expiry and re-arm its timer.
          await refresh();
        }
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _expirationTimer?.cancel();
    super.dispose();
  }
}
