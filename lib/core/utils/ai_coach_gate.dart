import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../../features/profile/domain/entities/profile.dart';
import '../../features/membership/domain/entities/membership.dart';

/// Gates the AI Coach feature behind premium membership.
///
/// Access rules:
/// - Silver, Gold, Platinum, Test tiers: unlimited access
/// - Free tier: 30-minute trial total (tracked across sessions), OR Chapter 1 only
/// - Trial time is persistent — tracked in Firestore
class AiCoachGate {
  static const Duration trialDuration = Duration(minutes: 30);
  static const String _trialDocPath = 'ai_coach_trial';

  /// Check if user has access to AI Coach.
  /// Returns [AiCoachAccess] with access status and remaining trial time.
  static Future<AiCoachAccess> checkAccess(
      String userId, Profile profile) async {
    // Premium members have unlimited access
    if (_isPremium(profile.membershipTier)) {
      return const AiCoachAccess(
        hasAccess: true,
        isPremium: true,
        remainingTrialSeconds: 0,
        trialUsedSeconds: 0,
      );
    }

    // Free users — check trial time
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('feature_trials')
          .doc(_trialDocPath)
          .get();

      if (!doc.exists) {
        // First time — full trial available
        return AiCoachAccess(
          hasAccess: true,
          isPremium: false,
          remainingTrialSeconds: trialDuration.inSeconds,
          trialUsedSeconds: 0,
        );
      }

      final data = doc.data()!;
      final usedSeconds = data['usedSeconds'] as int? ?? 0;
      final remaining = trialDuration.inSeconds - usedSeconds;

      return AiCoachAccess(
        hasAccess: remaining > 0,
        isPremium: false,
        remainingTrialSeconds: remaining > 0 ? remaining : 0,
        trialUsedSeconds: usedSeconds,
      );
    } catch (e) {
      // On error, allow access (fail open for UX)
      return AiCoachAccess(
        hasAccess: true,
        isPremium: false,
        remainingTrialSeconds: trialDuration.inSeconds,
        trialUsedSeconds: 0,
      );
    }
  }

  /// Record trial time used (call when session ends)
  static Future<void> recordTrialUsage(
      String userId, int sessionSeconds) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('feature_trials')
          .doc(_trialDocPath)
          .set({
        'usedSeconds': FieldValue.increment(sessionSeconds),
        'lastSessionAt': FieldValue.serverTimestamp(),
        'sessionCount': FieldValue.increment(1),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('AiCoachGate: Failed to record usage: $e');
    }
  }

  /// Check if user has access to a specific chapter.
  /// Free users can access Chapter 1 (Month 1) without trial.
  static bool hasChapterAccess(Profile profile, int chapterNumber) {
    if (_isPremium(profile.membershipTier)) return true;
    // Free users get Chapter 1 for free (no trial needed)
    return chapterNumber <= 1;
  }

  static bool _isPremium(MembershipTier tier) {
    return tier == MembershipTier.silver ||
        tier == MembershipTier.gold ||
        tier == MembershipTier.platinum ||
        tier == MembershipTier.test;
  }

  /// Show the upgrade dialog when trial expires or access is denied.
  static Future<bool> checkAndGate(
      BuildContext context, String userId, Profile profile) async {
    final access = await checkAccess(userId, profile);

    if (access.hasAccess) return true;

    if (!context.mounted) return false;

    // Show upgrade dialog
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.school, color: AppColors.richGold),
            SizedBox(width: 8),
            Text(
              'Upgrade to Learn More',
              style: TextStyle(color: AppColors.textPrimary, fontSize: 18),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your free trial of AI Coach has ended.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            _buildBenefit('Unlimited AI conversation practice'),
            _buildBenefit('All learning chapters unlocked'),
            _buildBenefit('Real-time grammar & pronunciation feedback'),
            _buildBenefit('Personalized learning path'),
            const SizedBox(height: 16),
            const Text(
              'Upgrade to Silver, Gold, or Platinum to unlock.',
              style: TextStyle(
                color: AppColors.richGold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Maybe Later',
              style: TextStyle(color: AppColors.textTertiary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // Navigate to subscription screen
              Navigator.of(context).pushNamed('/subscription');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.richGold,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Upgrade Now'),
          ),
        ],
      ),
    );

    return false;
  }

  static Widget _buildBenefit(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.richGold, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Represents user's access status for AI Coach
class AiCoachAccess {
  final bool hasAccess;
  final bool isPremium;
  final int remainingTrialSeconds;
  final int trialUsedSeconds;

  const AiCoachAccess({
    required this.hasAccess,
    required this.isPremium,
    required this.remainingTrialSeconds,
    required this.trialUsedSeconds,
  });

  String get remainingTrialFormatted {
    final minutes = remainingTrialSeconds ~/ 60;
    final seconds = remainingTrialSeconds % 60;
    return '${minutes}m ${seconds}s';
  }

  bool get isTrialActive => hasAccess && !isPremium && remainingTrialSeconds > 0;
}
