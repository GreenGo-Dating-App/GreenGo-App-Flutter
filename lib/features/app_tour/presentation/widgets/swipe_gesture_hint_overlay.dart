import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import 'gesture_glyphs.dart';

/// One-time overlay shown the first time the user enters swipe mode.
/// Demonstrates the three swipe directions; dismissed by tapping anywhere.
class SwipeGestureHintOverlay extends StatelessWidget {
  const SwipeGestureHintOverlay({required this.onDismiss, super.key});

  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Positioned.fill(
      child: GestureDetector(
        onTap: onDismiss,
        child: Container(
          color: Colors.black.withOpacity(0.82),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  l10n?.tourSwipeHintTitle ?? 'Swipe to connect',
                  style: const TextStyle(
                    color: AppColors.richGold,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _hint(
                      gesture: TourGesture.swipeLeft,
                      label: l10n?.tourSwipeHintPass ?? 'Pass',
                      icon: Icons.close,
                      color: AppColors.errorRed,
                    ),
                    _hint(
                      gesture: TourGesture.swipeUp,
                      label: l10n?.tourSwipeHintSuper ?? 'Super Like',
                      icon: Icons.star,
                      color: Colors.blueAccent,
                    ),
                    _hint(
                      gesture: TourGesture.swipeRight,
                      label: l10n?.tourSwipeHintLike ?? 'Like',
                      icon: Icons.favorite,
                      color: AppColors.successGreen,
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.richGold),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Text(
                    l10n?.tourGotIt ?? 'Got it',
                    style: const TextStyle(
                      color: AppColors.richGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _hint({
    required TourGesture gesture,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureGlyph(gesture: gesture, size: 72, color: color),
        const SizedBox(height: 8),
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
