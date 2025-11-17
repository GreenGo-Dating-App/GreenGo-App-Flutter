import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class OnboardingProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const OnboardingProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: LinearProgressIndicator(
                value: (currentStep + 1) / totalSteps,
                backgroundColor: AppColors.backgroundInput,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.richGold),
                minHeight: 6,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              '${currentStep + 1}/$totalSteps',
              style: const TextStyle(
                color: AppColors.richGold,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
