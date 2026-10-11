import 'package:flutter/material.dart';

import '../../features/coins/domain/entities/coin_transaction.dart'
    show CoinFeaturePrices;
import '../../generated/app_localizations.dart';
import '../services/tier_entitlements.dart';

/// Membership comparison table (Base / Silver / Gold / Platinum).
///
/// Every value comes from [TierEntitlements.comparisonRows], the same numbers
/// the app's gates and the server enforce, so the table can never promise
/// something the plans do not include (audit 2026-10-11, M7).
class TierComparisonTable extends StatelessWidget {
  const TierComparisonTable({super.key});

  static const _gold = Color(0xFFD4AF37);
  static const _platinum = Color(0xFFB9F2FF);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rows = TierEntitlements.comparisonRows(
      l10n,
      travelCoinsPerDay: CoinFeaturePrices.traveler,
    );
    final headers = [
      l10n.membershipBase,
      l10n.membershipSilver,
      l10n.membershipGold,
      l10n.membershipPlatinum,
    ];
    final colors = [Colors.white70, Colors.white, _gold, _platinum];

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.membershipFeatureComparison,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: _gold,
            ),
          ),
          const SizedBox(height: 12),
          _row(
            '',
            headers,
            colors,
            header: true,
          ),
          const Divider(color: Colors.white24, height: 12),
          for (final r in rows) _row(r.label, r.values, colors),
        ],
      ),
    );
  }

  Widget _row(
    String label,
    List<String> values,
    List<Color> colors, {
    bool header = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
          for (var i = 0; i < values.length; i++)
            Expanded(
              flex: 2,
              child: Text(
                values[i],
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors[i],
                  fontSize: header ? 12 : 13,
                  fontWeight: header ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
