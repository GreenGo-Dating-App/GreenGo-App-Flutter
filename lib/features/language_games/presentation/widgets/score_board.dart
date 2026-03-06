import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/game_player.dart';

/// Live updating scoreboard widget
class ScoreBoard extends StatelessWidget {
  final List<GamePlayer> players;
  final Map<String, int> scores;
  final String? currentUserId;
  final bool compact;

  const ScoreBoard({
    super.key,
    required this.players,
    required this.scores,
    this.currentUserId,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    // Sort players by score descending
    final sortedPlayers = List<GamePlayer>.from(players)
      ..sort((a, b) => (scores[b.userId] ?? 0).compareTo(scores[a.userId] ?? 0));

    if (compact) {
      return _buildCompact(sortedPlayers);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SCOREBOARD',
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          ...sortedPlayers.asMap().entries.map((entry) {
            final index = entry.key;
            final player = entry.value;
            final score = scores[player.userId] ?? 0;
            final isCurrentUser = player.userId == currentUserId;

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  // Rank
                  SizedBox(
                    width: 20,
                    child: Text(
                      '${index + 1}.',
                      style: TextStyle(
                        color: index == 0
                            ? AppColors.richGold
                            : AppColors.textTertiary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Name
                  Expanded(
                    child: Text(
                      isCurrentUser ? 'You' : player.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isCurrentUser
                            ? AppColors.richGold
                            : AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight:
                            isCurrentUser ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                  // Score
                  Text(
                    '$score',
                    style: TextStyle(
                      color: index == 0
                          ? AppColors.richGold
                          : AppColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCompact(List<GamePlayer> sortedPlayers) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: sortedPlayers.map((player) {
        final score = scores[player.userId] ?? 0;
        final isCurrentUser = player.userId == currentUserId;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isCurrentUser ? 'You' : player.displayName,
                style: TextStyle(
                  color: isCurrentUser
                      ? AppColors.richGold
                      : AppColors.textTertiary,
                  fontSize: 10,
                ),
              ),
              Text(
                '$score',
                style: TextStyle(
                  color: isCurrentUser
                      ? AppColors.richGold
                      : AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
