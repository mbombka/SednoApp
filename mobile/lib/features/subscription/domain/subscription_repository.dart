enum StorePurchaseState { pending, purchased, restored, canceled, error }

class StorePurchase {
  const StorePurchase(this.productId, this.token, this.state);
  final String productId;
  final String token;
  final StorePurchaseState state;
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
  });
  final bool active;
  final String state;
  final String accountBinding;
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
