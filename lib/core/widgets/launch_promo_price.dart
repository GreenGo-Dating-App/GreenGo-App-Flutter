import 'package:flutter/material.dart';

import '../../generated/app_localizations.dart';
import '../constants/app_colors.dart';
import '../constants/launch_promo.dart';

/// The 2026 launch price block of a membership card: a "2026 launch price"
/// badge, the launch price, "first year / first 3 months, then {regular}" and
/// who it is for. No struck-through former price (owner decision 2026-10-13).
///
/// For a [PromoPrice.generic] (iOS StoreKit 2 does not expose the offer) it
/// shows the regular price and a generic "50% off your first period" line.
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final regular = promo.regularLabel;
    final big = promo.isGeneric ? regular : promo.launchLabel;
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
        if (promo.isGeneric)
          Text(
            l10n.promoGenericStoreOffer('${LaunchPromo.percentOff}'),
            style: const TextStyle(fontSize: 12, color: Colors.white70),
          )
        else if (regular != null)
          Text(
            promo.yearly
                ? l10n.promoFirstYearThen(regular)
                : l10n.promoFirst3MonthsThen(regular),
            style: const TextStyle(fontSize: 13, color: Colors.white70),
          ),
        if (!promo.isGeneric)
          Text(
            l10n.promoUntilNote,
            style: const TextStyle(fontSize: 11, color: Colors.white54),
          ),
      ],
    );
  }
}
