import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Enhancement #27: Sound/Vibration Feedback
/// Haptic feedback utilities
class HapticFeedbackHelper {
  static void light() {
    HapticFeedback.lightImpact();
  }

  static void medium() {
    HapticFeedback.mediumImpact();
  }

  static void heavy() {
    HapticFeedback.heavyImpact();
  }

  static void selection() {
    HapticFeedback.selectionClick();
  }

  static void vibrate() {
    HapticFeedback.vibrate();
  }

  /// Like action feedback
  static void onLike() {
    HapticFeedback.mediumImpact();
  }

  /// Super like action feedback
  static void onSuperLike() {
    HapticFeedback.heavyImpact();
  }

  /// Nope/Pass action feedback
  static void onNope() {
    HapticFeedback.lightImpact();
  }

  /// Match celebration feedback
  static void onMatch() {
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 100), () {
      HapticFeedback.heavyImpact();
    });
  }

  /// Message sent feedback
  static void onMessageSent() {
    HapticFeedback.lightImpact();
  }

  /// Button tap feedback
  static void onButtonTap() {
    HapticFeedback.selectionClick();
  }

  /// Error feedback
  static void onError() {
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 100), () {
      HapticFeedback.heavyImpact();
    });
    Future.delayed(const Duration(milliseconds: 200), () {
      HapticFeedback.heavyImpact();
    });
  }

  /// Success feedback
  static void onSuccess() {
    HapticFeedback.mediumImpact();
  }
}

/// Widget wrapper that adds haptic feedback on tap
class HapticButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final HapticFeedbackType feedbackType;

  const HapticButton({
    super.key,
    required this.child,
    this.onPressed,
    this.feedbackType = HapticFeedbackType.selection,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        switch (feedbackType) {
          case HapticFeedbackType.light:
            HapticFeedbackHelper.light();
            break;
          case HapticFeedbackType.medium:
            HapticFeedbackHelper.medium();
            break;
          case HapticFeedbackType.heavy:
            HapticFeedbackHelper.heavy();
            break;
          case HapticFeedbackType.selection:
            HapticFeedbackHelper.selection();
            break;
        }
        onPressed?.call();
      },
      child: child,
    );
  }
}

enum HapticFeedbackType {
  light,
  medium,
  heavy,
  selection,
}
