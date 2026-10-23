import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_glass.dart';

/// A reusable frosted-glass surface.
///
/// Clips to a rounded rectangle, applies a [BackdropFilter] blur behind a
/// translucent fill, draws a 1px hairline border (gold when [active]) and a
/// subtle top-edge white sheen so the glass reads against colourful backdrops.
///
/// The blurred surface is wrapped in a [RepaintBoundary] to isolate its
/// (relatively expensive) backdrop pass from surrounding repaints.
///
/// When [onTap] is supplied the container becomes tappable, playing a light
/// spring press (scale to 0.97) and a haptic tick before invoking the callback.
class GlassContainer extends StatefulWidget {
  const GlassContainer({
    required this.child,
    super.key,
    this.borderRadius = AppGlass.radiusCard,
    this.padding,
    this.blurSigma = AppGlass.blurSigma,
    this.active = false,
    this.onTap,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final double blurSigma;
  final bool active;
  final VoidCallback? onTap;

  @override
  State<GlassContainer> createState() => _GlassContainerState();
}

class _GlassContainerState extends State<GlassContainer> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) {
      setState(() => _pressed = value);
    }
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.borderRadius);

    Widget surface = RepaintBoundary(
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: widget.blurSigma,
            sigmaY: widget.blurSigma,
          ),
          child: Container(
            padding: widget.padding,
            decoration: BoxDecoration(
              color: AppGlass.surface,
              borderRadius: radius,
              border: Border.all(
                color: widget.active ? AppGlass.borderGold : AppGlass.border,
              ),
              // Subtle top-edge white sheen for a glassy highlight.
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withOpacity(0.08),
                  Colors.white.withOpacity(0.0),
                ],
                stops: const [0.0, 0.35],
              ),
            ),
            child: widget.child,
          ),
        ),
      ),
    );

    if (widget.onTap == null) {
      return surface;
    }

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      onTap: _handleTap,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: AppGlass.pressDuration,
        curve: AppGlass.spring,
        child: surface,
      ),
    );
  }
}
