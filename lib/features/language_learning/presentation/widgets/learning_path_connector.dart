import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// CustomPainter-based widget that draws curved connecting lines
/// between learning path nodes. Supports completed (gold) and
/// incomplete (gray dashed) states.
class LearningPathConnector extends StatefulWidget {
  final bool isCompleted;
  final bool isLeft; // true = curves left, false = curves right
  final int connectorIndex;

  const LearningPathConnector({
    super.key,
    this.isCompleted = false,
    this.isLeft = true,
    this.connectorIndex = 0,
  });

  @override
  State<LearningPathConnector> createState() => _LearningPathConnectorState();
}

class _LearningPathConnectorState extends State<LearningPathConnector>
    with SingleTickerProviderStateMixin {
  late AnimationController _drawController;

  @override
  void initState() {
    super.initState();
    _drawController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    if (widget.isCompleted) {
      final delay = Duration(
        milliseconds: (widget.connectorIndex * 80).clamp(0, 1200),
      );
      Future.delayed(delay, () {
        if (mounted) _drawController.forward();
      });
    }
  }

  @override
  void dispose() {
    _drawController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCompleted) {
      return AnimatedBuilder(
        animation: _drawController,
        builder: (context, _) {
          return SizedBox(
            height: 60,
            width: double.infinity,
            child: CustomPaint(
              painter: _PathConnectorPainter(
                isCompleted: true,
                isLeft: widget.isLeft,
                drawProgress: _drawController.value,
              ),
            ),
          );
        },
      );
    }

    return SizedBox(
      height: 60,
      width: double.infinity,
      child: CustomPaint(
        painter: _PathConnectorPainter(
          isCompleted: false,
          isLeft: widget.isLeft,
        ),
      ),
    );
  }
}

class _PathConnectorPainter extends CustomPainter {
  final bool isCompleted;
  final bool isLeft;
  final double drawProgress;

  _PathConnectorPainter({
    required this.isCompleted,
    required this.isLeft,
    this.drawProgress = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isCompleted ? AppColors.richGold : AppColors.textTertiary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final centerX = size.width / 2;
    final offsetX = isLeft ? -30.0 : 30.0;

    final path = Path();
    path.moveTo(centerX, 0);

    // S-curve from top-center to bottom with horizontal offset
    path.cubicTo(
      centerX, size.height * 0.3, // control point 1
      centerX + offsetX, size.height * 0.5, // control point 2
      centerX + offsetX, size.height * 0.7, // mid point
    );
    path.cubicTo(
      centerX + offsetX, size.height * 0.85, // control point 3
      centerX, size.height * 0.9, // control point 4
      centerX, size.height, // end point
    );

    if (isCompleted) {
      // Animated solid gold line for completed connections
      final metrics = path.computeMetrics();
      for (final metric in metrics) {
        final extractLength = metric.length * drawProgress;
        final extractedPath = metric.extractPath(0, extractLength);
        canvas.drawPath(extractedPath, paint);
      }
    } else {
      // Dashed gray line for incomplete connections
      _drawDashedPath(canvas, path, paint);
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Paint paint) {
    final metrics = path.computeMetrics();
    const dashLength = 6.0;
    const gapLength = 4.0;

    for (final metric in metrics) {
      double distance = 0;
      bool draw = true;
      while (distance < metric.length) {
        final length = draw ? dashLength : gapLength;
        final end = (distance + length).clamp(0.0, metric.length);
        if (draw) {
          final extractedPath = metric.extractPath(distance, end);
          canvas.drawPath(extractedPath, paint);
        }
        distance = end;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _PathConnectorPainter oldDelegate) {
    return oldDelegate.isCompleted != isCompleted ||
        oldDelegate.isLeft != isLeft ||
        oldDelegate.drawProgress != drawProgress;
  }
}
