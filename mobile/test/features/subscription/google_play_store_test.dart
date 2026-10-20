import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:sedno_app/features/subscription/data/google_play_store.dart';
import 'package:sedno_app/features/subscription/domain/play_subscription_configuration.dart';

class _Billing extends Fake implements InAppPurchase {
  List<ProductDetails> products = [];
  Set<String>? requestedIds;
  PurchaseParam? purchase;

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> identifiers,
  ) async {
    requestedIds = identifiers;
    return ProductDetailsResponse(productDetails: products, notFoundIDs: []);
  }

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    purchase = purchaseParam;
    return true;
  }
}

SubscriptionOfferDetailsWrapper _offer(
  String basePlanId, {
  String? offerId,
  String period = 'P1M',
  RecurrenceMode recurrence = RecurrenceMode.infiniteRecurring,
  String price = '9,99 zł',
}) => SubscriptionOfferDetailsWrapper(
  basePlanId: basePlanId,
  offerId: offerId,
  offerTags: const [],
  offerIdToken: '$basePlanId-${offerId ?? "base"}',
  pricingPhases: [
    PricingPhaseWrapper(
      billingCycleCount: 0,
      billingPeriod: period,
      formattedPrice: price,
      priceAmountMicros: 9990000,
      priceCurrencyCode: 'PLN',
      recurrenceMode: recurrence,
    ),
  ],
);

List<GooglePlayProductDetails> _products(
  List<SubscriptionOfferDetailsWrapper> offers,
) => GooglePlayProductDetails.fromProductDetails(
  ProductDetailsWrapper(
    description: '400 uproszczeń dziennie',
    name: 'Sedno',
    productId: PlaySubscriptionConfiguration.productId,
    productType: ProductType.subs,
    subscriptionOfferDetails: offers,
    title: 'Sedno',
  ),
);

void main() {
  late _Billing billing;
  late GooglePlayStore store;
  setUp(() {
    billing = _Billing();
    store = GooglePlayStore(
      productId: PlaySubscriptionConfiguration.productId,
      basePlanId: PlaySubscriptionConfiguration.basePlanId,
      billing: billing,
    );
  });

  test(
    'selects the monthly base plan instead of the first plan or promotion',
    () async {
      billing.products = _products([
        _offer('annual', period: 'P1Y', price: '99,99 zł'),
        _offer('monthly', offerId: 'promotion', price: '0,00 zł'),
        _offer('monthly', price: '12,34 zł'),
      ]);

      final offer = await store.offer();

      expect(billing.requestedIds, {'subscription_full'});
      expect(offer.price, '12,34 zł'); // Display the actual store price.
      await store.buy('account-binding');
      final purchase = billing.purchase! as GooglePlayPurchaseParam;
      expect(purchase.productDetails.id, 'subscription_full');
      expect(purchase.offerToken, 'monthly-base');
      expect(purchase.applicationUserName, 'account-binding');
    },
  );

  final unsupported = [
    _offer('annual', period: 'P1Y'),
    _offer('monthly', offerId: 'promotion'),
    _offer('monthly', period: 'P1Y'),
    _offer('monthly', recurrence: RecurrenceMode.nonRecurring),
  ];
  for (var i = 0; i < unsupported.length; i++) {
    test('does not buy an unsupported plan or offer ($i)', () async {
      billing.products = _products([_offer('monthly')]);
      await store.offer();
      billing.products = _products([unsupported[i]]);

      await expectLater(store.buy('account-binding'), throwsStateError);
      expect(billing.purchase, isNull);
    });
  }
}
