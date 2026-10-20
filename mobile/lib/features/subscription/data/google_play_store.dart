import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:sedno_app/features/subscription/domain/subscription_repository.dart';
import 'package:url_launcher/url_launcher.dart';

class GooglePlayStore implements SubscriptionStore {
  GooglePlayStore({
    required this.productId,
    required this.basePlanId,
    InAppPurchase? billing,
    Future<bool> Function(Uri)? openUrl,
  }) : _billing = billing ?? InAppPurchase.instance,
       _openUrl = openUrl ?? _openExternal;
  final String productId;
  final String basePlanId;
  final InAppPurchase _billing;
  final Future<bool> Function(Uri) _openUrl;

  static Future<bool> _openExternal(Uri uri) =>
      launchUrl(uri, mode: LaunchMode.externalApplication);

  @override
  Future<void> manage() async {
    final uri = Uri.https('play.google.com', '/store/account/subscriptions', {
      'sku': productId,
      'package': 'xyz.sedno.app',
    });
    if (!await _openUrl(uri)) {
      throw StateError('Nie można otworzyć subskrypcji Google Play.');
    }
  }

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
    final product = await _loadProduct();
    return SubscriptionOffer(product.price);
  }

  Future<GooglePlayProductDetails> _loadProduct() async {
    if (!await _billing.isAvailable()) {
      throw StateError('Sklep jest niedostępny.');
    }
    final response = await _billing.queryProductDetails({productId});
    if (response.error != null || response.productDetails.isEmpty) {
      throw StateError('Brak oferty.');
    }
    final matching = response.productDetails
        .whereType<GooglePlayProductDetails>()
        .where((product) {
          final index = product.subscriptionIndex;
          final offers = product.productDetails.subscriptionOfferDetails;
          if (product.id != productId || index == null || offers == null) {
            return false;
          }
          final offer = offers[index];
          return offer.basePlanId == basePlanId &&
              offer.offerId == null &&
              offer.pricingPhases.length == 1 &&
              offer.pricingPhases.single.billingPeriod == 'P1M' &&
              offer.pricingPhases.single.recurrenceMode ==
                  RecurrenceMode.infiniteRecurring;
        })
        .toList();
    if (matching.length != 1) {
      throw StateError('Brak miesięcznej oferty subskrypcji.');
    }
    return matching.single;
  }

  @override
  Future<void> buy(String accountBinding) async {
    final product = await _loadProduct();
    if (!await _billing.buyNonConsumable(
      purchaseParam: GooglePlayPurchaseParam(
        productDetails: product,
        applicationUserName: accountBinding,
        offerToken: product.offerToken,
      ),
    )) {
      throw StateError('Nie udało się rozpocząć zakupu.');
    }
  }

  @override
  Future<void> restore() => _billing.restorePurchases();
  // Android acknowledgement is performed exclusively by the backend after verification.
}
