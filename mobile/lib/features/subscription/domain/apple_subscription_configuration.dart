abstract final class AppleSubscriptionConfiguration {
  static const enabled = bool.fromEnvironment('APPLE_BILLING_ENABLED');
  // Configure this from the actual App Store Connect monthly subscription.
  static const productId = String.fromEnvironment(
    'APPLE_SUBSCRIPTION_PRODUCT_ID',
  );
}
