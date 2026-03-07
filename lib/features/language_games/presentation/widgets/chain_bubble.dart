import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// Player colors for chain bubble tinting
const _playerColors = [
  AppColors.richGold,
  AppColors.infoBlue,
  Color(0xFFE040FB), // purple
  Color(0xFF00E676), // green
  Color(0xFFFF5252), // red
  Color(0xFF40C4FF), // light blue
];

/// Word bubble for Vocabulary Chain game
class ChainBubble extends StatelessWidget {
  final String word;
  final bool isLatest;
  final bool showConnector;
  final String? playerName;
  final int playerIndex;
  final bool animateIn;

  const ChainBubble({
    super.key,
    required this.word,
    this.isLatest = false,
    this.showConnector = true,
    this.playerName,
    this.playerIndex = 0,
    this.animateIn = false,
  });

  Color get _playerColor =>
      _playerColors[playerIndex % _playerColors.length];

  @override
  Widget build(BuildContext context) {
    final bubble = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Connector line
        if (showConnector)
          Container(
            width: 2,
            height: 16,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.divider.withValues(alpha: 0.3),
                  _playerColor.withValues(alpha: 0.4),
                ],
              ),
            ),
          ),

        // Word bubble
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isLatest
                ? _playerColor.withValues(alpha: 0.12)
                : AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isLatest
                  ? _playerColor.withValues(alpha: 0.6)
                  : AppColors.divider,
              width: isLatest ? 2 : 1,
            ),
            boxShadow: isLatest
                ? [
                    BoxShadow(
                      color: _playerColor.withValues(alpha: 0.2),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Mini player color dot
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _playerColor,
                ),
              ),
              const SizedBox(width: 8),

              // Word text with last letter highlighted
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

              // Player name tag
              if (playerName != null) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _playerColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    playerName!,
                    style: TextStyle(
                      color: _playerColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );

    if (!animateIn) return bubble;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - value)),
            child: Transform.scale(
              scale: 0.8 + 0.2 * value,
              child: child,
            ),
          ),
        );
      },
      child: bubble,
    );
  }
}
