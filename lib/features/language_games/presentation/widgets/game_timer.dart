import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// Animated countdown timer widget
/// Changes color from green -> yellow -> red as time decreases
/// Supports circular and linear modes with pulsing danger animation
class GameTimer extends StatelessWidget {
  final int remainingSeconds;
  final int totalSeconds;
  final VoidCallback? onExpired;
  final bool isCircular;
  final double size;

  const GameTimer({
    super.key,
    required this.remainingSeconds,
    required this.totalSeconds,
    this.onExpired,
    this.isCircular = true,
    this.size = 60,
  });

  Color get _timerColor {
    if (totalSeconds <= 0) return AppColors.errorRed;
    final ratio = remainingSeconds / totalSeconds;
    if (ratio > 0.5) return AppColors.successGreen;
    if (ratio > 0.25) return AppColors.warningAmber;
    return AppColors.errorRed;
  }

  bool get _isDanger => remainingSeconds <= 5 && remainingSeconds > 0;

  @override
  Widget build(BuildContext context) {
    if (isCircular) {
      return _buildCircularTimer();
    }
    return _buildLinearTimer();
  }

  Widget _buildCircularTimer() {
    final progress =
        totalSeconds > 0 ? (remainingSeconds / totalSeconds).clamp(0.0, 1.0) : 0.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _TimerArcPainter(
                progress: 1.0,
                color: AppColors.divider.withValues(alpha: 0.3),
                strokeWidth: 4,
              ),
            ),
          ),
          // Progress circle
          SizedBox(
            width: size,
            height: size,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: progress, end: progress),
              duration: const Duration(milliseconds: 300),
              builder: (context, value, _) {
                return CustomPaint(
                  painter: _TimerArcPainter(
                    progress: value,
                    color: _timerColor,
                    strokeWidth: 4,
                  ),
                );
              },
            ),
          ),
          // Time text with optional pulsing
          _isDanger
              ? _PulsingText(
                  text: '$remainingSeconds',
                  color: _timerColor,
                  fontSize: size / 2.8,
                )
              : Text(
                  '$remainingSeconds',
                  style: TextStyle(
                    color: _timerColor,
                    fontSize: size / 3,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildLinearTimer() {
    final progress =
        totalSeconds > 0 ? (remainingSeconds / totalSeconds).clamp(0.0, 1.0) : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: AppColors.divider,
            valueColor: AlwaysStoppedAnimation<Color>(_timerColor),
          ),
        ),
        const SizedBox(height: 4),
        _isDanger
            ? _PulsingText(
                text: '${remainingSeconds}s',
                color: _timerColor,
                fontSize: 12,
              )
            : Text(
                '${remainingSeconds}s',
                style: TextStyle(
                  color: _timerColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ],
    );
  }
}

/// Custom painter for the timer arc with rounded stroke caps
class _TimerArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _TimerArcPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _TimerArcPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

/// Pulsing text widget for danger zone countdown
class _PulsingText extends StatefulWidget {
  final String text;
  final Color color;
  final double fontSize;

  const _PulsingText({
    required this.text,
    required this.color,
    required this.fontSize,
  });

  @override
  State<_PulsingText> createState() => _PulsingTextState();
}

class _PulsingTextState extends State<_PulsingText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Text(
        widget.text,
        style: TextStyle(
          color: widget.color,
          fontSize: widget.fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
