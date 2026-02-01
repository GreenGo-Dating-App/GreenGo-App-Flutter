import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Enhancement #12: Streak Display Widget
/// Shows current login streak count
class StreakDisplay extends StatelessWidget {
  final int streakDays;
  final bool isCompact;
  final VoidCallback? onTap;

  const StreakDisplay({
    super.key,
    required this.streakDays,
    this.isCompact = false,
    this.onTap,
  });

  Color _getStreakColor() {
    if (streakDays >= 30) return AppColors.richGold;
    if (streakDays >= 14) return AppColors.warningAmber;
    if (streakDays >= 7) return AppColors.infoBlue;
    return AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _getStreakColor().withOpacity(0.2),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _getStreakColor().withOpacity(0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔥', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(
                '$streakDays',
                style: TextStyle(
                  color: _getStreakColor(),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _getStreakColor().withOpacity(0.2),
              _getStreakColor().withOpacity(0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getStreakColor().withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: _getStreakColor().withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text('🔥', style: TextStyle(fontSize: 24)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$streakDays Day Streak!',
                    style: TextStyle(
                      color: _getStreakColor(),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getStreakMessage(),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: _getStreakColor(),
            ),
          ],
        ),
      ),
    );
  }

  String _getStreakMessage() {
    if (streakDays >= 30) return 'Incredible dedication! 🏆';
    if (streakDays >= 14) return 'Two weeks strong! 💪';
    if (streakDays >= 7) return 'One week milestone! 🎯';
    if (streakDays >= 3) return 'Building momentum! 🚀';
    return 'Keep it up! ✨';
  }
}

/// Mini streak badge for profile/header
class StreakBadge extends StatelessWidget {
  final int streakDays;

  const StreakBadge({
    super.key,
    required this.streakDays,
  });

  @override
  Widget build(BuildContext context) {
    if (streakDays < 2) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 10)),
          const SizedBox(width: 2),
          Text(
            '$streakDays',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
