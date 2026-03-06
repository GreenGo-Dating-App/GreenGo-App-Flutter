import 'package:flutter/material.dart';

/// Custom painter that draws constellation lines connecting star nodes.
/// Completed connections glow gold, incomplete ones are dashed grey.
/// Supports opacity gradient for directional sense and inter-unit connections.
class ConstellationPainter extends CustomPainter {
  final List<Offset> starPositions;
  final List<bool> completedStars;
  final double animationProgress;
  final Offset? nextConstellationStart;
  final Offset? unitTitlePosition;

  ConstellationPainter({
    required this.starPositions,
    required this.completedStars,
    this.animationProgress = 1.0,
    this.nextConstellationStart,
    this.unitTitlePosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (starPositions.length < 2) return;

    for (int i = 0; i < starPositions.length - 1; i++) {
      final start = starPositions[i];
      final end = starPositions[i + 1];
      final isCompleted =
          i < completedStars.length && completedStars[i] && (i + 1 < completedStars.length && completedStars[i + 1]);

      // Opacity gradient: lines closer to start are brighter
      final lineOpacity = 0.15 + 0.15 * (1.0 - i / starPositions.length);

      if (isCompleted) {
        _drawCompletedLine(canvas, start, end, lineOpacity);
      } else {
        _drawIncompleteLine(canvas, start, end, lineOpacity);
      }
    }

    // Draw inter-unit connection line if provided
    if (nextConstellationStart != null && starPositions.isNotEmpty) {
      _drawInterUnitLine(canvas, starPositions.last, nextConstellationStart!);
    }

    // Draw title-to-first-node connection line
    if (unitTitlePosition != null && starPositions.isNotEmpty) {
      _drawTitleConnectionLine(canvas, unitTitlePosition!, starPositions.first);
    }
  }

  void _drawCompletedLine(Canvas canvas, Offset start, Offset end, double baseOpacity) {
    // Glow effect
    final glowPaint = Paint()
      ..color = const Color(0xFFD4AF37).withOpacity(0.25 * (baseOpacity / 0.3).clamp(0.5, 1.0))
      ..strokeWidth = 6.0
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    canvas.drawLine(start, end, glowPaint);

    // Solid gold line (wider for visibility)
    final solidPaint = Paint()
      ..color = const Color(0xFFD4AF37).withOpacity((baseOpacity + 0.4).clamp(0.0, 1.0))
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(start, end, solidPaint);
  }

  void _drawIncompleteLine(Canvas canvas, Offset start, Offset end, double baseOpacity) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(baseOpacity)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Dashed line
    final path = Path()
      ..moveTo(start.dx, start.dy)
      ..lineTo(end.dx, end.dy);

    final dashPath = _createDashedPath(path, 6.0, 4.0);
    canvas.drawPath(dashPath, paint);
  }

  void _drawInterUnitLine(Canvas canvas, Offset from, Offset to) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.12)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..lineTo(to.dx, to.dy);

    final dashPath = _createDashedPath(path, 8.0, 6.0);
    canvas.drawPath(dashPath, paint);
  }

  Path _createDashedPath(Path source, double dashLength, double gapLength) {
    final dashedPath = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + dashLength).clamp(0.0, metric.length);
        dashedPath.addPath(
          metric.extractPath(distance, end),
          Offset.zero,
        );
        distance += dashLength + gapLength;
      }
    }
    return dashedPath;
  }

  void _drawTitleConnectionLine(Canvas canvas, Offset from, Offset to) {
    // Glow
    final glowPaint = Paint()
      ..color = const Color(0xFFD4AF37).withOpacity(0.12)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
    canvas.drawLine(from, to, glowPaint);

    // Dashed gold line
    final paint = Paint()
      ..color = const Color(0xFFD4AF37).withOpacity(0.35)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..lineTo(to.dx, to.dy);

    final dashPath = _createDashedPath(path, 5.0, 4.0);
    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(covariant ConstellationPainter oldDelegate) {
    return oldDelegate.animationProgress != animationProgress ||
        oldDelegate.starPositions != starPositions ||
        oldDelegate.completedStars != completedStars ||
        oldDelegate.nextConstellationStart != nextConstellationStart ||
        oldDelegate.unitTitlePosition != unitTitlePosition;
  }
}
