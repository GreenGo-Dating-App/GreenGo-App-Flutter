import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// The gesture a tour step teaches. Drives which animated glyph is shown.
enum TourGesture {
  tap,
  doubleTap,
  longPress,
  edgeTaps,
  swipeRight,
  swipeLeft,
  swipeUp,
  pullDown,
  none,
}

/// Animated indicator for a single gesture, used inside tour tooltips and
/// the swipe-mode hint overlay. Loops until disposed.
class GestureGlyph extends StatefulWidget {
  const GestureGlyph({
    required this.gesture,
    this.size = 56,
    this.color = AppColors.richGold,
    super.key,
  });

  final TourGesture gesture;
  final double size;
  final Color color;

  @override
  State<GestureGlyph> createState() => _GestureGlyphState();
}

class _GestureGlyphState extends State<GestureGlyph>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _durationFor(widget.gesture),
    )..repeat();
  }

  Duration _durationFor(TourGesture gesture) {
    switch (gesture) {
      case TourGesture.longPress:
        return const Duration(milliseconds: 1800);
      case TourGesture.doubleTap:
        return const Duration(milliseconds: 1400);
      case TourGesture.none:
        return const Duration(seconds: 1);
      default:
        return const Duration(milliseconds: 1200);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.gesture == TourGesture.none) {
      return SizedBox.square(dimension: widget.size);
    }
    return SizedBox.square(
      dimension: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => CustomPaint(
          painter: _GlyphPainter(
            gesture: widget.gesture,
            progress: _controller.value,
            color: widget.color,
          ),
        ),
      ),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter({
    required this.gesture,
    required this.progress,
    required this.color,
  });

  final TourGesture gesture;
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;

    switch (gesture) {
      case TourGesture.tap:
        _paintTap(canvas, center, radius, progress);
        break;
      case TourGesture.doubleTap:
        // Two quick pulses in the first 70% of the loop, then rest.
        final local = progress < 0.35
            ? progress / 0.35
            : progress < 0.7
                ? (progress - 0.35) / 0.35
                : -1.0;
        if (local >= 0) {
          _paintTap(canvas, center, radius, local);
        } else {
          _paintFinger(canvas, center, radius, pressed: false);
        }
        break;
      case TourGesture.longPress:
        _paintLongPress(canvas, center, radius, progress);
        break;
      case TourGesture.edgeTaps:
        // Alternate a pulse on the left and right halves.
        final leftPhase = progress < 0.5;
        final local = (progress % 0.5) / 0.5;
        final side = Offset(
          leftPhase ? size.width * 0.25 : size.width * 0.75,
          center.dy,
        );
        _paintTap(canvas, side, radius * 0.6, local);
        break;
      case TourGesture.swipeRight:
        _paintSwipe(canvas, size, progress, const Offset(1, 0));
        break;
      case TourGesture.swipeLeft:
        _paintSwipe(canvas, size, progress, const Offset(-1, 0));
        break;
      case TourGesture.swipeUp:
        _paintSwipe(canvas, size, progress, const Offset(0, -1));
        break;
      case TourGesture.pullDown:
        _paintSwipe(canvas, size, progress, const Offset(0, 1));
        break;
      case TourGesture.none:
        break;
    }
  }

  void _paintTap(Canvas canvas, Offset center, double radius, double t) {
    // Expanding, fading ripple ring.
    final ripple = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = color.withOpacity((1 - t).clamp(0.0, 1.0));
    canvas.drawCircle(center, radius * (0.35 + 0.6 * t), ripple);
    _paintFinger(canvas, center, radius, pressed: t < 0.4);
  }

  void _paintLongPress(Canvas canvas, Offset center, double radius, double t) {
    // Hold for the first 70%: ring sweeps closed; then release.
    final holding = t < 0.7;
    final sweep = holding ? (t / 0.7) : 1.0;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = color.withOpacity(0.25);
    canvas.drawCircle(center, radius * 0.8, track);
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = color.withOpacity(holding ? 1.0 : 1 - (t - 0.7) / 0.3);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.8),
      -math.pi / 2,
      2 * math.pi * sweep,
      false,
      arc,
    );
    _paintFinger(canvas, center, radius, pressed: holding);
  }

  void _paintSwipe(Canvas canvas, Size size, double t, Offset direction) {
    final travel = size.shortestSide * 0.45;
    final start = Offset(size.width / 2, size.height / 2) -
        direction * (travel / 2);
    final pos = start + direction * (travel * Curves.easeOut.transform(t));
    final opacity = t < 0.15
        ? t / 0.15
        : t > 0.8
            ? (1 - t) / 0.2
            : 1.0;

    // Motion trail.
    final trail = Paint()
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = color.withOpacity(0.3 * opacity);
    canvas.drawLine(start, pos, trail);

    _paintFinger(canvas, pos, size.shortestSide / 2,
        pressed: true, opacity: opacity);

    // Arrow head at the end of the travel path.
    final tip = start + direction * travel;
    final perp = Offset(-direction.dy, direction.dx);
    final arrow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..color = color.withOpacity(0.8 * opacity);
    canvas.drawLine(tip, tip - direction * 8 + perp * 6, arrow);
    canvas.drawLine(tip, tip - direction * 8 - perp * 6, arrow);
  }

  void _paintFinger(Canvas canvas, Offset center, double radius,
      {required bool pressed, double opacity = 1.0}) {
    final dot = Paint()
      ..color = color.withOpacity((pressed ? 1.0 : 0.5) * opacity);
    canvas.drawCircle(center, radius * (pressed ? 0.22 : 0.18), dot);
    final rim = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = AppColors.textPrimary.withOpacity(0.85 * opacity);
    canvas.drawCircle(center, radius * (pressed ? 0.22 : 0.18), rim);
  }

  @override
  bool shouldRepaint(_GlyphPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.gesture != gesture;
}
