import 'package:flutter/material.dart';
import '../../domain/entities/learning_streak.dart';

class LearningStreakCard extends StatelessWidget {
  final LearningStreak streak;

  const LearningStreakCard({
    super.key,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    final nextMilestone = streak.nextMilestone;
    final progress = streak.progressToNextMilestone;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange.withOpacity(0.2),
            Colors.red.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.orange.withOpacity(0.5),
        ),
      ),
      child: Column(
        children: [
          // Header Row
          Row(
            children: [
              // Fire icon with streak count
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      color: Colors.orange,
                      size: 32,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${streak.currentStreak}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Day Streak',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      streak.isPracticedToday
                          ? 'Keep it up!'
                          : 'Practice today to extend your streak!',
                      style: TextStyle(
                        color: streak.isPracticedToday
                            ? Colors.green
                            : Colors.orange,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Today's status
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: streak.isPracticedToday
                      ? Colors.green.withOpacity(0.2)
                      : Colors.orange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      streak.isPracticedToday
                          ? Icons.check_circle
                          : Icons.schedule,
                      color: streak.isPracticedToday
                          ? Colors.green
                          : Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      streak.isPracticedToday ? 'Done' : 'Today',
                      style: TextStyle(
                        color: streak.isPracticedToday
                            ? Colors.green
                            : Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Next Milestone Progress
          if (nextMilestone != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.emoji_events,
                        color: Color(0xFFD4AF37),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Next: ${nextMilestone.name}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        '${streak.currentStreak}/${nextMilestone.requiredDays} days',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor:
                          const AlwaysStoppedAnimation(Color(0xFFD4AF37)),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.monetization_on,
                        color: Color(0xFFD4AF37),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+${nextMilestone.coinReward} coins',
                        style: const TextStyle(
                          color: Color(0xFFD4AF37),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.star,
                        color: Colors.purple,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '+${nextMilestone.xpReward} XP',
                        style: const TextStyle(
                          color: Colors.purple,
                          fontSize: 12,
                        ),
                      ),
                      if (nextMilestone.badgeName != null) ...[
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.military_tech,
                          color: Colors.amber,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Badge',
                          style: TextStyle(
                            color: Colors.amber,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],

          // Stats Row
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                'Longest',
                '${streak.longestStreak}',
                Icons.trending_up,
              ),
              _buildStatItem(
                'Total Days',
                '${streak.totalPracticeDays}',
                Icons.calendar_today,
              ),
              _buildStatItem(
                'Milestones',
                '${streak.achievedMilestones.length}',
                Icons.emoji_events,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white.withOpacity(0.5),
          size: 18,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
