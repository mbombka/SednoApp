const packProductId = 'simplifications_1000';

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
    this.packPurchasesEnabled = false,
  });
  final bool active;
  final String state;
  final String accountBinding;
  final bool packPurchasesEnabled;
}

abstract interface class SubscriptionStore {
  Stream<List<StorePurchase>> get purchases;
  Future<SubscriptionOffer> offer();
  Future<SubscriptionOffer> packOffer();
  Future<void> buyPack(String accountBinding);
  Future<List<StorePurchase>> pendingPacks();
  Future<void> buy(String accountBinding);
  Future<void> restore();
  Future<void> manage();
}

abstract interface class SubscriptionRepository {
  Future<SubscriptionStatus> current();
  Future<SubscriptionStatus> verify(String token);
  Future<String> verifyPack(String token);
}
