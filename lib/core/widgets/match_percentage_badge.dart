import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Enhancement #4: Match Percentage Badge
/// Shows compatibility score as a percentage
class MatchPercentageBadge extends StatelessWidget {
  final double percentage;
  final double size;
  final bool showLabel;

  const MatchPercentageBadge({
    super.key,
    required this.percentage,
    this.size = 40,
    this.showLabel = true,
  });

  Color _getColor() {
    if (percentage >= 80) return AppColors.successGreen;
    if (percentage >= 60) return AppColors.richGold;
    if (percentage >= 40) return AppColors.warningAmber;
    return AppColors.textTertiary;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size * 0.3,
        vertical: size * 0.15,
      ),
      decoration: BoxDecoration(
        color: _getColor().withOpacity(0.2),
        borderRadius: BorderRadius.circular(size * 0.4),
        border: Border.all(
          color: _getColor(),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.favorite,
            size: size * 0.4,
            color: _getColor(),
          ),
          const SizedBox(width: 4),
          Text(
            '${percentage.toInt()}%',
            style: TextStyle(
              color: _getColor(),
              fontSize: size * 0.35,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (showLabel) ...[
            const SizedBox(width: 2),
            Text(
              'match',
              style: TextStyle(
                color: _getColor().withOpacity(0.8),
                fontSize: size * 0.25,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Circular match percentage indicator
class CircularMatchIndicator extends StatelessWidget {
  final double percentage;
  final double size;

  const CircularMatchIndicator({
    super.key,
    required this.percentage,
    this.size = 50,
  });

  Color _getColor() {
    if (percentage >= 80) return AppColors.successGreen;
    if (percentage >= 60) return AppColors.richGold;
    if (percentage >= 40) return AppColors.warningAmber;
    return AppColors.textTertiary;
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
            value: percentage / 100,
            strokeWidth: 4,
            backgroundColor: AppColors.backgroundInput,
            valueColor: AlwaysStoppedAnimation<Color>(_getColor()),
          ),
          Text(
            '${percentage.toInt()}%',
            style: TextStyle(
              color: _getColor(),
              fontSize: size * 0.25,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
