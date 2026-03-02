import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/ai_coach_session.dart';

/// A bottom sheet widget displaying the 8 coach scenarios.
///
/// Each scenario shows its name, description, difficulty level, and icon.
/// Tapping a scenario calls [onScenarioSelected] and starts the session.
class ScenarioSelector extends StatelessWidget {
  final void Function(CoachScenario scenario) onScenarioSelected;

  const ScenarioSelector({
    super.key,
    required this.onScenarioSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(
                  Icons.school,
                  color: AppColors.richGold,
                  size: 24,
                ),
                SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose a Scenario',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Pick a conversation topic to practice',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Cost indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.richGold.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.richGold.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.monetization_on,
                    color: AppColors.richGold.withValues(alpha: 0.8),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    '10 coins per session',
                    style: TextStyle(
                      color: AppColors.richGold,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.star,
                    color: AppColors.richGold.withValues(alpha: 0.8),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '25 XP reward',
                    style: TextStyle(
                      color: AppColors.richGold,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Scenarios grid
          Flexible(
            child: GridView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.35,
              ),
              itemCount: CoachScenario.values.length,
              itemBuilder: (context, index) {
                final scenario = CoachScenario.values[index];
                return _buildScenarioCard(context, scenario);
              },
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildScenarioCard(BuildContext context, CoachScenario scenario) {
    final difficulty = _getDifficulty(scenario);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onScenarioSelected(scenario);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  scenario.icon,
                  style: const TextStyle(fontSize: 26),
                ),
                _buildDifficultyBadge(difficulty),
              ],
            ),
            const Spacer(),
            Text(
              scenario.displayName,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              scenario.description,
              style: TextStyle(
                color: AppColors.textTertiary.withValues(alpha: 0.7),
                fontSize: 11,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyBadge(_ScenarioDifficulty difficulty) {
    Color color;
    String label;

    switch (difficulty) {
      case _ScenarioDifficulty.beginner:
        color = AppColors.successGreen;
        label = 'Easy';
      case _ScenarioDifficulty.intermediate:
        color = AppColors.warningAmber;
        label = 'Medium';
      case _ScenarioDifficulty.advanced:
        color = AppColors.errorRed;
        label = 'Hard';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  _ScenarioDifficulty _getDifficulty(CoachScenario scenario) {
    switch (scenario) {
      case CoachScenario.casualChat:
      case CoachScenario.gettingToKnow:
        return _ScenarioDifficulty.beginner;
      case CoachScenario.firstDate:
      case CoachScenario.complimenting:
      case CoachScenario.discussingInterests:
        return _ScenarioDifficulty.intermediate;
      case CoachScenario.videoCallPrep:
      case CoachScenario.askingOut:
      case CoachScenario.travelPlanning:
        return _ScenarioDifficulty.advanced;
    }
  }
}

enum _ScenarioDifficulty {
  beginner,
  intermediate,
  advanced,
}
