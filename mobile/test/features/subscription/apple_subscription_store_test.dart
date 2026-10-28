import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_2_wrappers.dart';
import 'package:sedno_app/features/subscription/data/apple_subscription_store.dart';
import 'package:sedno_app/features/subscription/domain/subscription_repository.dart';

class _Billing extends Fake implements InAppPurchase {
  final events = StreamController<List<PurchaseDetails>>.broadcast(sync: true);
  List<ProductDetails> products = [];
  PurchaseParam? purchase;
  int completed = 0;
  int restores = 0;
  @override
  Stream<List<PurchaseDetails>> get purchaseStream => events.stream;
  @override
  Future<bool> isAvailable() async => true;
  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> ids) async =>
      ProductDetailsResponse(productDetails: products, notFoundIDs: []);
  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    purchase = purchaseParam;
    return true;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async {
    completed++;
  }

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {
    restores++;
  }
}

AppStoreProduct2Details _product({
  SK2SubscriptionPeriodUnit period = SK2SubscriptionPeriodUnit.month,
  SK2ProductType type = SK2ProductType.autoRenewable,
}) => AppStoreProduct2Details.fromSK2Product(
  SK2Product(
    id: 'sedno_monthly',
    displayName: 'Sedno',
    displayPrice: '12,34 zł',
    description: 'Sedno',
    price: 12.34,
    type: type,
    priceLocale: SK2PriceLocale(currencyCode: 'PLN', currencySymbol: 'zł'),
    subscription: SK2SubscriptionInfo(
      subscriptionGroupID: 'sedno',
      promotionalOffers: [],
      subscriptionPeriod: SK2SubscriptionPeriod(value: 1, unit: period),
    ),
  ),
);

void main() {
  late _Billing billing;
  late AppleSubscriptionStore store;
  setUp(() {
    billing = _Billing();
    store = AppleSubscriptionStore(
      productId: 'sedno_monthly',
      billing: billing,
    );
  });
  tearDown(() => billing.events.close());

  test(
    'selects monthly StoreKit2 subscription and displays store price',
    () async {
      billing.products = [_product()];
      expect((await store.offer()).price, '12,34 zł');
      const binding = '12345678-1234-1234-1234-123456789abc';
      await store.buy(binding);
      expect(billing.purchase?.applicationUserName, binding);
      await expectLater(store.buy('google-hash'), throwsStateError);
    },
  );
  test('rejects yearly and non-renewable purchases', () async {
    billing.products = [_product(period: SK2SubscriptionPeriodUnit.year)];
    await expectLater(store.offer(), throwsStateError);
    billing.products = [_product(type: SK2ProductType.nonRenewable)];
    await expectLater(store.offer(), throwsStateError);
  });
  test(
    'does not finish a purchase when merely reading the store event',
    () async {
      final received = store.purchases.first;
      final purchase = PurchaseDetails(
        purchaseID: '123456',
        productID: 'sedno_monthly',
        verificationData: PurchaseVerificationData(
          localVerificationData: 'signed',
          serverVerificationData: 'signed',
          source: 'app_store',
        ),
        transactionDate: '0',
        status: PurchaseStatus.purchased,
      )..pendingCompletePurchase = true;
      billing.events.add([purchase]);
      final item = (await received).single;
      expect(item.token, '123456');
      expect(item.source, 'app_store');
      expect(item.state, StorePurchaseState.purchased);
      expect(billing.completed, 0);
      await item.complete!();
      expect(billing.completed, 1);
      await store.restore();
      expect(billing.restores, 1);
    },
  );
  test('management uses the App Store subscription page', () async {
    Uri? opened;
    final managing = AppleSubscriptionStore(
      productId: 'sedno_monthly',
      billing: billing,
      openUrl: (url) async {
        opened = url;
        return true;
      },
    );
    await managing.manage();
    expect(opened.toString(), 'https://apps.apple.com/account/subscriptions');
  });
}
