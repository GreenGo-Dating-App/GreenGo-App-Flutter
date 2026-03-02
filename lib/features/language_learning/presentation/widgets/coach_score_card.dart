import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/services/ai_coach_service.dart';
import '../../domain/entities/ai_coach_session.dart';

/// End-of-session score summary card.
///
/// Displays:
/// - A-F grade per category (grammar, vocabulary, fluency)
/// - Overall grade with visual indicator
/// - Strengths and areas to improve
/// - XP earned
/// - "Practice Again" and "Done" buttons
class CoachScoreCard extends StatelessWidget {
  final CoachSessionScore score;
  final int xpEarned;
  final int messageCount;
  final VoidCallback onPracticeAgain;
  final VoidCallback onDone;

  const CoachScoreCard({
    super.key,
    required this.score,
    required this.xpEarned,
    required this.messageCount,
    required this.onPracticeAgain,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        _buildHeader(),
        const SizedBox(height: 20),

        // Overall grade circle
        _buildOverallGrade(),
        const SizedBox(height: 24),

        // Category scores
        _buildCategoryScores(),
        const SizedBox(height: 20),

        // Session stats
        _buildSessionStats(),
        const SizedBox(height: 20),

        // Strengths
        if (score.strengths.isNotEmpty) ...[
          _buildListSection(
            title: 'Strengths',
            icon: Icons.thumb_up_outlined,
            iconColor: AppColors.successGreen,
            items: score.strengths,
          ),
          const SizedBox(height: 16),
        ],

        // Areas to improve
        if (score.areasToImprove.isNotEmpty) ...[
          _buildListSection(
            title: 'Areas to Improve',
            icon: Icons.trending_up,
            iconColor: AppColors.warningAmber,
            items: score.areasToImprove,
          ),
          const SizedBox(height: 24),
        ],

        // Action buttons
        _buildActionButtons(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        const Icon(
          Icons.emoji_events,
          color: AppColors.richGold,
          size: 48,
        ),
        const SizedBox(height: 12),
        const Text(
          'Session Complete!',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          AiCoachService.gradeDescription(score.grade),
          style: TextStyle(
            color: _gradeColor(score.grade),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildOverallGrade() {
    final grade = score.grade;
    final color = _gradeColor(grade);

    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 4),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            grade,
            style: TextStyle(
              color: color,
              fontSize: 48,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${score.overallScore.round()}%',
            style: TextStyle(
              color: color.withValues(alpha: 0.8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryScores() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.divider.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildCategoryItem(
              label: 'Grammar',
              score: score.grammarAccuracy,
              icon: Icons.spellcheck,
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: AppColors.divider.withValues(alpha: 0.3),
          ),
          Expanded(
            child: _buildCategoryItem(
              label: 'Vocabulary',
              score: score.vocabularyUsage,
              icon: Icons.menu_book,
            ),
          ),
          Container(
            width: 1,
            height: 50,
            color: AppColors.divider.withValues(alpha: 0.3),
          ),
          Expanded(
            child: _buildCategoryItem(
              label: 'Fluency',
              score: score.fluency,
              icon: Icons.record_voice_over,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem({
    required String label,
    required double score,
    required IconData icon,
  }) {
    final grade = AiCoachService.scoreToGrade(score);
    final color = _gradeColor(grade);

    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(
          grade,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 11,
          ),
        ),
        Text(
          '${score.round()}%',
          style: TextStyle(
            color: AppColors.textTertiary.withValues(alpha: 0.6),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildSessionStats() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.richGold.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.richGold.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.chat_bubble_outline,
            value: '$messageCount',
            label: 'Messages',
          ),
          Container(
            width: 1,
            height: 32,
            color: AppColors.richGold.withValues(alpha: 0.2),
          ),
          _buildStatItem(
            icon: Icons.star,
            value: '+$xpEarned XP',
            label: 'Earned',
            valueColor: AppColors.richGold,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    Color? valueColor,
  }) {
    return Column(
      children: [
        Icon(icon, color: valueColor ?? AppColors.textTertiary, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textTertiary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildListSection({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<String> items,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.divider.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: iconColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: AppColors.textTertiary.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: onPracticeAgain,
            icon: const Icon(Icons.replay, size: 18),
            label: const Text('Practice Again'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.richGold,
              side: const BorderSide(color: AppColors.richGold),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onDone,
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Done'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.richGold,
              foregroundColor: AppColors.deepBlack,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _gradeColor(String grade) {
    switch (grade) {
      case 'A':
        return AppColors.successGreen;
      case 'B':
        return AppColors.infoBlue;
      case 'C':
        return AppColors.richGold;
      case 'D':
        return AppColors.warningAmber;
      case 'F':
        return AppColors.errorRed;
      default:
        return AppColors.textTertiary;
    }
  }
}
