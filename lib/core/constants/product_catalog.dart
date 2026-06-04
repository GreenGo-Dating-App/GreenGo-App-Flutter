import 'dart:io';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

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

  /// Google Play ID → canonical (reverse of [_androidIds]).
  static final Map<String, String> _androidToCanonical = <String, String>{
    for (final MapEntry<String, String> e in _androidIds.entries) e.value: e.key,
  };

  /// Map a canonical app product ID to the store ID for the current platform.
  /// iOS prefixes with `subscription_`; Android uses the bespoke Play IDs.
  static String storeId(String canonicalId) {
    if (Platform.isIOS) return 'subscription_$canonicalId';
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

  /// Every store ID to query for the current platform.
  static Set<String> allStoreIds() =>
      canonicalIds.map(storeId).toSet();

  /// Store ID for the base membership on the current platform.
  static String get baseStoreId => storeId(baseMembership);

  /// The localized recurring (non-free-trial) price for a queried subscription
  /// product as the store formats it for the user's region, e.g. "R$ 24,99" or
  /// "$4.99". On Android, skips the free-trial phase (price 0) and returns the
  /// first non-zero pricing phase; on iOS returns [ProductDetails.price].
  /// Returns null when no price is available. Never hard-code a currency.
  static String? recurringPriceLabel(ProductDetails product) {
    if (product is GooglePlayProductDetails) {
      final offers = product.productDetails.subscriptionOfferDetails;
      final idx = product.subscriptionIndex;
      if (offers != null && idx != null && idx < offers.length) {
        final phases = offers[idx].pricingPhases;
        for (final phase in phases.reversed) {
          if (phase.priceAmountMicros > 0) return phase.formattedPrice;
        }
      }
    }
    return product.price.isNotEmpty ? product.price : null;
  }
}
