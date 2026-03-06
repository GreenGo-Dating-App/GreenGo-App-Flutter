import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// Word bubble for Vocabulary Chain game
class ChainBubble extends StatelessWidget {
  final String word;
  final bool isLatest;
  final bool showConnector;
  final String? playerName;

  const ChainBubble({
    super.key,
    required this.word,
    this.isLatest = false,
    this.showConnector = true,
    this.playerName,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Connector line
        if (showConnector)
          Container(
            width: 2,
            height: 16,
            color: AppColors.divider,
          ),

        // Word bubble
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isLatest
                ? AppColors.richGold.withValues(alpha: 0.15)
                : AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isLatest ? AppColors.richGold : AppColors.divider,
              width: isLatest ? 2 : 1,
            ),
            boxShadow: isLatest
                ? [
                    BoxShadow(
                      color: AppColors.richGold.withValues(alpha: 0.2),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Word text
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Highlight last letter
                  if (word.isNotEmpty) ...[
                    Text(
                      word.substring(0, word.length - 1),
                      style: TextStyle(
                        color: isLatest
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontSize: 16,
                        fontWeight:
                            isLatest ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    Text(
                      word[word.length - 1],
                      style: TextStyle(
                        color: AppColors.richGold,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.richGold,
                      ),
                    ),
                  ],
                ],
              ),

              // Player name
              if (playerName != null) ...[
                const SizedBox(height: 2),
                Text(
                  playerName!,
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
