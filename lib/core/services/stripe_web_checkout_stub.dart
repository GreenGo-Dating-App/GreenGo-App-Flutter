/// Mobile (iOS / Android) implementation of [StripeWebCheckout] — deliberately
/// inert.
///
/// WHY THIS FILE EXISTS
/// --------------------
/// Stripe Checkout is an EXTERNAL payment method for digital goods. Shipping it
/// inside a store binary violates App Store Guideline 3.1.1 and Google Play's
/// Payments policy, and is an automatic rejection.
///
/// Guarding the call sites with `kIsWeb` was not enough: the real Stripe code
/// still got compiled into the iOS and Android binaries, where a single missed
/// guard (or a null-plugin fallback) could reach it — which is exactly the bug
/// that shipped before.
///
/// So the real implementation now lives in `stripe_web_checkout_web.dart` and is
/// selected by a conditional import in `stripe_web_checkout.dart`. On mobile,
/// THIS file is compiled instead, and it contains no checkout logic, no
/// `createStripeCheckoutSession` call and no `launchUrl`. The mobile binary
/// therefore has no reachable path to an external payment page at all.
///
/// Mobile purchases go exclusively through `in_app_purchase` (StoreKit / Play
/// Billing). See `coin_shop_screen.dart` and `purchase_recovery_service.dart`.
class StripeWebCheckout {
  StripeWebCheckout._();

  /// Always false on mobile — store billing is the only permitted path.
  static bool get isSupported => false;

  /// No-op on mobile. Returns null so any caller that slips past a `kIsWeb`
  /// guard fails closed instead of opening an external payment page.
  static Future<String?> startCheckout(String productId) async {
    assert(
      false,
      'StripeWebCheckout.startCheckout called on a mobile build. Digital goods '
      'must go through in_app_purchase — this would be an App Store 3.1.1 / '
      'Google Play Payments violation.',
    );
    return null;
  }

  /// No-op on mobile.
  static Future<Set<String>> existingCompletedOrderIds() async => <String>{};

  /// No-op on mobile.
  static Future<bool> waitForCompletion(
    Set<String> knownIds, {
    Duration timeout = const Duration(minutes: 6),
  }) async =>
      false;
}
