import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_2_wrappers.dart';
import 'package:sedno_app/features/subscription/domain/subscription_repository.dart';
import 'package:url_launcher/url_launcher.dart';

// in_app_purchase uses StoreKit 2 by default on supported iOS versions. Do not
// enable StoreKit 1: the server verifies transaction IDs with App Store Server API.
class AppleSubscriptionStore implements SubscriptionStore {
  AppleSubscriptionStore({
    required this.productId,
    InAppPurchase? billing,
    Future<bool> Function(Uri)? openUrl,
  }) : _billing = billing ?? InAppPurchase.instance,
       _openUrl = openUrl ?? _openExternal;

  final String productId;
  final InAppPurchase _billing;
  final Future<bool> Function(Uri) _openUrl;

  static Future<bool> _openExternal(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);

  @override
  Stream<List<StorePurchase>> get purchases => _billing.purchaseStream.map(
    (items) => items
        .where((item) => item.productID == productId)
        .map(
          (item) => StorePurchase(
            item.productID,
            item.purchaseID ?? '',
            switch (item.status) {
              PurchaseStatus.pending => StorePurchaseState.pending,
              PurchaseStatus.purchased => StorePurchaseState.purchased,
              PurchaseStatus.restored => StorePurchaseState.restored,
              PurchaseStatus.canceled => StorePurchaseState.canceled,
              PurchaseStatus.error => StorePurchaseState.error,
            },
            source: 'app_store',
            transactionId: item.purchaseID,
            complete: item.pendingCompletePurchase
                ? () => _billing.completePurchase(item)
                : null,
          ),
        )
        .toList(),
  );

  Future<ProductDetails> _product() async {
    if (productId.isEmpty || !await _billing.isAvailable()) {
      throw StateError('Store unavailable');
    }
    final response = await _billing.queryProductDetails({productId});
    final products = response.productDetails
        .whereType<AppStoreProduct2Details>()
        .where((p) {
          final subscription = p.sk2Product.subscription;
          return p.id == productId &&
              p.sk2Product.type == SK2ProductType.autoRenewable &&
              subscription?.subscriptionPeriod.unit ==
                  SK2SubscriptionPeriodUnit.month &&
              subscription?.subscriptionPeriod.value == 1;
        });
    if (response.error != null || products.length != 1) {
      throw StateError('Subscription unavailable');
    }
    // The configured product must be a monthly auto-renewable subscription in
    // App Store Connect. Never substitute an introductory or hardcoded price.
    return products.single;
  }

  @override
  Future<SubscriptionOffer> offer() async =>
      SubscriptionOffer((await _product()).price);

  @override
  Future<void> buy(String accountBinding) async {
    if (!RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(accountBinding)) {
      throw StateError('Invalid account binding');
    }
    if (!await _billing.buyNonConsumable(
      purchaseParam: PurchaseParam(
        productDetails: await _product(),
        applicationUserName: accountBinding,
      ),
    )) {
      throw StateError('Purchase could not start');
    }
  }

  @override
  Future<void> restore() => _billing.restorePurchases();

  @override
  Future<void> manage() async {
    if (!await _openUrl(
      Uri.parse('https://apps.apple.com/account/subscriptions'),
    )) {
      throw StateError('Subscriptions unavailable');
    }
  }
}
