import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/community.dart';

/// Community Type Filter Chip
///
/// A selectable chip for filtering communities by type
class CommunityTypeChip extends StatelessWidget {
  final CommunityType? type;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const CommunityTypeChip({
    super.key,
    this.type,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.richGold.withValues(alpha: 0.15)
              : AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.richGold : AppColors.divider,
            width: isSelected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (type != null) ...[
              Icon(
                _getTypeIcon(type!),
                size: 14,
                color: isSelected ? AppColors.richGold : AppColors.textTertiary,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.richGold : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTypeIcon(CommunityType type) {
    switch (type) {
      case CommunityType.languageCircle:
        return Icons.translate;
      case CommunityType.culturalInterest:
        return Icons.public;
      case CommunityType.travelGroup:
        return Icons.flight;
      case CommunityType.localGuides:
        return Icons.location_on;
      case CommunityType.studyGroup:
        return Icons.menu_book;
      case CommunityType.general:
        return Icons.chat_bubble_outline;
    }
  }
}
