import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import 'gesture_glyphs.dart';

/// Custom tooltip used by every tour step (via [Showcase.withWidget]).
///
/// Shows an animated gesture glyph, title, description, step counter and
/// Skip / Next actions. When [interactive] is true the Next button becomes a
/// pulsing "Try it!" hint and the step only advances when the user performs
/// the gesture on the highlighted target.
class GestureTooltip extends StatelessWidget {
  const GestureTooltip({
    required this.title,
    required this.description,
    required this.gesture,
    required this.stepIndex,
    required this.stepCount,
    required this.onSkip,
    this.onNext,
    this.interactive = false,
    this.tryItLabel = 'Try it!',
    this.nextLabel = 'Next',
    this.skipLabel = 'Skip',
    super.key,
  });

  final String title;
  final String description;
  final TourGesture gesture;
  final int stepIndex;
  final int stepCount;
  final VoidCallback onSkip;
  final VoidCallback? onNext;
  final bool interactive;
  final String tryItLabel;
  final String nextLabel;
  final String skipLabel;

  static const double width = 300;
  static const double height = 220;

  @override
  Widget build(BuildContext context) {
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
                if (interactive)
                  _TryItPill(label: tryItLabel)
                else
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

/// Pulsing pill shown instead of the Next button on interactive steps.
class _TryItPill extends StatefulWidget {
  const _TryItPill({required this.label});

  final String label;

  @override
  State<_TryItPill> createState() => _TryItPillState();
}

class _TryItPillState extends State<_TryItPill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.55, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.richGold, width: 1.2),
        ),
        child: Text(
          widget.label,
          style: const TextStyle(
            color: AppColors.richGold,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
