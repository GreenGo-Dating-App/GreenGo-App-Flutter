import 'package:flutter/material.dart';
import '../../domain/entities/lesson.dart';

class LessonCard extends StatelessWidget {
  final Lesson lesson;
  final bool isPurchased;
  final VoidCallback? onTap;
  final VoidCallback? onPurchase;

  const LessonCard({
    super.key,
    required this.lesson,
    this.isPurchased = false,
    this.onTap,
    this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    final isLocked = !lesson.isFree && !isPurchased;

    return GestureDetector(
      onTap: isLocked ? onPurchase : onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isLocked
                ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                : [const Color(0xFF1A1A2E), const Color(0xFF2D2D44)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isLocked
                ? Colors.white.withOpacity(0.1)
                : const Color(0xFFD4AF37).withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with lesson number and lock status
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Day ${lesson.dayNumber}',
                    style: const TextStyle(
                      color: Color(0xFFD4AF37),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  lesson.category.emoji,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    lesson.category.displayName,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isLocked)
                  const Icon(
                    Icons.lock,
                    color: Colors.white54,
                    size: 18,
                  )
                else if (lesson.isFree)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'FREE',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFFD4AF37),
                    size: 18,
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Lesson title
            Text(
              lesson.title,
              style: TextStyle(
                color: isLocked ? Colors.white70 : Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),

            // Lesson description
            Text(
              lesson.description,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 13,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),

            // Bottom row with level, duration, and price/XP
            Row(
              children: [
                // Level badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getLevelColor(lesson.level).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        lesson.level.emoji,
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        lesson.level.displayName,
                        style: TextStyle(
                          color: _getLevelColor(lesson.level),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Duration
                Icon(
                  Icons.timer_outlined,
                  color: Colors.white.withOpacity(0.5),
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '${lesson.estimatedMinutes}m',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
                const Spacer(),

                // Price or XP reward
                if (isLocked) ...[
                  const Icon(
                    Icons.monetization_on,
                    color: Color(0xFFD4AF37),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${lesson.coinPrice}',
                    style: const TextStyle(
                      color: Color(0xFFD4AF37),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ] else ...[
                  const Icon(
                    Icons.star,
                    color: Color(0xFFD4AF37),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '+${lesson.xpReward} XP',
                    style: const TextStyle(
                      color: Color(0xFFD4AF37),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getLevelColor(LessonLevel level) {
    switch (level) {
      case LessonLevel.absolute_beginner:
        return Colors.lightGreen;
      case LessonLevel.beginner:
        return Colors.green;
      case LessonLevel.elementary:
        return Colors.teal;
      case LessonLevel.pre_intermediate:
        return Colors.cyan;
      case LessonLevel.intermediate:
        return Colors.blue;
      case LessonLevel.upper_intermediate:
        return Colors.indigo;
      case LessonLevel.advanced:
        return Colors.purple;
      case LessonLevel.fluent:
        return const Color(0xFFD4AF37);
    }
  }
}
