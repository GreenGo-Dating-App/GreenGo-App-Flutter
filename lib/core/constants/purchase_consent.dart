/// Consumer-law consent for web (Stripe) purchases. Plan P2-9.
///
/// These version strings must match the server allowlist in the web repo
/// (`functions/src/payments/stripeConsumerLaw.ts`): the order records which
/// wording the buyer saw. Change the localized text (`checkoutCoinWaiverCheckbox`,
/// `checkoutMembershipWithdrawalInfo`) only with counsel, and bump the version
/// here AND on the server when you do.
library;

/// EU CRD art. 16(m) immediate-delivery waiver shown before a coin checkout.
const String kCoinWaiverVersion = 'coins-immediate-delivery-2026-10-v1';

/// Withdrawal information shown before a membership checkout.
const String kMembershipWithdrawalNoticeVersion =
    'membership-withdrawal-notice-2026-10-v1';

/// Coin packages are immediate digital content (waiver); everything else sold
/// on the web is a membership (a service with a withdrawal period).
bool isCoinProduct(String productId) => productId.startsWith('greengo_coins_');

/// What the buyer agreed to in the pre-checkout step.
class CheckoutConsent {
  const CheckoutConsent({
    this.waiverAccepted = false,
    this.waiverVersion,
    this.withdrawalNoticeVersion,
  });

  final bool waiverAccepted;
  final String? waiverVersion;
  final String? withdrawalNoticeVersion;

  /// Fields added to the `createStripeCheckoutSession` payload.
  Map<String, dynamic> toPayload() => {
        if (waiverAccepted) 'waiverAccepted': true,
        if (waiverVersion != null) 'waiverVersion': waiverVersion,
        if (withdrawalNoticeVersion != null)
          'withdrawalNoticeVersion': withdrawalNoticeVersion,
      };
}
