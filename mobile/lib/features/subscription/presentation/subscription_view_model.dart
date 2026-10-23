import 'package:sedno_app/l10n/localization.dart';

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:sedno_app/features/subscription/domain/subscription_repository.dart';

class SubscriptionViewModel extends ChangeNotifier {
  AppLocalizations Function() localizations = polishStrings;
  AppLocalizations get strings => localizations();

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
        message = strings.paymentReadFailed;
        _notify();
      },
    );
    // The backend enforces entitlement from its stored verification and Google
    // Play notifications. The app refreshes only at start, resume and sign-in.
    await refresh();
  }

  Future<void> refresh() async {
    await _run(() async {
      // Start server verification immediately; store availability must not delay it.
      final offerTask = () async {
        try {
          offer = await store.offer();
        } catch (_) {
          offer = null;
        }
      }();
      try {
        status = await repository.current();
        _notify();
      } finally {
        await offerTask;
      }
    });
  }

  Future<void> buy() => _run(() async {
    final current = await repository.current();
    status = current;
    if (current.accountBinding.isEmpty) {
      throw StateError(strings.signInBeforePurchase);
    }
    if (current.active) {
      message = strings.subscriptionAlreadyActive;
      return;
    }
    await store.buy(current.accountBinding);
  });
  Future<void> restore() => _run(() async {
    final current = await repository.current();
    if (current.accountBinding.isEmpty) {
      throw StateError(strings.signInBeforeRestore);
    }
    await store.restore();
    status = await repository.current();
    message = strings.purchasesChecked;
  });

  Future<void> manage() async {
    try {
      await store.manage();
    } catch (_) {
      message = strings.playOpenFailed;
      _notify();
    }
  }

  Future<void> _purchases(List<StorePurchase> items) async {
    for (final item in items.where((item) => item.productId == productId)) {
      if (_disposed) return;
      switch (item.state) {
        case StorePurchaseState.pending:
          message = strings.paymentPending;
        case StorePurchaseState.canceled:
          message = strings.purchaseCancelled;
        case StorePurchaseState.error:
          message = strings.purchaseFailed;
        case StorePurchaseState.purchased:
        case StorePurchaseState.restored:
          await _run(() async {
            status = await repository.verify(item.token);
            message = status!.active
                ? strings.subscriptionActive
                : strings.subscriptionInactive;
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
      message = strings.subscriptionVerifyFailed;
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
