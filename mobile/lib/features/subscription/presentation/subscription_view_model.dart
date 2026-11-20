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
  Future<void>? _queue;
  bool _disposed = false;
  bool busy = false;
  SubscriptionOffer? offer;
  SubscriptionOffer? packOffer;
  SubscriptionStatus? status;
  String? message;

  Future<void> start() async {
    _listener ??= store.purchases.listen(
      (items) => unawaited(_enqueue(items)),
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
      final packOfferTask = () async {
        try {
          packOffer = await store.packOffer();
        } catch (_) {
          packOffer = null;
        }
      }();
      try {
        status = await repository.current();
        _notify();
      } finally {
        await Future.wait([offerTask, packOfferTask]);
      }
    });
    if (!_disposed && status?.packPurchasesEnabled == true) {
      try {
        await _enqueue(await store.pendingPacks());
      } catch (_) {
        // Play may be unavailable. The next refresh or RTDN can retry delivery.
      }
    }
  }

  Future<void> buyPack() => _run(() async {
    final current = await repository.current();
    status = current;
    if (current.accountBinding.isEmpty) {
      throw StateError(strings.signInBeforePurchase);
    }
    if (!current.packPurchasesEnabled) throw StateError(strings.purchaseFailed);
    await store.buyPack(current.accountBinding);
  }, errorMessage: () => strings.purchaseFailed);

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

  Future<void> _enqueue(List<StorePurchase> items) async {
    if (_disposed || items.isEmpty) return;
    final processing = (_queue ?? Future<void>.value()).then(
      (_) => _purchases(items),
    );
    _queue = processing;
    try {
      await processing;
    } finally {
      if (identical(_queue, processing)) _queue = null;
    }
  }

  Future<void> _purchases(List<StorePurchase> items) async {
    for (final item in items.where(
      (item) => item.productId == productId || item.productId == packProductId,
    )) {
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
          if (item.productId == packProductId) {
            await _run(() async {
              final state = await repository.verifyPack(item.token);
              message = switch (state) {
                'credited' => strings.packCredited,
                'pending' => strings.paymentPending,
                _ => strings.purchaseFailed,
              };
            }, errorMessage: () => strings.purchaseFailed);
          } else {
            await _run(() async {
              status = await repository.verify(item.token);
              message = status!.active
                  ? strings.subscriptionActive
                  : strings.subscriptionInactive;
            });
          }
      }
      _notify();
    }
  }

  Future<void> _run(
    Future<void> Function() action, {
    String Function()? errorMessage,
  }) async {
    if (_disposed) return;
    busy = true;
    message = null;
    _notify();
    try {
      await action();
    } catch (_) {
      if (errorMessage == null) status = null;
      message = errorMessage?.call() ?? strings.subscriptionVerifyFailed;
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
