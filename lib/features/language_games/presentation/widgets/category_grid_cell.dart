import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// A single cell in the 3x3 categories grid.
class CategoryGridCell extends StatelessWidget {
  final String category;
  final String? filledWord;
  final bool isActive;
  final VoidCallback onTap;

  const CategoryGridCell({
    super.key,
    required this.category,
    this.filledWord,
    this.isActive = false,
    required this.onTap,
  });

  bool get isFilled => filledWord != null;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isFilled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
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
                    color: AppColors.successGreen.withValues(alpha: 0.15),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              category,
              style: TextStyle(
                color: isFilled
                    ? AppColors.successGreen
                    : AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (isFilled) ...[
              const SizedBox(height: 4),
              const Icon(Icons.check_circle,
                  color: AppColors.successGreen, size: 16),
              const SizedBox(height: 2),
              Text(
                filledWord!,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ] else
              const SizedBox(height: 4),
              if (!isFilled)
                const Icon(Icons.edit_outlined,
                    color: AppColors.textTertiary, size: 14),
          ],
        ),
      ),
    );
  }
}
