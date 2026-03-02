import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/safety_module.dart';
import '../../domain/entities/safety_progress.dart';

/// Card widget representing a safety module on the academy home screen.
///
/// Displays the module icon, title, description, lesson progress,
/// XP reward, and completion status.
class SafetyModuleCard extends StatelessWidget {
  final SafetyModule module;
  final SafetyProgress? progress;
  final VoidCallback onTap;

  const SafetyModuleCard({
    super.key,
    required this.module,
    required this.progress,
    required this.onTap,
  });

  bool get _isCompleted =>
      progress?.isModuleCompleted(module.id) ?? false;

  int get _completedLessons =>
      progress?.completedLessonsInModule(module.lessons) ?? 0;

  int get _totalLessons => module.lessons.length;

  double get _progressFraction =>
      _totalLessons == 0 ? 0.0 : _completedLessons / _totalLessons;

  /// Map icon name strings to Flutter IconData
  IconData get _icon {
    switch (module.iconName) {
      case 'shield':
        return Icons.shield;
      case 'location_on':
        return Icons.location_on;
      case 'chat_bubble':
        return Icons.chat_bubble;
      case 'public':
        return Icons.public;
      case 'psychology':
        return Icons.psychology;
      case 'favorite':
        return Icons.favorite;
      case 'security':
        return Icons.security;
      case 'handshake':
        return Icons.handshake;
      default:
        return Icons.school;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(12),
          border: _isCompleted
              ? Border.all(
                  color: AppColors.successGreen.withValues(alpha: 0.4),
                  width: 1.5,
                )
              : null,
        ),
        child: Row(
          children: [
            // Module icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: _isCompleted
                    ? AppColors.successGreen.withValues(alpha: 0.15)
                    : AppColors.richGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _icon,
                color: _isCompleted
                    ? AppColors.successGreen
                    : AppColors.richGold,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),

            // Module details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          module.title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_isCompleted)
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.successGreen,
                          size: 20,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Description
                  Text(
                    module.description,
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Progress bar + stats
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: _progressFraction,
                            backgroundColor: AppColors.backgroundInput,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _isCompleted
                                  ? AppColors.successGreen
                                  : AppColors.richGold,
                            ),
                            minHeight: 4,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '$_completedLessons/$_totalLessons',
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.star,
                        color: AppColors.richGold,
                        size: 14,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${module.xpReward} XP',
                        style: const TextStyle(
                          color: AppColors.richGold,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textTertiary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
