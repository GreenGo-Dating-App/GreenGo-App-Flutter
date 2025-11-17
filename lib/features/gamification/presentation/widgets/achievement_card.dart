/**
 * Achievement Card Widget
 * Points 176-185: Display individual achievement with progress
 */

import 'package:flutter/material.dart';
import '../../domain/entities/achievement.dart';

class AchievementCard extends StatelessWidget {
  final Achievement achievement;
  final UserAchievementProgress? progress;
  final VoidCallback? onTap;

  const AchievementCard({
    Key? key,
    required this.achievement,
    this.progress,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isUnlocked = progress?.isUnlocked ?? false;
    final currentProgress = progress?.progress ?? 0;
    final progressPercentage = progress?.progressPercentage ?? 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isUnlocked ? 4 : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: isUnlocked
                ? LinearGradient(
                    colors: [
                      _getRarityColor(achievement.rarity).withOpacity(0.2),
                      _getRarityColor(achievement.rarity).withOpacity(0.05),
                    ],
                  )
                : null,
          ),
          child: Row(
            children: [
              // Achievement Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isUnlocked
                      ? _getRarityColor(achievement.rarity)
                      : Colors.grey.shade300,
                  boxShadow: isUnlocked
                      ? [
                          BoxShadow(
                            color: _getRarityColor(achievement.rarity)
                                .withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  _getCategoryIcon(achievement.category),
                  color: isUnlocked ? Colors.white : Colors.grey.shade600,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),

              // Achievement Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            achievement.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isUnlocked ? Colors.black : Colors.grey,
                            ),
                          ),
                        ),
                        if (isUnlocked)
                          Icon(
                            Icons.check_circle,
                            color: _getRarityColor(achievement.rarity),
                            size: 20,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      achievement.description,
                      style: TextStyle(
                        fontSize: 13,
                        color: isUnlocked
                            ? Colors.grey.shade700
                            : Colors.grey.shade500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Progress Bar
                    if (!isUnlocked) ...[
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progressPercentage / 100,
                                minHeight: 6,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _getRarityColor(achievement.rarity),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$currentProgress/${achievement.requiredCount}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // Reward Display
                      Row(
                        children: [
                          Icon(
                            _getRewardIcon(achievement.rewardType),
                            size: 16,
                            color: _getRarityColor(achievement.rarity),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '+${achievement.rewardAmount} ${achievement.rewardType}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _getRarityColor(achievement.rarity),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.social:
        return Icons.people;
      case AchievementCategory.engagement:
        return Icons.favorite;
      case AchievementCategory.premium:
        return Icons.diamond;
      case AchievementCategory.milestones:
        return Icons.flag;
      case AchievementCategory.special:
        return Icons.star;
    }
  }

  IconData _getRewardIcon(String rewardType) {
    switch (rewardType) {
      case 'xp':
        return Icons.trending_up;
      case 'coins':
        return Icons.monetization_on;
      case 'badge':
        return Icons.military_tech;
      default:
        return Icons.card_giftcard;
    }
  }

  Color _getRarityColor(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return Colors.grey;
      case AchievementRarity.uncommon:
        return Colors.green;
      case AchievementRarity.rare:
        return Colors.blue;
      case AchievementRarity.epic:
        return Colors.purple;
      case AchievementRarity.legendary:
        return Colors.amber;
    }
  }
}
