import 'package:flutter/material.dart';

import '../../../../core/services/tier_entitlements.dart';
import '../../../../core/widgets/limit_reached_dialog.dart';
import '../../../../generated/app_localizations.dart';
import '../../../membership/domain/entities/membership.dart';

/// Central gate for the "sponsor a community" business feature.
///
/// A sponsor must be a business account ([Profile.isBusiness]) on the Platinum
/// tier — reusing the same Platinum gate as the business Analytics dashboard
/// ([TierEntitlements.analyticsEnabled]). Non-business / non-Platinum users get
/// the standard upgrade dialog.
class SponsorshipGate {
  const SponsorshipGate._();

  /// Whether a user with [isBusiness] on [tier] may sponsor a community and
  /// pin a promo (Platinum business only; test users included via entitlements).
  static bool canSponsor({
    required bool isBusiness,
    required MembershipTier tier,
  }) {
    return isBusiness && TierEntitlements.analyticsEnabled(tier);
  }

  /// Shows the standard upgrade/gated dialog explaining that sponsoring a
  /// community requires a Platinum business account.
  static Future<void> showGate(
    BuildContext context, {
    required MembershipTier currentTier,
    required String userId,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    await FeatureNotAvailableDialog.show(
      context: context,
      featureName: l10n.communitiesSponsorFeatureName,
      description: l10n.communitiesSponsorRequiresPlatinum,
      currentTier: currentTier,
      requiredTier: MembershipTier.platinum,
      userId: userId,
      icon: Icons.workspace_premium,
    );
  }
}
