import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import 'gesture_glyphs.dart';

/// One-time overlay shown the first time the user enters swipe mode.
/// Lists the four swipe actions top-to-bottom — Explore (down), Connect
/// (right), Priority Connect (up), Pass (left) — using the same labels as
/// the in-card swipe indicators. Dismissed by tapping anywhere.
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
                const SizedBox(height: 28),
                _hint(
                  gesture: TourGesture.pullDown,
                  label: l10n?.swipeIndicatorSkip ?? 'EXPLORE NEXT',
                  icon: Icons.arrow_downward,
                  color: AppColors.infoBlue,
                ),
                _hint(
                  gesture: TourGesture.swipeRight,
                  label: l10n?.swipeIndicatorLike ?? 'CONNECT',
                  icon: Icons.connect_without_contact,
                  color: AppColors.successGreen,
                ),
                _hint(
                  gesture: TourGesture.swipeUp,
                  label: l10n?.swipeIndicatorSuperLike ?? 'PRIORITY CONNECT',
                  icon: Icons.star,
                  color: AppColors.richGold,
                ),
                _hint(
                  gesture: TourGesture.swipeLeft,
                  label: l10n?.swipeIndicatorNope ?? 'PASS',
                  icon: Icons.close,
                  color: AppColors.errorRed,
                ),
                const SizedBox(height: 36),
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 32),
      child: Row(
        children: [
          GestureGlyph(gesture: gesture, size: 52, color: color),
          const SizedBox(width: 20),
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 17,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
