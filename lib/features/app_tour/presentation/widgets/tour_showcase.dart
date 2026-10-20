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
    this.enableAutoScroll,
    this.scrollAlignment = 0.5,
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

  /// Scrolls the target into view before its step shows (null = the
  /// ShowCaseWidget's setting). A step whose target sits below the fold
  /// otherwise anchors its bubble off screen.
  final bool? enableAutoScroll;

  /// Where the target lands in its scroll view when [enableAutoScroll]
  /// (0 = top, 1 = bottom): near the top leaves room for the bubble below.
  final double scrollAlignment;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final bubbleWidth =
        GestureTooltip.widthFor(MediaQuery.sizeOf(context).width);
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
      width: bubbleWidth,
      height: GestureTooltip.height,
      enableAutoScroll: enableAutoScroll,
      scrollAlignment: scrollAlignment,
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
        maxWidth: bubbleWidth,
      ),
      child: child,
    );
  }
}
