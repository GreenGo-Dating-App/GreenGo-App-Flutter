import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/paid_listing_access.dart';
import '../../../../core/services/tier_gate.dart';
import '../../../../generated/app_localizations.dart';
import '../screens/business_account_screen.dart';

/// Shown in the event / experience wizards instead of the price options when
/// the user may not sell (see [PaidListingAccess]): "Paid tickets are
/// available for business accounts" + a link to Become a business (or, for a
/// lapsed business, to renew Platinum). [onReturn] runs after the user comes
/// back so the wizard can re-check the access.
class PaidBusinessNote extends StatelessWidget {
  const PaidBusinessNote({
    required this.uid,
    required this.access,
    this.onReturn,
    super.key,
  });

  final String uid;
  final PaidListingAccess access;
  final VoidCallback? onReturn;

  Future<void> _open(BuildContext context) async {
    if (access == PaidListingAccess.businessPaused) {
      TierGate().openMembershipUpgrade(context, currentUserId: uid);
    } else {
      await BusinessAccountScreen.open(context, uid);
    }
    onReturn?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final paused = access == PaidListingAccess.businessPaused;
    return Container(
      key: const ValueKey('paid-business-note'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.richGold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.richGold.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.storefront_outlined, color: AppColors.richGold),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                paused ? l.paidBusinessPausedNote : l.paidBusinessOnlyNote,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontWeight: FontWeight.w600),
              ),
            ),
          ]),
          const SizedBox(height: 6),
          Text(l.paidBusinessOnlyBody,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12.5, height: 1.35)),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const ValueKey('paid-business-note-action'),
              onPressed: () => _open(context),
              icon: Icon(paused ? Icons.workspace_premium : Icons.storefront,
                  color: AppColors.richGold, size: 18),
              label: Text(paused ? l.businessReactivate : l.becomeBusiness,
                  style: const TextStyle(color: AppColors.richGold)),
            ),
          ),
        ],
      ),
    );
  }
}
