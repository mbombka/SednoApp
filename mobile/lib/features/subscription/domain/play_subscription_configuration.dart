abstract final class PlaySubscriptionConfiguration {
  static const enabled = bool.fromEnvironment('PLAY_BILLING_ENABLED');
  static const productId = String.fromEnvironment(
    'PLAY_SUBSCRIPTION_PRODUCT_ID',
    defaultValue: 'subscription_full',
  );
  static const basePlanId = String.fromEnvironment(
    'PLAY_SUBSCRIPTION_BASE_PLAN_ID',
    defaultValue: 'monthly',
  );
}
