import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../coins/presentation/bloc/coin_bloc.dart';
import '../../../coins/presentation/bloc/coin_event.dart';
import '../../domain/entities/lesson.dart';
import '../widgets/learning_path_node.dart';

/// Bottom sheet shown when tapping a star node in the Galaxy Map.
/// Shows lesson info, coin cost, and a "Start Lesson" or "Unlock" button.
class StarSystemInfoSheet extends StatelessWidget {
  final Lesson? lesson;
  final PathNodeType nodeType;
  final PathNodeStatus nodeStatus;
  final String title;
  final int xpReward;
  final bool isPurchased;
  final int coinCost;
  final int starCount;
  final VoidCallback onStartLesson;

  const StarSystemInfoSheet({
    super.key,
    this.lesson,
    required this.nodeType,
    required this.nodeStatus,
    required this.title,
    required this.xpReward,
    required this.isPurchased,
    this.coinCost = 0,
    this.starCount = 0,
    required this.onStartLesson,
  });

  static void show(
    BuildContext context, {
    Lesson? lesson,
    required PathNodeType nodeType,
    required PathNodeStatus nodeStatus,
    required String title,
    required int xpReward,
    required bool isPurchased,
    int coinCost = 0,
    int starCount = 0,
    required VoidCallback onStartLesson,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => StarSystemInfoSheet(
        lesson: lesson,
        nodeType: nodeType,
        nodeStatus: nodeStatus,
        title: title,
        xpReward: xpReward,
        isPurchased: isPurchased,
        coinCost: coinCost,
        starCount: starCount,
        onStartLesson: onStartLesson,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Node type icon
          _buildTypeIcon(),
          const SizedBox(height: 12),

          // Title
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),

          // Description
          if (lesson != null)
            Text(
              lesson!.description,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 16),

          // Star rating for completed lessons
          if (nodeStatus == PathNodeStatus.completed && starCount > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) {
                return Icon(
                  i < starCount ? Icons.star : Icons.star_border,
                  size: 28,
                  color: i < starCount
                      ? AppColors.richGold
                      : Colors.grey.withValues(alpha: 0.4),
                );
              }),
            ),
            const SizedBox(height: 12),
          ],

          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatChip(
                icon: Icons.star,
                label: '+$xpReward XP',
                color: AppColors.richGold,
              ),
              const SizedBox(width: 16),
              if (lesson != null)
                _buildStatChip(
                  icon: Icons.timer,
                  label: '${lesson!.estimatedMinutes} min',
                  color: Colors.blue,
                ),
              if (coinCost > 0) ...[
                const SizedBox(width: 16),
                _buildStatChip(
                  icon: Icons.monetization_on,
                  label: '$coinCost coins',
                  color: AppColors.richGold,
                ),
              ],
              if (lesson != null && lesson!.bonusCoins > 0 && coinCost == 0) ...[
                const SizedBox(width: 16),
                _buildStatChip(
                  icon: Icons.monetization_on,
                  label: '+${lesson!.bonusCoins}',
                  color: AppColors.richGold,
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),

          // Progress indicator for in-progress
          if (nodeStatus == PathNodeStatus.inProgress) ...[
            LinearProgressIndicator(
              value: 0.5,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor:
                  const AlwaysStoppedAnimation(AppColors.richGold),
              minHeight: 4,
            ),
            const SizedBox(height: 16),
          ],

          // Action button
          SizedBox(
            width: double.infinity,
            child: _buildActionButton(context),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildTypeIcon() {
    IconData icon;
    Color color;
    switch (nodeType) {
      case PathNodeType.lesson:
        icon = Icons.menu_book;
        color = AppColors.richGold;
      case PathNodeType.quiz:
        icon = Icons.quiz;
        color = Colors.purple;
      case PathNodeType.flashcard:
        icon = Icons.style;
        color = Colors.blue;
      case PathNodeType.aiCoach:
        icon = Icons.smart_toy;
        color = Colors.teal;
    }

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.15),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Icon(icon, color: color, size: 28),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    if (nodeStatus == PathNodeStatus.completed) {
      return ElevatedButton.icon(
        onPressed: () {
          Navigator.pop(context);
          onStartLesson();
        },
        icon: const Icon(Icons.replay, size: 18),
        label: const Text('Review'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.withOpacity(0.3),
          foregroundColor: Colors.green,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }

    if (lesson != null && lesson!.isLocked && !isPurchased) {
      return ElevatedButton.icon(
        onPressed: () => _unlockLesson(context),
        icon: const Icon(Icons.lock_open, size: 18),
        label: Text('Unlock for ${lesson!.coinPrice} coins'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.richGold,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }

    // Label based on node type
    String buttonLabel;
    switch (nodeType) {
      case PathNodeType.lesson:
        buttonLabel = 'Start Lesson';
      case PathNodeType.quiz:
        buttonLabel = 'Start Quiz';
      case PathNodeType.flashcard:
        buttonLabel = 'Start Flashcards';
      case PathNodeType.aiCoach:
        buttonLabel = 'Open AI Coach';
    }

    return ElevatedButton.icon(
      onPressed: () {
        Navigator.pop(context);
        onStartLesson();
      },
      icon: const Icon(Icons.play_arrow, size: 20),
      label: Text(
        buttonLabel,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.richGold,
        foregroundColor: Colors.black,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _unlockLesson(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null || lesson == null) return;

    context.read<CoinBloc>().add(PurchaseFeatureWithCoins(
          userId: userId,
          featureName: 'lesson_unlock',
          cost: lesson!.coinPrice,
          relatedId: lesson!.id,
        ));
    Navigator.pop(context);
  }
}
