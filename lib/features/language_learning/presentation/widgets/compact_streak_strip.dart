import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/entities/learning_streak.dart';

/// Thin horizontal strip displaying the user's current learning streak.
/// Shows a fire icon (with animated glow when streak > 0), streak count,
/// and today's completion status.
class CompactStreakStrip extends StatelessWidget {
  final LearningStreak? streak;

  const CompactStreakStrip({super.key, this.streak});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentStreak = streak?.currentStreak ?? 0;
    final practicedToday = streak?.isPracticedToday ?? false;
    final isActive = currentStreak > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive
              ? AppColors.richGold.withValues(alpha: 0.4)
              : AppColors.divider,
        ),
      ),
      child: Row(
        children: [
          // Fire icon with glow when streak > 0
          _FireIcon(isActive: isActive),
          const SizedBox(width: 8),

          // Streak count text
          Text(
            l10n?.dayStreakCount(currentStreak.toString()) ??
                '$currentStreak day streak',
            style: TextStyle(
              color: isActive ? AppColors.textPrimary : AppColors.textTertiary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),

          const Spacer(),

          // Today's status
          if (practicedToday)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: AppColors.successGreen, size: 18),
                const SizedBox(width: 4),
                Text(
                  l10n?.streakActiveToday ?? 'Active today',
                  style: const TextStyle(
                    color: AppColors.successGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            )
          else
            Text(
              isActive
                  ? (l10n?.streakActiveToday ?? 'Active today')
                  : (l10n?.streakInactive ?? 'Start your streak!'),
              style: TextStyle(
                color: isActive ? AppColors.textSecondary : AppColors.textTertiary,
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }
}

/// Fire icon with an animated orange glow when the streak is active.
class _FireIcon extends StatelessWidget {
  final bool isActive;

  const _FireIcon({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: isActive
          ? BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.orange.withValues(alpha: 0.5),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            )
          : null,
      child: Icon(
        Icons.local_fire_department,
        color: isActive ? Colors.orange : AppColors.textTertiary,
        size: 22,
      ),
    );
  }
}
