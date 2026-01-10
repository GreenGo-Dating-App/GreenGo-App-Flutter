import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/usage_limit_service.dart';
import '../../features/membership/domain/entities/membership.dart';
import '../../features/coins/presentation/screens/shop_screen.dart';

/// Dialog action types
enum LimitDialogAction {
  upgrade,
  buyCoins,
  dismiss,
}

/// Result from the limit reached dialog
class LimitDialogResult {
  final LimitDialogAction action;
  final MembershipTier? selectedTier;

  const LimitDialogResult({
    required this.action,
    this.selectedTier,
  });
}

/// Displays a stylish dialog when a user reaches their usage limit
/// Provides options to upgrade membership or buy coins
class LimitReachedDialog extends StatelessWidget {
  final UsageLimitResult limitResult;
  final String userId;
  final VoidCallback? onUpgrade;
  final VoidCallback? onBuyCoins;

  const LimitReachedDialog({
    super.key,
    required this.limitResult,
    required this.userId,
    this.onUpgrade,
    this.onBuyCoins,
  });

  /// Static helper to show the dialog
  static Future<LimitDialogResult?> show({
    required BuildContext context,
    required UsageLimitResult limitResult,
    required String userId,
    VoidCallback? onUpgrade,
    VoidCallback? onBuyCoins,
  }) {
    return showDialog<LimitDialogResult>(
      context: context,
      barrierDismissible: true,
      builder: (context) => LimitReachedDialog(
        limitResult: limitResult,
        userId: userId,
        onUpgrade: onUpgrade,
        onBuyCoins: onBuyCoins,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.richGold.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with icon
            _buildHeader(),
            // Content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Message
                  Text(
                    limitResult.message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Usage stats
                  _buildUsageStats(),
                  const SizedBox(height: 24),
                  // Tier comparison if upgrade is available
                  if (limitResult.suggestedTier != null) ...[
                    _buildTierComparison(),
                    const SizedBox(height: 24),
                  ],
                  // Action buttons
                  _buildActionButtons(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Limit Reached',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _getLimitTypeTitle(),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _getLimitTypeTitle() {
    if (limitResult.limit == 0) {
      return 'Feature not available on ${limitResult.currentTier.displayName}';
    }
    return 'Daily limit of ${limitResult.limit} reached';
  }

  Widget _buildUsageStats() {
    if (limitResult.isUnlimited || limitResult.limit == 0) {
      return const SizedBox.shrink();
    }

    final progress = limitResult.currentUsage / limitResult.limit;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundInput,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Used today',
                style: TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 12,
                ),
              ),
              Text(
                '${limitResult.currentUsage} / ${limitResult.limit}',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: AppColors.divider,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.errorRed),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierComparison() {
    final suggestedTier = limitResult.suggestedTier!;
    final suggestedRules = MembershipRules.getDefaultsForTier(suggestedTier);
    final currentRules = MembershipRules.getDefaultsForTier(limitResult.currentTier);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.richGold.withValues(alpha: 0.1),
            AppColors.richGold.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.richGold.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(
                Icons.star,
                color: AppColors.richGold,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Upgrade to ${suggestedTier.displayName}',
                style: const TextStyle(
                  color: AppColors.richGold,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildComparisonRow(
            'Daily Swipes',
            _formatLimit(currentRules.dailySwipeLimit),
            _formatLimit(suggestedRules.dailySwipeLimit),
          ),
          _buildComparisonRow(
            'Daily Messages',
            _formatLimit(currentRules.dailyMessageLimit),
            _formatLimit(suggestedRules.dailyMessageLimit),
          ),
          _buildComparisonRow(
            'Super Likes',
            _formatLimit(currentRules.dailySuperLikeLimit),
            _formatLimit(suggestedRules.dailySuperLikeLimit),
          ),
          if (suggestedRules.canSendMedia && !currentRules.canSendMedia)
            _buildComparisonRow(
              'Send Media',
              'No',
              'Yes',
            ),
          if (suggestedRules.canSeeWhoLiked && !currentRules.canSeeWhoLiked)
            _buildComparisonRow(
              'See Who Liked',
              'No',
              'Yes',
            ),
        ],
      ),
    );
  }

  String _formatLimit(int limit) {
    return limit == -1 ? 'Unlimited' : limit.toString();
  }

  Widget _buildComparisonRow(String label, String current, String upgraded) {
    final isImprovement = current != upgraded;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              current,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isImprovement ? AppColors.textTertiary : AppColors.textSecondary,
                fontSize: 13,
                decoration: isImprovement ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          const Icon(
            Icons.arrow_forward,
            color: AppColors.textTertiary,
            size: 14,
          ),
          Expanded(
            child: Text(
              upgraded,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isImprovement ? AppColors.successGreen : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: isImprovement ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        // Primary action - Upgrade
        if (limitResult.suggestedTier != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.richGold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(
                  context,
                  LimitDialogResult(
                    action: LimitDialogAction.upgrade,
                    selectedTier: limitResult.suggestedTier,
                  ),
                );
                onUpgrade?.call();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Upgrade to ${limitResult.suggestedTier!.displayName}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        // Secondary action - Buy Coins
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.richGold,
              side: const BorderSide(color: AppColors.richGold),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(
                context,
                const LimitDialogResult(action: LimitDialogAction.buyCoins),
              );
              // Navigate to shop
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ShopScreen(userId: userId),
                ),
              );
              onBuyCoins?.call();
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.monetization_on, size: 20),
                SizedBox(width: 8),
                Text(
                  'Buy Coins',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Dismiss
        TextButton(
          onPressed: () {
            Navigator.pop(
              context,
              const LimitDialogResult(action: LimitDialogAction.dismiss),
            );
          },
          child: const Text(
            'Maybe Later',
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}

/// A simpler snackbar-style notification for limit warnings
class LimitWarningSnackBar {
  static void show({
    required BuildContext context,
    required int remaining,
    required String limitType,
    VoidCallback? onUpgrade,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.backgroundCard,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        duration: const Duration(seconds: 4),
        content: Row(
          children: [
            Icon(
              remaining <= 3 ? Icons.warning_amber_rounded : Icons.info_outline,
              color: remaining <= 3 ? AppColors.warningAmber : AppColors.richGold,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '$remaining $limitType remaining today',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        action: onUpgrade != null
            ? SnackBarAction(
                label: 'Upgrade',
                textColor: AppColors.richGold,
                onPressed: onUpgrade,
              )
            : null,
      ),
    );
  }
}

/// Feature not available dialog for features that require higher tier
class FeatureNotAvailableDialog extends StatelessWidget {
  final String featureName;
  final String description;
  final MembershipTier currentTier;
  final MembershipTier requiredTier;
  final String userId;
  final IconData? icon;

  const FeatureNotAvailableDialog({
    super.key,
    required this.featureName,
    required this.description,
    required this.currentTier,
    required this.requiredTier,
    required this.userId,
    this.icon,
  });

  static Future<LimitDialogResult?> show({
    required BuildContext context,
    required String featureName,
    required String description,
    required MembershipTier currentTier,
    required MembershipTier requiredTier,
    required String userId,
    IconData? icon,
  }) {
    return showDialog<LimitDialogResult>(
      context: context,
      barrierDismissible: true,
      builder: (context) => FeatureNotAvailableDialog(
        featureName: featureName,
        description: description,
        currentTier: currentTier,
        requiredTier: requiredTier,
        userId: userId,
        icon: icon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 360),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Lock icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.richGold.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon ?? Icons.lock_outline,
                  color: AppColors.richGold,
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              // Feature name
              Text(
                featureName,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              // Description
              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              // Required tier badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.richGold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.richGold.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star,
                      color: AppColors.richGold,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Requires ${requiredTier.displayName}',
                      style: const TextStyle(
                        color: AppColors.richGold,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Upgrade button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.richGold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(
                      context,
                      LimitDialogResult(
                        action: LimitDialogAction.upgrade,
                        selectedTier: requiredTier,
                      ),
                    );
                  },
                  child: Text(
                    'Upgrade to ${requiredTier.displayName}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Dismiss
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    const LimitDialogResult(action: LimitDialogAction.dismiss),
                  );
                },
                child: const Text(
                  'Not Now',
                  style: TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
