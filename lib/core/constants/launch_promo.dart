import 'package:flutter/foundation.dart' show visibleForTesting;

/// The 2026 launch promo (owner decision 2026-10-13): every membership plan is
/// 50% off for its FIRST period - the first year of a yearly plan, the first
/// 3 months of a monthly plan - for subscriptions bought until 31 December
/// 2026 (end of day, Brazil time). Renewals are at the regular price.
///
/// Shown as a "2026 launch price" next to the regular price, never as a
/// struck-through former price. Everything promo-related hides itself once
/// [isActive] turns false, with no release needed.
///
/// Where the price comes from:
///  * web: `getDisplayPrices` / `getMembershipPrice` return a `promo` object
///    per membership (Stripe coupon, see the web repo's stripeCore.ts);
///  * Android: the Play offer `launch2026` on each base plan (intro phase,
///    picked by ProductCatalog.pickOffer);
///  * iOS: App Store introductory offers. StoreKit 2 (the plugin default)
///    does not expose them, so the app shows a generic line and the App
///    Store sheet shows the real price.
class LaunchPromo {
  LaunchPromo._();

  static const String id = 'launch2026';
  static const int percentOff = 50;

  /// Billing periods at the launch price.
  static const int monthlyPeriods = 3;
  static const int yearlyPeriods = 1;

  /// 31 Dec 2026 23:59:59 in Brazil (UTC-3) = 1 Jan 2027 03:00 UTC.
  static final DateTime endsAt = DateTime.utc(2027, 1, 1, 3);

  @visibleForTesting
  static DateTime Function() clock = DateTime.now;

  /// The current time (tests override [clock]).
  static DateTime now() => clock();

  static bool isActive([DateTime? now]) =>
      (now ?? clock()).toUtc().isBefore(endsAt);

  /// Launch prices (USD = EUR, BRL) per canonical product id. The regular
  /// prices live in SubscriptionTier / the stores.
  static const Map<String, (double usd, double brl)> launchPrices = {
    'greengo_base_membership': (4.99, 14.90),
    '1_month_silver': (4.99, 16.90),
    '1_month_gold': (9.99, 29.90),
    '1_month_platinum': (14.99, 44.90),
    '1_year_silver': (34.99, 124.90),
    '1_year_gold': (59.99, 199.90),
    '1_year_platinum_membership': (89.99, 299.90),
  };
}

/// A launch price to show for one plan.
class PromoPrice {
  const PromoPrice({
    required this.yearly,
    this.launchLabel,
    this.launchAmount,
    this.regularLabel,
    this.regularAmount,
  });

  /// The store did not tell the app the launch price (iOS StoreKit 2): show
  /// the regular price plus a generic "50% off your first period" line.
  const PromoPrice.generic({required this.yearly, this.regularLabel})
      : launchLabel = null,
        launchAmount = null,
        regularAmount = null;

  final bool yearly;

  /// Formatted launch price, e.g. "R$ 14,90"; null for [PromoPrice.generic].
  final String? launchLabel;
  final double? launchAmount;

  /// Formatted regular (renewal) price.
  final String? regularLabel;
  final double? regularAmount;

  bool get isGeneric => launchLabel == null;

  int get periods =>
      yearly ? LaunchPromo.yearlyPeriods : LaunchPromo.monthlyPeriods;
}
