import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Enhancement #5: Common Interests Chips
/// Displays shared interests between two users
class CommonInterestsChips extends StatelessWidget {
  final List<String> interests;
  final int maxDisplay;
  final bool isHighlighted;

  const CommonInterestsChips({
    super.key,
    required this.interests,
    this.maxDisplay = 3,
    this.isHighlighted = true,
  });

  @override
  Widget build(BuildContext context) {
    if (interests.isEmpty) return const SizedBox.shrink();

    final displayInterests = interests.take(maxDisplay).toList();
    final remaining = interests.length - maxDisplay;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        ...displayInterests.map((interest) => _InterestChip(
              interest: interest,
              isHighlighted: isHighlighted,
            )),
        if (remaining > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.backgroundInput,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '+$remaining',
              style: const TextStyle(
                color: AppColors.textTertiary,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}

class _InterestChip extends StatelessWidget {
  final String interest;
  final bool isHighlighted;

  const _InterestChip({
    required this.interest,
    required this.isHighlighted,
  });

  IconData _getIcon() {
    final lower = interest.toLowerCase();
    if (lower.contains('music')) return Icons.music_note;
    if (lower.contains('travel')) return Icons.flight;
    if (lower.contains('food') || lower.contains('cook')) return Icons.restaurant;
    if (lower.contains('sport') || lower.contains('fitness')) return Icons.fitness_center;
    if (lower.contains('read') || lower.contains('book')) return Icons.book;
    if (lower.contains('movie') || lower.contains('film')) return Icons.movie;
    if (lower.contains('art') || lower.contains('paint')) return Icons.palette;
    if (lower.contains('photo')) return Icons.camera_alt;
    if (lower.contains('game') || lower.contains('gaming')) return Icons.sports_esports;
    if (lower.contains('nature') || lower.contains('hiking')) return Icons.nature;
    if (lower.contains('yoga') || lower.contains('meditat')) return Icons.self_improvement;
    if (lower.contains('dance')) return Icons.nightlife;
    if (lower.contains('pet') || lower.contains('dog') || lower.contains('cat')) return Icons.pets;
    return Icons.favorite;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isHighlighted
            ? AppColors.richGold.withOpacity(0.2)
            : AppColors.backgroundInput,
        borderRadius: BorderRadius.circular(14),
        border: isHighlighted
            ? Border.all(color: AppColors.richGold.withOpacity(0.5))
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getIcon(),
            size: 14,
            color: isHighlighted ? AppColors.richGold : AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            interest,
            style: TextStyle(
              color: isHighlighted ? AppColors.richGold : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: isHighlighted ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
