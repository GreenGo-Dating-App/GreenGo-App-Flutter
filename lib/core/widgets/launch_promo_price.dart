import 'package:flutter/material.dart';

import '../../generated/app_localizations.dart';
import '../constants/app_colors.dart';
import '../constants/launch_promo.dart';
import '../constants/product_catalog.dart';

/// The 2026 launch price block of a membership card: a "2026 launch price"
/// badge, the launch price, then ONE offer line, the same on every platform
/// (iOS: Apple 3.1.2(c) / 2.3.1; Android and web: owner 2026-10-17, no free
/// trials anywhere): "50% off your first year (3 months) for new subscribers:
/// {launch}, then {regular}/year (month)." plus where it renews / cancels and
/// the offer end date. No struck-through former price (owner 2026-10-13).
///
/// For a [PromoPrice.generic] (iOS StoreKit 2 does not expose the offer and
/// the storefront currency is not in the catalogue) the big price is the
/// regular one and the line omits the launch amount.
class LaunchPromoPrice extends StatelessWidget {
  const LaunchPromoPrice({
    required this.promo,
    required this.accent,
    this.priceFontSize = 24,
    this.suffix,
    super.key,
  });

  final PromoPrice promo;
  final Color accent;
  final double priceFontSize;

  /// Appended to the big price (e.g. "+ taxes").
  final String? suffix;

  /// The offer wording for [promo] ("50% off your first year for new
  /// subscribers: X, then Y/year."), or null when there is nothing truthful
  /// to say (no regular price).
  static String? offerLine(AppLocalizations l10n, PromoPrice promo) {
    final regular = promo.regularLabel;
    if (regular == null) return null;
    const pct = '${LaunchPromo.percentOff}';
    final launch = promo.launchLabel;
    if (launch == null) {
      return promo.yearly
          ? l10n.promoStoreFirstYearGeneric(pct, regular)
          : l10n.promoStoreFirst3MonthsGeneric(pct, regular);
    }
    return promo.yearly
        ? l10n.promoStoreFirstYear(pct, launch, regular)
        : l10n.promoStoreFirst3Months(pct, launch, regular);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final regular = promo.regularLabel;
    final big = promo.isGeneric ? regular : promo.launchLabel;
    final line = offerLine(l10n, promo);
    // Never claim an offer we cannot price.
    if (line == null) return const SizedBox.shrink();
    return _block(l10n, big, line);
  }

  Widget _block(AppLocalizations l10n, String? big, String line) {
    return Column(
      key: const ValueKey('launch-promo-price'),
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.richGold,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            l10n.promoLaunchBadge,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        const SizedBox(height: 6),
        if (big != null)
          Text(
            suffix == null ? big : '$big  $suffix',
            style: TextStyle(
              fontSize: priceFontSize,
              fontWeight: FontWeight.bold,
              color: accent,
            ),
          ),
        const SizedBox(height: 2),
        Text(
          line,
          key: const ValueKey('launch-promo-offer'),
          style: const TextStyle(fontSize: 13, color: Colors.white70),
        ),
        Text(
          ProductCatalog.isAppleStore
              ? l10n.promoRenewsAppStore
              : (ProductCatalog.isStoreApp
                  ? l10n.promoRenewsGooglePlay
                  : l10n.promoRenewsWeb),
          style: const TextStyle(fontSize: 11, color: Colors.white54),
        ),
        Text(
          l10n.promoUntilNote,
          style: const TextStyle(fontSize: 11, color: Colors.white54),
        ),
      ],
    );
  }
}
