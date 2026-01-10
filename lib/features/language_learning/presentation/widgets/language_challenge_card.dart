import 'package:flutter/material.dart';
import '../../domain/entities/language_challenge.dart';

class LanguageChallengeCard extends StatelessWidget {
  final LanguageChallenge challenge;
  final VoidCallback? onClaim;

  const LanguageChallengeCard({
    super.key,
    required this.challenge,
    this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final progress = challenge.progressPercentage;
    final isCompleted = challenge.isCompleted;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompleted
              ? Colors.green.withOpacity(0.5)
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          // Challenge Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _getDifficultyColor(challenge.difficulty).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                challenge.type.icon,
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Challenge Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        challenge.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getDifficultyColor(challenge.difficulty)
                            .withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        challenge.difficulty.displayName,
                        style: TextStyle(
                          color: _getDifficultyColor(challenge.difficulty),
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  challenge.description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),

                // Progress Bar
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          backgroundColor: Colors.white.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation(
                            isCompleted
                                ? Colors.green
                                : const Color(0xFFD4AF37),
                          ),
                          minHeight: 6,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${challenge.currentProgress}/${challenge.targetCount}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Rewards
                Row(
                  children: [
                    const Icon(
                      Icons.star,
                      color: Colors.purple,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '+${challenge.xpReward} XP',
                      style: const TextStyle(
                        color: Colors.purple,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.monetization_on,
                      color: Color(0xFFD4AF37),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '+${challenge.coinReward}',
                      style: const TextStyle(
                        color: Color(0xFFD4AF37),
                        fontSize: 12,
                      ),
                    ),
                    if (challenge.badgeReward != null) ...[
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.military_tech,
                        color: Colors.amber,
                        size: 14,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Claim Button or Checkmark
          if (isCompleted && !challenge.isRewardClaimed)
            ElevatedButton(
              onPressed: onClaim,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Claim',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          else if (isCompleted)
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 28,
            ),
        ],
      ),
    );
  }

  Color _getDifficultyColor(ChallengeDifficulty difficulty) {
    switch (difficulty) {
      case ChallengeDifficulty.easy:
        return Colors.green;
      case ChallengeDifficulty.medium:
        return Colors.amber;
      case ChallengeDifficulty.hard:
        return Colors.orange;
      case ChallengeDifficulty.epic:
        return Colors.purple;
    }
  }
}
