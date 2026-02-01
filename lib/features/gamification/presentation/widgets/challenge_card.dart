/**
 * Challenge Card Widget
 * Points 196-199: Display challenge with progress and rewards
 */

import 'package:flutter/material.dart';
import '../../domain/entities/daily_challenge.dart';

class ChallengeCard extends StatelessWidget {
  final DailyChallenge challenge;
  final UserChallengeProgress? progress;
  final VoidCallback? onClaim;

  const ChallengeCard({
    Key? key,
    required this.challenge,
    this.progress,
    this.onClaim,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isCompleted = progress?.isCompleted ?? false;
    final canClaim = progress?.canClaim ?? false;
    final currentProgress = progress?.progress ?? 0;
    final progressPercentage = progress?.progressPercentage ?? 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isCompleted ? 4 : 2,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isCompleted
              ? LinearGradient(
                  colors: [
                    _getDifficultyColor(challenge.difficulty).withOpacity(0.2),
                    _getDifficultyColor(challenge.difficulty).withOpacity(0.05),
                  ],
                )
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Challenge icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getDifficultyColor(challenge.difficulty)
                        .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getChallengeIcon(challenge.type),
                    color: _getDifficultyColor(challenge.difficulty),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),

                // Challenge info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              challenge.name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color:
                                    isCompleted ? Colors.black : Colors.black87,
                              ),
                            ),
                          ),
                          if (isCompleted)
                            Icon(
                              Icons.check_circle,
                              color: _getDifficultyColor(challenge.difficulty),
                              size: 24,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        challenge.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Progress bar (Point 197)
            if (!isCompleted) ...[
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progressPercentage / 100,
                        minHeight: 8,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getDifficultyColor(challenge.difficulty),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '$currentProgress/${challenge.requiredCount}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _getDifficultyColor(challenge.difficulty),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],

            // Rewards section (Point 198)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: challenge.rewards.map((reward) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Colors.green.shade50
                        : Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isCompleted
                          ? Colors.green.shade200
                          : Colors.amber.shade200,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getRewardIcon(reward.type),
                        size: 16,
                        color: isCompleted
                            ? Colors.green.shade700
                            : Colors.amber.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+${reward.amount} ${reward.type}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isCompleted
                              ? Colors.green.shade700
                              : Colors.amber.shade700,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

            // Claim button
            if (canClaim && onClaim != null) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onClaim,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getDifficultyColor(challenge.difficulty),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Claim Rewards',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getChallengeIcon(ChallengeType type) {
    switch (type) {
      case ChallengeType.daily:
        return Icons.calendar_today;
      case ChallengeType.weekly:
        return Icons.event;
      case ChallengeType.monthly:
        return Icons.date_range;
      case ChallengeType.seasonal:
        return Icons.celebration;
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
      case 'boost':
        return Icons.rocket_launch;
      case 'super_like':
        return Icons.favorite;
      default:
        return Icons.card_giftcard;
    }
  }

  Color _getDifficultyColor(ChallengeDifficulty difficulty) {
    switch (difficulty) {
      case ChallengeDifficulty.easy:
        return Colors.green;
      case ChallengeDifficulty.medium:
        return Colors.orange;
      case ChallengeDifficulty.hard:
        return Colors.red;
      case ChallengeDifficulty.epic:
        return Colors.purple;
    }
  }
}
