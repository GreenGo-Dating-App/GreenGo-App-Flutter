import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../data/services/age_verification_service.dart';
import '../screens/age_verification_screen.dart';

/// Central gate for publishing content other users will see.
///
/// Guideline 1.2.1 requires an age-restriction mechanism on creator content,
/// and 4.7.5 says the same for anything exceeding the app's age rating. The
/// server enforces it — `canPostChat()` in `firestore.rules` checks the
/// `isAgeVerified` flag that only Cloud Functions can set — so this class is
/// purely about the user not running head-first into a permission error.
///
/// Reading and joining a community stay open to everyone. The gate is on
/// broadcasting, which is what the guideline is actually about.
///
/// Mirrors [SponsorshipGate] in shape so the two read the same way.
class AgeVerificationGate {
  const AgeVerificationGate._();

  /// Returns true when the user may publish; otherwise explains why and offers
  /// the verification flow, then returns whatever the flow achieved.
  ///
  /// Call this immediately before a publish action, not on screen load — a
  /// prompt that appears the moment someone opens a community reads as a wall,
  /// while one that appears as they try to post reads as a reason.
  static Future<bool> ensureCanPublish(BuildContext context) async {
    final service = AgeVerificationService();
    final state = await service.loadState();
    if (state.canPublishToCommunities) return true;
    if (!context.mounted) return false;

    // Already submitted: say so rather than asking again.
    if (state.status == AgeVerificationStatus.pending) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.ageVerifyPending),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }

    final verified = await _showPrompt(context, state);
    return verified ?? false;
  }

  static Future<bool?> _showPrompt(
    BuildContext context,
    AgeVerificationState state,
  ) async {
    final l10n = AppLocalizations.of(context)!;

    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            const Icon(Icons.verified_user_outlined,
                color: AppColors.richGold, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n.ageVerifyNeededToPost,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          state.documentRequired
              ? l10n.ageVerifyWhyPhone
              : l10n.ageVerifyWhyPublish,
          style: const TextStyle(
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              l10n.ageVerifyLater,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.richGold,
              foregroundColor: AppColors.deepBlack,
            ),
            child: Text(l10n.ageVerifyCta),
          ),
        ],
      ),
    );

    if (proceed != true || !context.mounted) return false;

    return AgeVerificationScreen.push(
      context,
      reason: state.documentRequired
          ? AgeVerificationReason.phoneAccount
          : AgeVerificationReason.publishing,
    );
  }
}
