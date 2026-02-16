import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// Swipe Action Buttons
///
/// Displays pass/skip/super like/like buttons below the card
class SwipeButtons extends StatelessWidget {
  final VoidCallback? onRewind;
  final VoidCallback? onPass;
  final VoidCallback? onSkip;
  final VoidCallback? onSuperLike;
  final VoidCallback? onLike;
  final bool enabled;

  const SwipeButtons({
    super.key,
    this.onRewind,
    this.onPass,
    this.onSkip,
    this.onSuperLike,
    this.onLike,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Rewind button
        _buildActionButton(
          icon: Icons.replay,
          color: AppColors.warningAmber,
          size: 44,
          iconSize: 22,
          onPressed: enabled ? onRewind : null,
        ),

        // Pass button
        _buildActionButton(
          icon: Icons.close,
          color: AppColors.errorRed,
          size: 60,
          iconSize: 32,
          onPressed: enabled ? onPass : null,
        ),

        // Skip button
        _buildActionButton(
          icon: Icons.arrow_downward,
          color: AppColors.infoBlue,
          size: 50,
          iconSize: 28,
          onPressed: enabled ? onSkip : null,
        ),

        // Super Like button
        _buildActionButton(
          icon: Icons.star,
          color: AppColors.richGold,
          size: 50,
          iconSize: 28,
          onPressed: enabled ? onSuperLike : null,
        ),

        // Like button
        _buildActionButton(
          icon: Icons.favorite,
          color: AppColors.successGreen,
          size: 60,
          iconSize: 32,
          onPressed: enabled ? onLike : null,
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required double size,
    required double iconSize,
    VoidCallback? onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: onPressed != null
                ? AppColors.backgroundCard
                : AppColors.backgroundCard.withOpacity(0.5),
            border: Border.all(
              color: onPressed != null ? color : color.withOpacity(0.5),
              width: 2,
            ),
            boxShadow: onPressed != null
                ? [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Icon(
            icon,
            color: onPressed != null ? color : color.withOpacity(0.5),
            size: iconSize,
          ),
        ),
      ),
    );
  }
}
