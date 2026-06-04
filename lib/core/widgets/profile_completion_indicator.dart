import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Enhancement #6: Profile Completion Indicator
/// Shows profile completion percentage with visual progress
class ProfileCompletionIndicator extends StatelessWidget {

  const ProfileCompletionIndicator({
    required this.completion, super.key,
    this.showPercentage = true,
    this.showLabel = true,
    this.height = 8,
  });
  final double completion;
  final bool showPercentage;
  final bool showLabel;
  final double height;

  Color _getColor() {
    if (completion >= 100) return AppColors.successGreen;
    if (completion >= 70) return AppColors.richGold;
    if (completion >= 40) return AppColors.warningAmber;
    return AppColors.errorRed;
  }

  String _getMessage() {
    if (completion >= 100) return 'Complete!';
    if (completion >= 70) return 'Almost there!';
    if (completion >= 40) return 'Keep going!';
    return 'Just started';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showLabel)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Profile Completion',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      _getMessage(),
                      style: TextStyle(
                        color: _getColor(),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (showPercentage) ...[
                      const SizedBox(width: 8),
                      Text(
                        '${completion.toInt()}%',
                        style: TextStyle(
                          color: _getColor(),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: LinearProgressIndicator(
            value: completion / 100,
            minHeight: height,
            backgroundColor: AppColors.backgroundInput,
            valueColor: AlwaysStoppedAnimation<Color>(_getColor()),
          ),
        ),
      ],
    );
  }
}

/// Circular profile completion indicator
class CircularProfileCompletion extends StatelessWidget {

  const CircularProfileCompletion({
    required this.completion, super.key,
    this.size = 60,
  });
  final double completion;
  final double size;

  Color _getColor() {
    if (completion >= 100) return AppColors.successGreen;
    if (completion >= 70) return AppColors.richGold;
    if (completion >= 40) return AppColors.warningAmber;
    return AppColors.errorRed;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: completion / 100,
            strokeWidth: 5,
            backgroundColor: AppColors.backgroundInput,
            valueColor: AlwaysStoppedAnimation<Color>(_getColor()),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${completion.toInt()}%',
                style: TextStyle(
                  color: _getColor(),
                  fontSize: size * 0.25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (completion < 100)
                Icon(
                  Icons.edit,
                  size: size * 0.2,
                  color: AppColors.textTertiary,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
