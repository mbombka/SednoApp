import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:sedno_app/features/subscription/domain/subscription_repository.dart';

class GooglePlayStore implements SubscriptionStore {
  GooglePlayStore({required this.productId, InAppPurchase? billing})
    : _billing = billing ?? InAppPurchase.instance;
  final String productId;
  final InAppPurchase _billing;
  ProductDetails? _product;

  @override
  Stream<List<StorePurchase>> get purchases => _billing.purchaseStream.map(
    (items) => items
        .where((item) => item.productID == productId)
        .map(
          (item) => StorePurchase(
            item.productID,
            item.verificationData.serverVerificationData,
            switch (item.status) {
              PurchaseStatus.pending => StorePurchaseState.pending,
              PurchaseStatus.purchased => StorePurchaseState.purchased,
              PurchaseStatus.restored => StorePurchaseState.restored,
              PurchaseStatus.canceled => StorePurchaseState.canceled,
              PurchaseStatus.error => StorePurchaseState.error,
            },
          ),
        )
        .toList(),
  );

  @override
  Future<SubscriptionOffer> offer() async {
    if (!await _billing.isAvailable()) {
      throw StateError('Sklep jest niedostępny.');
    }
    final response = await _billing.queryProductDetails({productId});
    if (response.error != null || response.productDetails.isEmpty) {
      throw StateError('Brak oferty.');
    }
    // Configure one monthly base plan, without introductory offers, in Play Console.
    _product = response.productDetails.first;
    return SubscriptionOffer(_product!.price);
  }

  @override
  Future<void> buy(String accountBinding) async {
    await offer();
    if (!await _billing.buyNonConsumable(
      purchaseParam: PurchaseParam(
        productDetails: _product!,
        applicationUserName: accountBinding,
      ),
    )) {
      throw StateError('Nie udało się rozpocząć zakupu.');
    }
  }

  @override
  Future<void> restore() => _billing.restorePurchases();
  // Android acknowledgement is performed exclusively by the backend after verification.
}
