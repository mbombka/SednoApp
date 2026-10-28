enum StorePurchaseState { pending, purchased, restored, canceled, error }

class StorePurchase {
  const StorePurchase(
    this.productId,
    this.token,
    this.state, {
    this.source = 'google_play',
    this.transactionId,
    this.complete,
  });
  final String productId;
  final String token;
  final StorePurchaseState state;
  final String source;
  final String? transactionId;
  // StoreKit transactions finish only after successful backend verification.
  // Android acknowledgement remains exclusively on the server.
  final Future<void> Function()? complete;
}

class SubscriptionOffer {
  const SubscriptionOffer(this.price);
  final String price;
}

class SubscriptionStatus {
  const SubscriptionStatus({
    required this.active,
    required this.state,
    required this.accountBinding,
    this.store = 'google_play',
  });
  final bool active;
  final String state;
  final String accountBinding;
  final String store;
}

abstract interface class SubscriptionStore {
  Stream<List<StorePurchase>> get purchases;
  Future<SubscriptionOffer> offer();
  Future<void> buy(String accountBinding);
  Future<void> restore();
  Future<void> manage();
}

abstract interface class SubscriptionRepository {
  Future<SubscriptionStatus> current();
  Future<SubscriptionStatus> verify(String token);
}
