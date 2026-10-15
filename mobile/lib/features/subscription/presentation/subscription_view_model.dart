import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sedno_app/features/subscription/domain/subscription_repository.dart';

class SubscriptionViewModel extends ChangeNotifier {
  SubscriptionViewModel({
    required this.store,
    required this.repository,
    required this.productId,
  });
  final SubscriptionStore store;
  final SubscriptionRepository repository;
  final String productId;
  StreamSubscription<List<StorePurchase>>? _listener;
  Future<void> _queue = Future.value();
  bool _disposed = false;
  bool busy = false;
  SubscriptionOffer? offer;
  SubscriptionStatus? status;
  String? message;

  Future<void> start() async {
    _listener ??= store.purchases.listen(
      (items) {
        _queue = _queue.then((_) => _purchases(items));
      },
      onError: (Object _) {
        message = 'Nie można odczytać płatności. Spróbuj przywrócić zakupy.';
        _notify();
      },
    );
    await refresh();
  }

  Future<void> refresh() async {
    await _run(() async {
      offer = await store.offer();
      status = await repository.current();
    });
  }

  Future<void> buy() => _run(() async {
    final current = await repository.current();
    status = current;
    if (current.active) {
      message = 'Subskrypcja jest już aktywna.';
      return;
    }
    await store.buy(current.accountBinding);
  });
  Future<void> restore() => _run(() async {
    await repository
        .current(); // Require an authenticated account before restoring.
    await store.restore();
    status = await repository.current();
    message = 'Sprawdzono zakupy. Potwierdzenie może potrwać chwilę.';
  });
  Future<void> _purchases(List<StorePurchase> items) async {
    for (final item in items.where((item) => item.productId == productId)) {
      if (_disposed) return;
      switch (item.state) {
        case StorePurchaseState.pending:
          message =
              'Płatność oczekuje na potwierdzenie. Limit pozostaje bez zmian.';
        case StorePurchaseState.canceled:
          message = 'Zakup anulowano.';
        case StorePurchaseState.error:
          message = 'Nie udało się kupić subskrypcji. Spróbuj ponownie.';
        case StorePurchaseState.purchased:
        case StorePurchaseState.restored:
          await _run(() async {
            status = await repository.verify(item.token);
            message = status!.active
                ? 'Subskrypcja jest aktywna.'
                : 'Subskrypcja nie jest aktywna.';
          });
      }
      _notify();
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_disposed) return;
    busy = true;
    message = null;
    _notify();
    try {
      await action();
    } catch (_) {
      status = null;
      message = 'Nie można potwierdzić subskrypcji. Zaloguj się, sprawdź połączenie i przywróć zakupy.';
    } finally {
      busy = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_listener?.cancel());
    super.dispose();
  }
}
