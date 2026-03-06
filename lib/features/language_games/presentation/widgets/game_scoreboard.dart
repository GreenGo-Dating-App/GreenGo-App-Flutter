import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/game_player.dart';
import 'player_avatar_circle.dart';

/// Live scoreboard widget showing all players' scores, lives, and turn indicator
/// Displays player avatars in a horizontal row with scores and hearts
class GameScoreboard extends StatelessWidget {
  final List<GamePlayer> players;
  final Map<String, int> scores;
  final Map<String, int> lives;
  final String? currentTurnUserId;
  final String? currentUserId;

  const GameScoreboard({
    super.key,
    required this.players,
    required this.scores,
    this.lives = const {},
    this.currentTurnUserId,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: players.map((player) {
          final score = scores[player.userId] ?? 0;
          final playerLives = lives[player.userId] ?? player.lives;
          final isCurrentTurn = player.userId == currentTurnUserId;
          final isMe = player.userId == currentUserId;

          return _PlayerScoreColumn(
            player: player.copyWith(
              score: score,
              lives: playerLives,
            ),
            isCurrentTurn: isCurrentTurn,
            isCurrentUser: isMe,
            showLives: lives.isNotEmpty,
          );
        }).toList(),
      ),
    );
  }
}

class _PlayerScoreColumn extends StatelessWidget {
  final GamePlayer player;
  final bool isCurrentTurn;
  final bool isCurrentUser;
  final bool showLives;

  const _PlayerScoreColumn({
    required this.player,
    required this.isCurrentTurn,
    required this.isCurrentUser,
    required this.showLives,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isCurrentTurn
            ? AppColors.richGold.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isCurrentTurn
            ? Border.all(color: AppColors.richGold.withValues(alpha: 0.4))
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Player avatar
          PlayerAvatarCircle(
            player: player,
            isCurrentTurn: isCurrentTurn,
            isCurrentUser: isCurrentUser,
            showLives: showLives,
            showScore: true,
            size: 40,
          ),

          // Turn indicator arrow
          if (isCurrentTurn) ...[
            const SizedBox(height: 2),
            const Icon(
              Icons.arrow_drop_up_rounded,
              color: AppColors.richGold,
              size: 16,
            ),
          ],
        ],
      ),
    );
  }
}
