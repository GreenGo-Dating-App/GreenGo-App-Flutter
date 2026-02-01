import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Enhancement #17: Sort Matches Dropdown
/// Allows sorting matches by different criteria
enum MatchSortOption {
  recent,
  oldest,
  nameAz,
  nameZa,
  nearestFirst,
  highestMatch,
}

extension MatchSortOptionExtension on MatchSortOption {
  String get label {
    switch (this) {
      case MatchSortOption.recent:
        return 'Most Recent';
      case MatchSortOption.oldest:
        return 'Oldest First';
      case MatchSortOption.nameAz:
        return 'Name (A-Z)';
      case MatchSortOption.nameZa:
        return 'Name (Z-A)';
      case MatchSortOption.nearestFirst:
        return 'Nearest First';
      case MatchSortOption.highestMatch:
        return 'Highest Match %';
    }
  }

  IconData get icon {
    switch (this) {
      case MatchSortOption.recent:
        return Icons.access_time;
      case MatchSortOption.oldest:
        return Icons.history;
      case MatchSortOption.nameAz:
        return Icons.sort_by_alpha;
      case MatchSortOption.nameZa:
        return Icons.sort_by_alpha;
      case MatchSortOption.nearestFirst:
        return Icons.near_me;
      case MatchSortOption.highestMatch:
        return Icons.favorite;
    }
  }
}

class SortDropdown extends StatelessWidget {
  final MatchSortOption selectedOption;
  final Function(MatchSortOption) onChanged;

  const SortDropdown({
    super.key,
    required this.selectedOption,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<MatchSortOption>(
      initialValue: selectedOption,
      onSelected: onChanged,
      offset: const Offset(0, 40),
      color: AppColors.backgroundCard,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.divider),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.backgroundInput,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.sort,
              size: 18,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              selectedOption.label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.arrow_drop_down,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => MatchSortOption.values
          .map((option) => PopupMenuItem<MatchSortOption>(
                value: option,
                child: Row(
                  children: [
                    Icon(
                      option.icon,
                      size: 18,
                      color: option == selectedOption
                          ? AppColors.richGold
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      option.label,
                      style: TextStyle(
                        color: option == selectedOption
                            ? AppColors.richGold
                            : AppColors.textPrimary,
                        fontWeight: option == selectedOption
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    if (option == selectedOption) ...[
                      const Spacer(),
                      const Icon(
                        Icons.check,
                        size: 18,
                        color: AppColors.richGold,
                      ),
                    ],
                  ],
                ),
              ))
          .toList(),
    );
  }
}
