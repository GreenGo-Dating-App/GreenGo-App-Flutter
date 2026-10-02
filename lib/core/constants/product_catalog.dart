import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart'
    show SubscriptionOfferDetailsWrapper;
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

/// Membership tier a store product grants (display/grouping only).
enum MembershipProductTier { base, silver, gold, platinum }

/// Billing period of a membership product.
enum MembershipPeriod { monthly, yearly }

/// Result of [ProductCatalog.classify]: what a store (or canonical) product ID
/// is, for grouping and labelling in the membership screens.
class MembershipProductInfo {
  const MembershipProductInfo({
    required this.canonicalId,
    required this.tier,
    required this.period,
    required this.isKnown,
  });

  /// Canonical app ID ([ProductCatalog.canonicalId] of the input).
  final String canonicalId;
  final MembershipProductTier tier;
  final MembershipPeriod period;

  /// False when the ID is not in [ProductCatalog.canonicalIds]; [tier] and
  /// [period] were then guessed from the ID text.
  final bool isKnown;

  bool get isBase => tier == MembershipProductTier.base;
  bool get isYearly => period == MembershipPeriod.yearly;
  bool get isMonthly => period == MembershipPeriod.monthly;

  @override
  String toString() =>
      'MembershipProductInfo($canonicalId, $tier, $period, known: $isKnown)';
}

/// Central, hard-coded mapping between the app's canonical membership product
/// IDs and the per-platform store IDs.
///
/// The App Store (iOS) and Google Play use DIFFERENT product IDs for the same
/// membership, and neither fully matches the canonical IDs used in app code and
/// in the Cloud Functions `PRODUCT_CONFIG`. This class is the single source of
/// truth for that mapping so query/purchase/restore all agree.
///
/// - Canonical (app code / server): `greengo_base_membership`, `1_month_silver`,
///   `1_year_silver`, `1_month_gold`, `1_year_gold`, `1_month_platinum`,
///   `1_year_platinum_membership`.
/// - iOS (App Store Connect): canonical prefixed with `subscription_`.
/// - Android (Google Play): bespoke IDs (see [_androidIds]).
class ProductCatalog {
  ProductCatalog._();

  /// Canonical base ("GreenGo VIP") membership product ID.
  static const String baseMembership = 'greengo_base_membership';

  /// All canonical product IDs (also the server `PRODUCT_CONFIG` keys).
  static const List<String> canonicalIds = <String>[
    'greengo_base_membership',
    '1_month_silver',
    '1_year_silver',
    '1_month_gold',
    '1_year_gold',
    '1_month_platinum',
    '1_year_platinum_membership',
  ];

  /// canonical → Google Play subscription product ID.
  static const Map<String, String> _androidIds = <String, String>{
    'greengo_base_membership': 'greengo_base_membership',
    '1_month_silver': 'silver_premium_monthly',
    '1_year_silver': 'greengo_silver_yearly',
    '1_month_gold': 'gold_premium_monthly',
    '1_year_gold': 'greengo_gold_yearly',
    '1_month_platinum': 'platinum_vip_monthly',
    '1_year_platinum_membership': 'greengo_platinum_yearly',
  };

  /// canonical → Google Play ID (read-only view, for tests/diagnostics).
  static Map<String, String> get androidIds => _androidIds;

  /// canonical → App Store ID (iOS prefixes the canonical ID).
  static String iosStoreId(String canonicalId) => 'subscription_$canonicalId';

  /// Google Play ID → canonical (reverse of [_androidIds]).
  static final Map<String, String> _androidToCanonical = <String, String>{
    for (final MapEntry<String, String> e in _androidIds.entries) e.value: e.key,
  };

  /// Map a canonical app product ID to the store ID for the current platform.
  /// iOS prefixes with `subscription_`; Android uses the bespoke Play IDs.
  static String storeId(String canonicalId) {
    // Web (Stripe) uses the canonical IDs directly — and `Platform` isn't
    // available on web, so guard before touching it.
    if (kIsWeb) return canonicalId;
    if (Platform.isIOS) return iosStoreId(canonicalId);
    return _androidIds[canonicalId] ?? canonicalId;
  }

  /// Map a store-returned product ID (iOS-prefixed or Android-renamed) back to
  /// the canonical app ID used for tier matching and server `verifyPurchase`.
  static String canonicalId(String storeId) {
    if (storeId.startsWith('subscription_')) {
      return storeId.substring('subscription_'.length);
    }
    return _androidToCanonical[storeId] ?? storeId;
  }

  /// canonical ID → (tier, period). Base is a 1-year membership
  /// (server `PRODUCT_CONFIG`: durationDays 365 / interval 'year').
  static const Map<String, (MembershipProductTier, MembershipPeriod)> _info =
      <String, (MembershipProductTier, MembershipPeriod)>{
    'greengo_base_membership': (MembershipProductTier.base, MembershipPeriod.yearly),
    '1_month_silver': (MembershipProductTier.silver, MembershipPeriod.monthly),
    '1_year_silver': (MembershipProductTier.silver, MembershipPeriod.yearly),
    '1_month_gold': (MembershipProductTier.gold, MembershipPeriod.monthly),
    '1_year_gold': (MembershipProductTier.gold, MembershipPeriod.yearly),
    '1_month_platinum': (MembershipProductTier.platinum, MembershipPeriod.monthly),
    '1_year_platinum_membership':
        (MembershipProductTier.platinum, MembershipPeriod.yearly),
  };

  static final Set<String> _loggedUnknown = <String>{};

  /// Classify any membership product ID — canonical, iOS (`subscription_`
  /// prefixed) or Google Play — into tier + period. The single classifier the
  /// membership screens use for grouping and labels; never use substring
  /// checks on raw store IDs (Play IDs look like `silver_premium_monthly`).
  ///
  /// Unknown IDs are never dropped: they are logged once and classified by a
  /// best-effort guess from the ID text (period defaults to monthly).
  static MembershipProductInfo classify(String productId) {
    final canonical = canonicalId(productId);
    final known = _info[canonical];
    if (known != null) {
      return MembershipProductInfo(
        canonicalId: canonical,
        tier: known.$1,
        period: known.$2,
        isKnown: true,
      );
    }
    if (_loggedUnknown.add(productId)) {
      debugPrint('[ProductCatalog] Unknown membership product id "$productId" '
          '— classified heuristically; add it to ProductCatalog.');
    }
    final id = productId.toLowerCase();
    final MembershipProductTier tier;
    if (id.contains('platinum')) {
      tier = MembershipProductTier.platinum;
    } else if (id.contains('gold')) {
      tier = MembershipProductTier.gold;
    } else if (id.contains('silver')) {
      tier = MembershipProductTier.silver;
    } else {
      tier = MembershipProductTier.base;
    }
    final period = (id.contains('year') || id.contains('annual'))
        ? MembershipPeriod.yearly
        : MembershipPeriod.monthly;
    return MembershipProductInfo(
      canonicalId: canonical,
      tier: tier,
      period: period,
      isKnown: false,
    );
  }

  /// Every store ID to query for the current platform.
  static Set<String> allStoreIds() =>
      canonicalIds.map(storeId).toSet();

  /// Store ID for the base membership on the current platform.
  static String get baseStoreId => storeId(baseMembership);

  /// Choose the ONE entry to show (and buy) for a product the store returned
  /// several times. On Google Play a subscription comes back as one
  /// [GooglePlayProductDetails] per base plan / offer, all with the same id.
  ///
  /// Rule, in order:
  ///  1. an offer with a free-trial phase (Play only returns offers the user
  ///     is eligible for; the app ships the 7-day trial copy);
  ///  2. the base plan (no offer id; else the entry whose only phase is the
  ///     recurring price);
  ///  3. the first entry the store returned.
  /// iOS/web return a single entry per id, which is returned as-is.
  static ProductDetails pickOffer(List<ProductDetails> entries) {
    assert(entries.isNotEmpty, 'pickOffer needs at least one entry');
    if (entries.length == 1) return entries.first;
    for (final e in entries) {
      if (freeTrialPeriod(e) != null) return e;
    }
    ProductDetails? singlePhase;
    for (final e in entries) {
      final offer = _offerOf(e);
      if (offer == null) continue;
      if (offer.offerId == null) return e;
      if (singlePhase == null && offer.pricingPhases.length == 1) {
        singlePhase = e;
      }
    }
    return singlePhase ?? entries.first;
  }

  /// One entry per product id, in the order ids first appear, each chosen
  /// with [pickOffer].
  static List<ProductDetails> onePerProduct(List<ProductDetails> products) {
    final byId = <String, List<ProductDetails>>{};
    for (final p in products) {
      (byId[p.id] ??= <ProductDetails>[]).add(p);
    }
    return <ProductDetails>[for (final group in byId.values) pickOffer(group)];
  }

  static SubscriptionOfferDetailsWrapper? _offerOf(ProductDetails product) {
    if (product is! GooglePlayProductDetails) return null;
    final offers = product.productDetails.subscriptionOfferDetails;
    final idx = product.subscriptionIndex;
    if (offers == null || idx == null || idx >= offers.length) return null;
    return offers[idx];
  }

  /// The recurring (non-trial, non-intro) price of a store product, or null
  /// when the store reports no non-zero amount.
  ///
  /// On Android `ProductDetails.price` / `rawPrice` are the offer's FIRST
  /// pricing phase — "Free" / 0 for a free-trial offer, or a discounted intro
  /// price — so they must not be shown as the plan price. This picks the last
  /// non-zero phase (the one that renews). On iOS `price` is already the
  /// regular price.
  static ({String label, double amount, String currencySymbol})? recurringPrice(
      ProductDetails product) {
    if (product is GooglePlayProductDetails) {
      final offers = product.productDetails.subscriptionOfferDetails;
      final idx = product.subscriptionIndex;
      if (offers != null && idx != null && idx < offers.length) {
        for (final phase in offers[idx].pricingPhases.reversed) {
          if (phase.priceAmountMicros > 0) {
            return (
              label: phase.formattedPrice,
              amount: phase.priceAmountMicros / 1000000.0,
              currencySymbol:
                  _currencySymbolOf(phase.formattedPrice) ?? phase.priceCurrencyCode,
            );
          }
        }
      }
    }
    if (product.price.isEmpty || product.rawPrice <= 0) return null;
    return (
      label: product.price,
      amount: product.rawPrice,
      currencySymbol: product.currencySymbol,
    );
  }

  /// Same rule as the Play plugin: leading/trailing non-digit, non-space run.
  static String? _currencySymbolOf(String formatted) {
    final m = RegExp(r'^[^\d ]*|[^\d ]*$').firstMatch(formatted)?.group(0);
    return (m == null || m.isEmpty) ? null : m;
  }

  /// ISO-8601 length (e.g. `P7D`, `P1W`) of the free-trial phase of an
  /// Android subscription offer, or null when the offer has no free phase.
  /// iOS introductory offers aren't exposed on [ProductDetails]; returns null.
  static String? freeTrialPeriod(ProductDetails product) {
    if (product is! GooglePlayProductDetails) return null;
    final offers = product.productDetails.subscriptionOfferDetails;
    final idx = product.subscriptionIndex;
    if (offers == null || idx == null || idx >= offers.length) return null;
    final phases = offers[idx].pricingPhases;
    if (phases.length < 2 || phases.first.priceAmountMicros != 0) return null;
    return phases.first.billingPeriod;
  }

  /// True when the offer's free trial is exactly 7 days — the only trial the
  /// existing localized copy (`subscriptionFreeTrialInfo`: "7 days free, then
  /// renews at the price shown") describes truthfully.
  static bool hasSevenDayFreeTrial(ProductDetails product) {
    final p = freeTrialPeriod(product);
    return p == 'P7D' || p == 'P1W';
  }

  /// The localized recurring (non-free-trial) price for a queried subscription
  /// product as the store formats it for the user's region, e.g. "R$ 24,99" or
  /// "$4.99". On Android, skips the free-trial phase (price 0) and returns the
  /// first non-zero pricing phase; on iOS returns [ProductDetails.price].
  /// Returns null when no price is available. Never hard-code a currency.
  static String? recurringPriceLabel(ProductDetails product) {
    // Kept byte-for-byte compatible with the coin shop's existing behaviour
    // (falls back to `price` even when rawPrice is 0).
    final recurring = recurringPrice(product);
    if (recurring != null) return recurring.label;
    return product.price.isNotEmpty ? product.price : null;
  }
}
