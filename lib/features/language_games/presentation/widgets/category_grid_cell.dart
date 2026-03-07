import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// A single cell in the 3x3 categories grid.
/// Shows category icon + name when empty, filled word + checkmark when complete.
/// Includes fill animation (scale bounce) and staggered entrance.
class CategoryGridCell extends StatelessWidget {
  final String category;
  final String categoryIcon;
  final String? filledWord;
  final bool isActive;
  final int index;
  final VoidCallback onTap;

  const CategoryGridCell({
    super.key,
    required this.category,
    this.categoryIcon = '',
    this.filledWord,
    this.isActive = false,
    this.index = 0,
    required this.onTap,
  });

  bool get isFilled => filledWord != null;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isFilled ? null : onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(milliseconds: 400 + index * 60),
        curve: Curves.elasticOut,
        builder: (context, scale, child) {
          return Transform.scale(scale: scale, child: child);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: isFilled
                ? AppColors.successGreen.withValues(alpha: 0.15)
                : isActive
                    ? AppColors.richGold.withValues(alpha: 0.1)
                    : AppColors.backgroundCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isFilled
                  ? AppColors.successGreen.withValues(alpha: 0.5)
                  : isActive
                      ? AppColors.richGold
                      : AppColors.divider,
              width: isActive ? 2 : 1,
            ),
            boxShadow: isFilled
                ? [
                    BoxShadow(
                      color: AppColors.successGreen.withValues(alpha: 0.2),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ]
                : isActive
                    ? [
                        BoxShadow(
                          color: AppColors.richGold.withValues(alpha: 0.15),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
          ),
          padding: const EdgeInsets.all(6),
          child: isFilled ? _buildFilledContent() : _buildEmptyContent(),
        ),
      ),
    );
  }

  Widget _buildEmptyContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (categoryIcon.isNotEmpty)
          Text(
            categoryIcon,
            style: const TextStyle(fontSize: 22),
          ),
        const SizedBox(height: 2),
        Text(
          category,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Icon(
          isActive ? Icons.edit : Icons.touch_app_outlined,
          color: isActive ? AppColors.richGold : AppColors.textTertiary,
          size: 13,
        ),
      ],
    );
  }

  Widget _buildFilledContent() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle,
              color: AppColors.successGreen, size: 20),
          const SizedBox(height: 2),
          Text(
            category,
            style: const TextStyle(
              color: AppColors.successGreen,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            filledWord!,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
