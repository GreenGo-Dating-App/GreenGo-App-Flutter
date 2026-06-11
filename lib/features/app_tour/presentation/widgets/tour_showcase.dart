import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

import '../../../../generated/app_localizations.dart';
import '../tour_controller.dart';
import 'gesture_glyphs.dart';
import 'gesture_tooltip.dart';

/// Wraps a tour target in a [Showcase.withWidget] step with the GreenGo
/// gesture tooltip. Every step advances via the Next button (tapping the
/// highlighted target also advances — default showcase behavior); the
/// animated [gesture] glyph in the tooltip demonstrates the interaction.
class TourShowcase extends StatelessWidget {
  const TourShowcase({
    required this.showcaseKey,
    required this.title,
    required this.description,
    required this.child,
    this.gesture = TourGesture.none,
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
  final BorderRadius? targetBorderRadius;
  final ShapeBorder? targetShapeBorder;
  final EdgeInsets targetPadding;
  final TooltipPosition? tooltipPosition;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = TourController.instance;

    void skip() {
      if (controller.isMainTourActive) {
        controller.skipMainTour(context);
      } else {
        ShowCaseWidget.of(context).dismiss();
      }
    }

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
      container: GestureTooltip(
        showcaseKey: showcaseKey,
        title: title,
        description: description,
        gesture: gesture,
        onNext: () => controller.advance(context),
        onSkip: skip,
        nextLabel: l10n?.tourNext ?? 'Next',
        skipLabel: l10n?.tourSkip ?? 'Skip',
      ),
      child: child,
    );
  }
}
