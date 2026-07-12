import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';

/// Small gold "Sponsored" pill shown on sponsored communities.
///
/// Used in the community detail header and (compact) on the community list row
/// so the business sponsorship is visible but subtle.
class SponsoredBadge extends StatelessWidget {
  const SponsoredBadge({super.key, this.compact = false});

  /// Render a tighter variant for dense rows (e.g. the Exchange-style card).
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final double fontSize = compact ? 9 : 10;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 5 : 7,
        vertical: compact ? 1 : 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.richGold.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(compact ? 4 : 6),
        border: Border.all(
          color: AppColors.richGold.withValues(alpha: 0.5),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.workspace_premium,
            size: compact ? 10 : 12,
            color: AppColors.richGold,
          ),
          SizedBox(width: compact ? 3 : 4),
          Text(
            AppLocalizations.of(context)!.communitiesSponsored,
            style: TextStyle(
              color: AppColors.richGold,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
