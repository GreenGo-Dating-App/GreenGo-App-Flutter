import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/game_player.dart';

/// Circular avatar widget with ready indicator, lives, and score
class PlayerAvatarCircle extends StatelessWidget {
  final GamePlayer player;
  final bool isCurrentTurn;
  final bool isCurrentUser;
  final bool showLives;
  final bool showScore;
  final double size;

  const PlayerAvatarCircle({
    super.key,
    required this.player,
    this.isCurrentTurn = false,
    this.isCurrentUser = false,
    this.showLives = false,
    this.showScore = false,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar with glow for current turn
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isCurrentTurn
                  ? AppColors.richGold
                  : (player.isReady ? AppColors.successGreen : AppColors.divider),
              width: isCurrentTurn ? 3 : 2,
            ),
            boxShadow: isCurrentTurn
                ? [
                    BoxShadow(
                      color: AppColors.richGold.withValues(alpha: 0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: CircleAvatar(
            radius: size / 2,
            backgroundColor: AppColors.backgroundInput,
            backgroundImage: player.photoUrl != null
                ? CachedNetworkImageProvider(player.photoUrl!)
                : null,
            child: player.photoUrl == null
                ? Text(
                    player.displayName.isNotEmpty
                        ? player.displayName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: size / 2.5,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
        ),

        const SizedBox(height: 4),

        // Player name
        SizedBox(
          width: size + 20,
          child: Text(
            isCurrentUser ? 'You' : player.displayName,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isCurrentUser ? AppColors.richGold : AppColors.textSecondary,
              fontSize: 11,
              fontWeight: isCurrentUser ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),

        // Lives display
        if (showLives && player.lives > 0) ...[
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              player.lives,
              (index) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 1),
                child: Icon(
                  Icons.favorite,
                  color: AppColors.errorRed,
                  size: 12,
                ),
              ),
            ),
          ),
        ],

        // Score display
        if (showScore) ...[
          const SizedBox(height: 2),
          Text(
            '${player.score} pts',
            style: const TextStyle(
              color: AppColors.richGold,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],

        // Ready indicator (for lobby)
        if (player.isReady) ...[
          const SizedBox(height: 2),
          const Text(
            'READY',
            style: TextStyle(
              color: AppColors.successGreen,
              fontSize: 9,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ],
    );
  }
}
