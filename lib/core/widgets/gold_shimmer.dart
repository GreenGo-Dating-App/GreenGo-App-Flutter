import 'dart:async';

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// A slow band of light that sweeps across [child] (only where the child is
/// opaque) once every [interval] — the login logo's gold shimmer.
///
/// The sweep itself takes [sweep]; between sweeps nothing animates (a Timer
/// waits, no ticker runs), so the shimmer costs nothing ~60% of the time.
/// Only the ShaderMask rebuilds per frame — [child] is passed through.
/// Static (no band) with reduced motion.
class GoldShimmer extends StatefulWidget {
  const GoldShimmer({
    required this.child,
    super.key,
    this.interval = const Duration(seconds: 9),
    this.sweep = const Duration(milliseconds: 3420),
    this.initialDelay = const Duration(milliseconds: 1400),
  });

  final Widget child;
  final Duration interval;
  final Duration sweep;
  final Duration initialDelay;

  @override
  State<GoldShimmer> createState() => GoldShimmerState();
}

@visibleForTesting
class GoldShimmerState extends State<GoldShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.sweep)
        ..addStatusListener(_onStatus);
  // Same easing as the mock's elShine: cubic-bezier(.45,.05,.55,.95).
  late final Animation<double> _band = CurvedAnimation(
    parent: _controller,
    curve: const Cubic(0.45, 0.05, 0.55, 0.95),
  );
  Timer? _timer;
  bool _reducedMotion = false;

  /// True while a sweep is running (exposed for tests).
  bool get isSweeping => _controller.isAnimating;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduced == _reducedMotion && (_timer != null || reduced)) return;
    _reducedMotion = reduced;
    _timer?.cancel();
    _timer = null;
    if (reduced) {
      _controller.stop();
      _controller.value = 0;
    } else {
      // The first sweep lands at initialDelay + the idle part of a cycle,
      // exactly like the CSS keyframes (0–62 % idle, 62–100 % sweep).
      _schedule(widget.initialDelay + (widget.interval - widget.sweep));
    }
  }

  void _schedule(Duration wait) {
    _timer?.cancel();
    _timer = Timer(wait, () {
      if (!mounted || _reducedMotion) return;
      _controller.forward(from: 0);
    });
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && !_reducedMotion) {
      _schedule(widget.interval - widget.sweep);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _band,
      child: widget.child,
      builder: (context, child) {
        if (!_controller.isAnimating) return child!;
        // Band travels right → left across the logo (CSS 160% → -60%).
        final x = 1.6 - 2.2 * _band.value; // centre in "widths"
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            const half = 0.24; // band half-width, in widths
            final w = bounds.width;
            // The gradient spans only the band; clamp mode keeps the rest
            // transparent, so the band keeps its shape at the edges.
            final band = Rect.fromLTWH(
              bounds.left + (x - half) * w,
              bounds.top,
              2 * half * w,
              bounds.height,
            );
            return LinearGradient(
              colors: [
                AppColors.liquidGoldCream.withValues(alpha: 0),
                AppColors.liquidGoldCream.withValues(alpha: 0.85),
                AppColors.liquidGoldCream.withValues(alpha: 0),
              ],
              // ~100deg in the mock: a slight diagonal.
              transform: const GradientRotation(0.17),
            ).createShader(band);
          },
          child: child,
        );
      },
    );
  }
}
