import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/badge.dart';

/// Widget for displaying badges on profile
class BadgeDisplayWidget extends StatelessWidget {
  final List<Badge> badges;
  final double badgeSize;
  final bool showTooltip;
  final bool isCompact;
  final VoidCallback? onTap;

  const BadgeDisplayWidget({
    super.key,
    required this.badges,
    this.badgeSize = 32,
    this.showTooltip = true,
    this.isCompact = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...badges.take(3).map((badge) => Padding(
                padding: EdgeInsets.only(right: isCompact ? 4 : 8),
                child: _BadgeIcon(
                  badge: badge,
                  size: badgeSize,
                  showTooltip: showTooltip,
                ),
              )),
          if (badges.length > 3)
            Container(
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.divider),
              ),
              child: Center(
                child: Text(
                  '+${badges.length - 3}',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: badgeSize * 0.35,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Single badge icon
class _BadgeIcon extends StatelessWidget {
  final Badge badge;
  final double size;
  final bool showTooltip;

  const _BadgeIcon({
    required this.badge,
    required this.size,
    this.showTooltip = true,
  });

  @override
  Widget build(BuildContext context) {
    final icon = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Color(badge.rarity.colorValue).withValues(alpha: 0.2),
        border: Border.all(
          color: Color(badge.rarity.colorValue),
          width: 2,
        ),
        boxShadow: badge.rarity == BadgeRarity.legendary ||
                badge.rarity == BadgeRarity.mythic
            ? [
                BoxShadow(
                  color: Color(badge.rarity.colorValue).withValues(alpha: 0.5),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Center(
        child: _getBadgeIcon(badge, size * 0.55),
      ),
    );

    if (!showTooltip) return icon;

    return Tooltip(
      message: '${badge.name}\n${badge.description}',
      child: icon,
    );
  }

  Widget _getBadgeIcon(Badge badge, double iconSize) {
    // Map badge IDs to icons
    IconData iconData;
    switch (badge.badgeId) {
      case 'verified_user':
        iconData = Icons.verified;
        break;
      case 'premium_member':
        iconData = Icons.workspace_premium;
        break;
      case 'vip_crown':
        iconData = Icons.emoji_events;
        break;
      case 'social_butterfly_badge':
        iconData = Icons.groups;
        break;
      case 'heartbreaker_badge':
        iconData = Icons.favorite;
        break;
      case 'globe_trotter_badge':
        iconData = Icons.public;
        break;
      case 'video_star_badge':
        iconData = Icons.videocam;
        break;
      case 'super_star_badge':
        iconData = Icons.star;
        break;
      case 'centurion_badge':
        iconData = Icons.military_tech;
        break;
      case 'millennium_badge':
        iconData = Icons.diamond;
        break;
      case 'perfect_week_badge':
        iconData = Icons.calendar_today;
        break;
      case 'streak_master_badge':
        iconData = Icons.local_fire_department;
        break;
      case 'early_bird_badge':
        iconData = Icons.egg;
        break;
      case 'cupid_badge':
        iconData = Icons.favorite_border;
        break;
      case 'summer_love_badge':
        iconData = Icons.wb_sunny;
        break;
      case 'santa_badge':
        iconData = Icons.card_giftcard;
        break;
      case 'referral_champion_badge':
        iconData = Icons.share;
        break;
      case 'language_master_badge':
        iconData = Icons.translate;
        break;
      case 'leaderboard_champion_badge':
        iconData = Icons.leaderboard;
        break;
      // Frame badges
      case 'bronze_frame':
      case 'silver_frame':
      case 'gold_frame':
      case 'platinum_frame':
      case 'diamond_frame':
      case 'legendary_frame':
        iconData = Icons.crop_free;
        break;
      default:
        iconData = Icons.military_tech;
    }

    return Icon(
      iconData,
      size: iconSize,
      color: Color(badge.rarity.colorValue),
    );
  }
}

/// Profile badge row for profile header
class ProfileBadgeRow extends StatelessWidget {
  final List<Badge> displayedBadges;
  final bool isVerified;
  final bool isPremium;
  final bool isVIP;
  final int level;
  final VoidCallback? onBadgeTap;

  const ProfileBadgeRow({
    super.key,
    required this.displayedBadges,
    this.isVerified = false,
    this.isPremium = false,
    this.isVIP = false,
    this.level = 1,
    this.onBadgeTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Level badge
        _LevelBadge(level: level),
        const SizedBox(width: 8),

        // Verified badge
        if (isVerified)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Tooltip(
              message: 'Verified User',
              child: Icon(
                Icons.verified,
                size: 20,
                color: Colors.blue,
              ),
            ),
          ),

        // VIP badge
        if (isVIP)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Tooltip(
              message: 'VIP Member',
              child: Icon(
                Icons.emoji_events,
                size: 20,
                color: AppColors.richGold,
              ),
            ),
          ),

        // Premium badge
        if (isPremium && !isVIP)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Tooltip(
              message: 'Premium Member',
              child: Icon(
                Icons.workspace_premium,
                size: 20,
                color: AppColors.richGold,
              ),
            ),
          ),

        // Custom badges
        if (displayedBadges.isNotEmpty)
          BadgeDisplayWidget(
            badges: displayedBadges,
            badgeSize: 24,
            isCompact: true,
            onTap: onBadgeTap,
          ),
      ],
    );
  }
}

/// Level badge
class _LevelBadge extends StatelessWidget {
  final int level;

  const _LevelBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getLevelColors(),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.stars,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            'Lv.$level',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _getLevelColors() {
    if (level >= 100) {
      return [Colors.purple, Colors.pink, Colors.orange]; // Legendary
    } else if (level >= 75) {
      return [Colors.cyan, Colors.blue]; // Diamond
    } else if (level >= 50) {
      return [Colors.amber, Colors.orange]; // Gold/VIP
    } else if (level >= 25) {
      return [Colors.grey.shade400, Colors.grey.shade600]; // Silver
    } else if (level >= 10) {
      return [Colors.brown.shade300, Colors.brown.shade500]; // Bronze
    } else {
      return [Colors.green, Colors.teal]; // Beginner
    }
  }
}

/// Badge grid for badge selection/viewing
class BadgeGrid extends StatelessWidget {
  final List<Badge> badges;
  final Set<String> selectedBadgeIds;
  final ValueChanged<String>? onBadgeSelected;
  final int maxSelections;

  const BadgeGrid({
    super.key,
    required this.badges,
    this.selectedBadgeIds = const {},
    this.onBadgeSelected,
    this.maxSelections = 3,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 0.85,
      ),
      itemCount: badges.length,
      itemBuilder: (context, index) {
        final badge = badges[index];
        final isSelected = selectedBadgeIds.contains(badge.badgeId);
        final canSelect = selectedBadgeIds.length < maxSelections || isSelected;

        return GestureDetector(
          onTap: canSelect && onBadgeSelected != null
              ? () => onBadgeSelected!(badge.badgeId)
              : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.richGold.withValues(alpha: 0.2)
                  : AppColors.backgroundCard,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? AppColors.richGold : AppColors.divider,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _BadgeIcon(
                  badge: badge,
                  size: 28,
                  showTooltip: false,
                ),
                const SizedBox(height: 2),
                Text(
                  badge.name,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 8,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  badge.rarity.displayName,
                  style: TextStyle(
                    color: Color(badge.rarity.colorValue),
                    fontSize: 7,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Badge showcase dialog
class BadgeShowcaseDialog extends StatelessWidget {
  final Badge badge;
  final bool isEarned;
  final DateTime? earnedAt;

  const BadgeShowcaseDialog({
    super.key,
    required this.badge,
    this.isEarned = false,
    this.earnedAt,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.backgroundCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Badge icon (large)
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Color(badge.rarity.colorValue).withValues(alpha: 0.2),
                border: Border.all(
                  color: Color(badge.rarity.colorValue),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(badge.rarity.colorValue).withValues(alpha: 0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                _getBadgeIconData(badge.badgeId),
                size: 50,
                color: Color(badge.rarity.colorValue),
              ),
            ),
            const SizedBox(height: 20),

            // Badge name
            Text(
              badge.name,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // Rarity
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Color(badge.rarity.colorValue).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badge.rarity.displayName,
                style: TextStyle(
                  color: Color(badge.rarity.colorValue),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Description
            Text(
              badge.description,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Category
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.category,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
                const SizedBox(width: 4),
                Text(
                  badge.category.displayName,
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),

            // Earned date
            if (isEarned && earnedAt != null) ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 16,
                    color: AppColors.successGreen,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Earned on ${_formatDate(earnedAt!)}',
                    style: const TextStyle(
                      color: AppColors.successGreen,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),

            // Close button
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getBadgeIconData(String badgeId) {
    switch (badgeId) {
      case 'verified_user':
        return Icons.verified;
      case 'premium_member':
        return Icons.workspace_premium;
      case 'vip_crown':
        return Icons.emoji_events;
      default:
        return Icons.military_tech;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
