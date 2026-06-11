import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../tour_controller.dart';
import 'gesture_glyphs.dart';

/// Custom tooltip used by every tour step (via [Showcase.withWidget]).
///
/// Shows an animated gesture glyph, title, description, step counter and
/// Skip / Next actions. The step counter is resolved from [TourController]
/// at build time — the overlay rebuilds this widget when each step is
/// shown, so numbering stays correct even though the underlying screens
/// (cached in an IndexedStack) don't rebuild when the tour starts.
class GestureTooltip extends StatelessWidget {
  const GestureTooltip({
    required this.showcaseKey,
    required this.title,
    required this.description,
    required this.gesture,
    required this.onSkip,
    required this.onNext,
    this.nextLabel = 'Next',
    this.skipLabel = 'Skip',
    super.key,
  });

  final GlobalKey showcaseKey;
  final String title;
  final String description;
  final TourGesture gesture;
  final VoidCallback onSkip;
  final VoidCallback onNext;
  final String nextLabel;
  final String skipLabel;

  static const double width = 300;
  static const double height = 220;

  @override
  Widget build(BuildContext context) {
    final (stepIndex, stepCount) =
        TourController.instance.stepNumberFor(showcaseKey);
    return Material(
      color: Colors.transparent,
      child: Container(
        width: width,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        decoration: BoxDecoration(
          color: AppColors.charcoal,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.richGold, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (gesture != TourGesture.none) ...[
                  GestureGlyph(gesture: gesture, size: 44),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.richGold,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13.5,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                if (stepCount > 0)
                  Text(
                    '$stepIndex/$stepCount',
                    style: const TextStyle(
                      color: AppColors.textTertiary,
                      fontSize: 12,
                    ),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: onSkip,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textTertiary,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: const Size(0, 34),
                  ),
                  child: Text(skipLabel, style: const TextStyle(fontSize: 13)),
                ),
                const SizedBox(width: 4),
                ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.richGold,
                    foregroundColor: AppColors.deepBlack,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    minimumSize: const Size(0, 34),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    nextLabel,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
