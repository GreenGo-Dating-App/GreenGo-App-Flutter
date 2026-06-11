import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../../../generated/app_localizations.dart';
import '../tour_controller.dart';
import 'gesture_glyphs.dart';
import 'gesture_tooltip.dart';

/// Wraps a tour target in a [Showcase.withWidget] step with the GreenGo
/// gesture tooltip.
///
/// When [interactive] is true the step advances only when the user performs
/// [gesture] (tap / double-tap / long-press) on the highlighted target; the
/// tooltip then shows a pulsing "Try it!" hint instead of a Next button.
class TourShowcase extends StatelessWidget {
  const TourShowcase({
    required this.showcaseKey,
    required this.title,
    required this.description,
    required this.child,
    this.gesture = TourGesture.none,
    this.interactive = false,
    this.targetBorderRadius,
    this.targetShapeBorder,
    this.targetPadding = EdgeInsets.zero,
    this.tooltipPosition,
    super.key,
  });

  final GlobalKey showcaseKey;
  final String title;
  final String description;
  final Widget child;
  final TourGesture gesture;
  final bool interactive;
  final BorderRadius? targetBorderRadius;
  final ShapeBorder? targetShapeBorder;
  final EdgeInsets targetPadding;
  final TooltipPosition? tooltipPosition;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = TourController.instance;
    final (stepIndex, stepCount) = controller.stepNumberFor(showcaseKey);

    void skip() {
      if (controller.isMainTourActive) {
        controller.skipMainTour(context);
      } else {
        ShowCaseWidget.of(context).dismiss();
      }
    }

    void advance() => controller.advance(context);

    final interactiveTap = interactive && gesture == TourGesture.tap;
    final interactiveLongPress =
        interactive && gesture == TourGesture.longPress;
    final interactiveDoubleTap =
        interactive && gesture == TourGesture.doubleTap;

    return Showcase.withWidget(
      key: showcaseKey,
      width: GestureTooltip.width,
      height: GestureTooltip.height,
      targetBorderRadius: targetBorderRadius,
      targetShapeBorder: targetShapeBorder ??
          const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
      targetPadding: targetPadding,
      tooltipPosition: tooltipPosition,
      disableBarrierInteraction: true,
      overlayOpacity: 0.8,
      onTargetClick: interactiveTap ? advance : null,
      disposeOnTap: interactiveTap ? false : null,
      onTargetLongPress: interactiveLongPress ? advance : null,
      onTargetDoubleTap: interactiveDoubleTap ? advance : null,
      container: GestureTooltip(
        title: title,
        description: description,
        gesture: gesture,
        stepIndex: stepIndex,
        stepCount: stepCount,
        interactive: interactive,
        onNext: advance,
        onSkip: skip,
        nextLabel: l10n?.tourNext ?? 'Next',
        skipLabel: l10n?.tourSkip ?? 'Skip',
        tryItLabel: l10n?.tourTryIt ?? 'Try it!',
      ),
      child: child,
    );
  }
}
