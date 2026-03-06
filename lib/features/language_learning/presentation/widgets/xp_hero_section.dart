import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/entities/lesson.dart';

/// Animated XP hero section with circular progress ring, level badge,
/// and animated counter. Replaces the old stats overview.
class XpHeroSection extends StatefulWidget {
  final int totalXp;
  final int languagesLearning;

  const XpHeroSection({
    super.key,
    required this.totalXp,
    required this.languagesLearning,
  });

  @override
  State<XpHeroSection> createState() => _XpHeroSectionState();
}

class _XpHeroSectionState extends State<XpHeroSection>
    with SingleTickerProviderStateMixin {
  late AnimationController _ringController;
  late Animation<double> _ringAnimation;

  @override
  void initState() {
    super.initState();
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _ringAnimation = CurvedAnimation(
      parent: _ringController,
      curve: Curves.easeOutCubic,
    );
    _ringController.forward();
  }

  @override
  void didUpdateWidget(XpHeroSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.totalXp != widget.totalXp) {
      _ringController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ringController.dispose();
    super.dispose();
  }

  /// Determines the current LessonLevel based on total XP.
  LessonLevel _currentLevel(int xp) {
    final levels = LessonLevel.values.reversed;
    for (final level in levels) {
      if (xp >= level.requiredXp) return level;
    }
    return LessonLevel.absolute_beginner;
  }

  /// Returns the next LessonLevel, or null if already at max.
  LessonLevel? _nextLevel(LessonLevel current) {
    final idx = LessonLevel.values.indexOf(current);
    if (idx < LessonLevel.values.length - 1) {
      return LessonLevel.values[idx + 1];
    }
    return null;
  }

  /// Calculates progress fraction towards the next level (0.0 - 1.0).
  double _progressToNext(int xp, LessonLevel current, LessonLevel? next) {
    if (next == null) return 1.0;
    final range = next.requiredXp - current.requiredXp;
    if (range <= 0) return 1.0;
    final progress = xp - current.requiredXp;
    return (progress / range).clamp(0.0, 1.0);
  }

  /// Formats an integer with comma separators (e.g. 12345 -> "12,345").
  String _formatWithCommas(int value) {
    final str = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentLevel = _currentLevel(widget.totalXp);
    final nextLevel = _nextLevel(currentLevel);
    final progress = _progressToNext(widget.totalXp, currentLevel, nextLevel);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated circular progress ring with level badge
          SizedBox(
            width: 160,
            height: 160,
            child: AnimatedBuilder(
              animation: _ringAnimation,
              builder: (context, child) {
                return CustomPaint(
                  painter: _XpRingPainter(
                    progress: progress * _ringAnimation.value,
                    shimmerPhase: _ringAnimation.value,
                  ),
                  child: child,
                );
              },
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currentLevel.emoji,
                      style: const TextStyle(fontSize: 36),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currentLevel.displayName,
                      style: const TextStyle(
                        color: AppColors.richGold,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Animated XP counter
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: widget.totalXp),
            duration: const Duration(milliseconds: 1500),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return Text(
                _formatWithCommas(value),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              );
            },
          ),

          const SizedBox(height: 4),

          // "Total XP" label
          Text(
            l10n?.totalXpLabel ?? 'Total XP',
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 8),

          // Level label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.richGold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.richGold.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              l10n?.levelLabelN(currentLevel.displayName) ??
                  'Level ${currentLevel.displayName}',
              style: const TextStyle(
                color: AppColors.richGold,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for the animated XP progress ring with shimmer effect.
class _XpRingPainter extends CustomPainter {
  final double progress;
  final double shimmerPhase;

  _XpRingPainter({
    required this.progress,
    required this.shimmerPhase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) - 8;
    const strokeWidth = 8.0;

    // Background track
    final trackPaint = Paint()
      ..color = AppColors.divider
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    // Gold arc
    const startAngle = -pi / 2;
    final sweepAngle = 2 * pi * progress;

    // Shimmer gradient that rotates with the shimmer phase
    final shimmerRotation = shimmerPhase * 2 * pi;
    final gradientPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: shimmerRotation,
        endAngle: shimmerRotation + 2 * pi,
        colors: const [
          AppColors.richGold,
          AppColors.accentGold,
          Color(0xFFFFF8E1), // Light gold shimmer highlight
          AppColors.accentGold,
          AppColors.richGold,
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      gradientPaint,
    );

    // Subtle glow behind the arc end
    final glowAngle = startAngle + sweepAngle;
    final glowX = center.dx + radius * cos(glowAngle);
    final glowY = center.dy + radius * sin(glowAngle);

    final glowPaint = Paint()
      ..color = AppColors.richGold.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawCircle(Offset(glowX, glowY), strokeWidth, glowPaint);
  }

  @override
  bool shouldRepaint(_XpRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.shimmerPhase != shimmerPhase;
}
