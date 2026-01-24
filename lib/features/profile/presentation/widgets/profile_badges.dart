import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../membership/domain/entities/membership.dart';
import '../../../gamification/domain/entities/achievement.dart';
import '../../../gamification/domain/entities/user_level.dart';

/// Profile Badges Widget
/// Displays user's tier badge, level, and top achievements
class ProfileBadgesWidget extends StatelessWidget {
  final MembershipTier tier;
  final int level;
  final int xp;
  final int xpToNextLevel;
  final List<UserAchievement>? achievements;
  final bool isVerified;
  final VoidCallback? onViewAllAchievements;

  const ProfileBadgesWidget({
    super.key,
    required this.tier,
    required this.level,
    required this.xp,
    required this.xpToNextLevel,
    this.achievements,
    this.isVerified = false,
    this.onViewAllAchievements,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.paddingM),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main badges row (Tier + Level + Verified)
          Row(
            children: [
              // Tier badge
              _TierBadge(tier: tier),
              const SizedBox(width: 12),
              // Level badge
              _LevelBadge(
                level: level,
                xp: xp,
                xpToNextLevel: xpToNextLevel,
              ),
              const SizedBox(width: 12),
              // Verified badge
              if (isVerified) _VerifiedBadge(),
              const Spacer(),
            ],
          ),
          const SizedBox(height: AppDimensions.paddingM),

          // XP Progress bar
          _XPProgressBar(xp: xp, xpToNextLevel: xpToNextLevel),

          // Achievement showcase
          if (achievements != null && achievements!.isNotEmpty) ...[
            const SizedBox(height: AppDimensions.paddingM),
            const Divider(color: AppColors.divider),
            const SizedBox(height: AppDimensions.paddingS),
            _AchievementShowcase(
              achievements: achievements!,
              onViewAll: onViewAllAchievements,
            ),
          ],
        ],
      ),
    );
  }
}

/// Tier Badge Widget
class _TierBadge extends StatelessWidget {
  final MembershipTier tier;

  const _TierBadge({required this.tier});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: _getTierGradient(),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        boxShadow: [
          BoxShadow(
            color: _getTierColor().withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_getTierIcon(), color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Text(
            tier.displayName,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  LinearGradient _getTierGradient() {
    switch (tier) {
      case MembershipTier.free:
        return LinearGradient(
          colors: [Colors.grey.shade600, Colors.grey.shade800],
        );
      case MembershipTier.silver:
        return LinearGradient(
          colors: [Colors.grey.shade400, Colors.grey.shade600],
        );
      case MembershipTier.gold:
        return const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
        );
      case MembershipTier.platinum:
        return LinearGradient(
          colors: [Colors.purple.shade400, Colors.blue.shade600],
        );
      case MembershipTier.test:
        return LinearGradient(
          colors: [Colors.green.shade400, Colors.teal.shade600],
        );
    }
  }

  Color _getTierColor() {
    switch (tier) {
      case MembershipTier.free:
        return Colors.grey;
      case MembershipTier.silver:
        return Colors.grey.shade400;
      case MembershipTier.gold:
        return const Color(0xFFFFD700);
      case MembershipTier.platinum:
        return Colors.purple;
      case MembershipTier.test:
        return Colors.green;
    }
  }

  IconData _getTierIcon() {
    switch (tier) {
      case MembershipTier.free:
        return Icons.person;
      case MembershipTier.silver:
        return Icons.star_border;
      case MembershipTier.gold:
        return Icons.star;
      case MembershipTier.platinum:
        return Icons.diamond;
      case MembershipTier.test:
        return Icons.bug_report;
    }
  }
}

/// Level Badge Widget
class _LevelBadge extends StatelessWidget {
  final int level;
  final int xp;
  final int xpToNextLevel;

  const _LevelBadge({
    required this.level,
    required this.xp,
    required this.xpToNextLevel,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showLevelDetails(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade600, Colors.purple.shade900],
          ),
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shield, color: Colors.white, size: 18),
            const SizedBox(width: 6),
            Text(
              'Lvl $level',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLevelDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppDimensions.paddingL),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingL),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade400, Colors.purple.shade800],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '$level',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.paddingM),
            Text(
              'Level $level',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _getLevelTitle(level),
              style: TextStyle(
                color: Colors.purple.shade300,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingL),
            // XP Progress
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Colors.purple, size: 20),
                const SizedBox(width: 4),
                Text(
                  '$xp / $xpToNextLevel XP',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppDimensions.paddingS),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: xp / xpToNextLevel,
                backgroundColor: AppColors.divider,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.purple.shade400),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingM),
            Text(
              '${xpToNextLevel - xp} XP to Level ${level + 1}',
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: AppDimensions.paddingL),
          ],
        ),
      ),
    );
  }

  String _getLevelTitle(int level) {
    if (level < 5) return 'Newcomer';
    if (level < 10) return 'Rising Star';
    if (level < 20) return 'Social Explorer';
    if (level < 30) return 'Connection Master';
    if (level < 50) return 'Dating Pro';
    return 'Legend';
  }
}

/// Verified Badge Widget
class _VerifiedBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade500, Colors.blue.shade700],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, color: Colors.white, size: 18),
          SizedBox(width: 4),
          Text(
            'Verified',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// XP Progress Bar Widget
class _XPProgressBar extends StatelessWidget {
  final int xp;
  final int xpToNextLevel;

  const _XPProgressBar({
    required this.xp,
    required this.xpToNextLevel,
  });

  @override
  Widget build(BuildContext context) {
    final progress = xp / xpToNextLevel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.star, color: Colors.purple, size: 16),
                const SizedBox(width: 4),
                Text(
                  '$xp XP',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            Text(
              '${(progress * 100).toInt()}%',
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            FractionallySizedBox(
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple.shade400, Colors.purple.shade700],
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Achievement Showcase Widget
class _AchievementShowcase extends StatelessWidget {
  final List<UserAchievement> achievements;
  final VoidCallback? onViewAll;

  const _AchievementShowcase({
    required this.achievements,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    // Show only completed achievements, max 5
    final completedAchievements = achievements
        .where((a) => a.isCompleted)
        .take(5)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Achievements',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (onViewAll != null)
              GestureDetector(
                onTap: onViewAll,
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: AppColors.richGold,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppDimensions.paddingS),
        if (completedAchievements.isEmpty)
          const Text(
            'No achievements yet. Start engaging to earn badges!',
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 12,
            ),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: completedAchievements.map((userAchievement) {
              final achievement = Achievements.getById(userAchievement.achievementId);
              if (achievement == null) return const SizedBox.shrink();
              return _AchievementBadge(achievement: achievement);
            }).toList(),
          ),
      ],
    );
  }
}

/// Single Achievement Badge
class _AchievementBadge extends StatelessWidget {
  final Achievement achievement;

  const _AchievementBadge({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final rarityColor = Color(achievement.rarity.colorValue);

    return Tooltip(
      message: achievement.name,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: rarityColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(AppDimensions.radiusS),
          border: Border.all(color: rarityColor, width: 2),
        ),
        child: Icon(
          Icons.emoji_events,
          color: rarityColor,
          size: 24,
        ),
      ),
    );
  }
}

/// Compact Profile Badge (for display in other places like discovery cards)
class CompactProfileBadge extends StatelessWidget {
  final MembershipTier tier;
  final bool isVerified;
  final int? level;

  const CompactProfileBadge({
    super.key,
    required this.tier,
    this.isVerified = false,
    this.level,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Tier indicator
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            gradient: _getTierGradient(),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_getTierIcon(), color: Colors.white, size: 12),
              if (tier != MembershipTier.free) ...[
                const SizedBox(width: 4),
                Text(
                  tier.displayName.split(' ').first,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (isVerified) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(Icons.verified, color: Colors.white, size: 12),
          ),
        ],
        if (level != null) ...[
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.purple,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '$level',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ],
    );
  }

  LinearGradient _getTierGradient() {
    switch (tier) {
      case MembershipTier.free:
        return LinearGradient(
          colors: [Colors.grey.shade600, Colors.grey.shade800],
        );
      case MembershipTier.silver:
        return LinearGradient(
          colors: [Colors.grey.shade400, Colors.grey.shade600],
        );
      case MembershipTier.gold:
        return const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
        );
      case MembershipTier.platinum:
        return LinearGradient(
          colors: [Colors.purple.shade400, Colors.blue.shade600],
        );
      case MembershipTier.test:
        return LinearGradient(
          colors: [Colors.green.shade400, Colors.teal.shade600],
        );
    }
  }

  IconData _getTierIcon() {
    switch (tier) {
      case MembershipTier.free:
        return Icons.person;
      case MembershipTier.silver:
        return Icons.star_border;
      case MembershipTier.gold:
        return Icons.star;
      case MembershipTier.platinum:
        return Icons.diamond;
      case MembershipTier.test:
        return Icons.bug_report;
    }
  }
}

/// Login Streak Badge Widget
class StreakBadge extends StatelessWidget {
  final int currentStreak;
  final bool isActive;

  const StreakBadge({
    super.key,
    required this.currentStreak,
    this.isActive = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive
              ? [Colors.orange.shade400, Colors.red.shade400]
              : [Colors.grey.shade600, Colors.grey.shade800],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusS),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department,
            color: Colors.white,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '$currentStreak',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
