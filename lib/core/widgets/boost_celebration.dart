import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// The moment a boost takes effect.
///
/// Boosting used to report itself with a snackbar - and for profiles not even
/// that survived: the success message was posted first and then immediately
/// replaced by the "activating..." one, so the user paid coins and saw nothing.
/// A boost is a purchase; it should feel like something happened.
///
/// Rays sweep out from a glowing rocket while the card scales in, then the
/// whole thing fades away on its own. It is also dismissible by tap, because
/// an animation that holds the screen hostage stops being a reward the second
/// time you see it.
///
/// Honours reduced motion: the same card appears, without the sweep or the
/// pulse.
class BoostCelebration extends StatefulWidget {
  const BoostCelebration({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  /// Shows the celebration and returns when it has gone.
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String subtitle,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.72),
      builder: (_) => BoostCelebration(title: title, subtitle: subtitle),
    );
  }

  @override
  State<BoostCelebration> createState() => _BoostCelebrationState();
}

class _BoostCelebrationState extends State<BoostCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  bool _reduceMotion = false;
  bool _closing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.of(context).disableAnimations;
    if (!_c.isAnimating && _c.value == 0) {
      // Runs even under reduced motion: the controller also drives the
      // auto-dismiss, and a celebration that never leaves is a modal trap.
      _c.forward().then((_) => _close());
    }
  }

  void _close() {
    if (_closing || !mounted) return;
    _closing = true;
    Navigator.of(context).maybePop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entrance = CurvedAnimation(
      parent: _c,
      curve: const Interval(0, 0.22, curve: Curves.easeOutBack),
    );

    return GestureDetector(
      onTap: _close,
      behavior: HitTestBehavior.opaque,
      child: Center(
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, child) {
            final scale = _reduceMotion ? 1.0 : entrance.value.clamp(0.0, 1.0);
            return Transform.scale(scale: scale, child: child);
          },
          child: Material(
            type: MaterialType.transparency,
            child: Container(
              width: 300,
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 24),
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: const Color(0xFFDAA520).withValues(alpha: 0.6),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFDAA520).withValues(alpha: 0.25),
                    blurRadius: 40,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 120,
                    width: 120,
                    child: AnimatedBuilder(
                      animation: _c,
                      builder: (context, _) => CustomPaint(
                        painter: _RayBurst(
                          // A single still frame under reduced motion.
                          progress: _reduceMotion ? 0.55 : _c.value,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.rocket_launch,
                            size: _reduceMotion
                                ? 52
                                : 52 + 6 * math.sin(_c.value * math.pi * 4),
                            color: const Color(0xFFFFD700),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.subtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Twelve rays sweeping outwards and fading, behind the rocket.
class _RayBurst extends CustomPainter {
  _RayBurst({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // Eased so the burst leaves quickly and settles, rather than crawling out
    // at a constant speed.
    final t = Curves.easeOutCubic.transform(progress.clamp(0.0, 1.0));
    final inner = 26 + 22 * t;
    final outer = inner + 14 * (1 - t) + 6;
    final opacity = (1 - t).clamp(0.0, 1.0);
    if (opacity <= 0.01) return;

    final paint = Paint()
      ..color = const Color(0xFFFFD700).withValues(alpha: 0.75 * opacity)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    const count = 12;
    for (var i = 0; i < count; i++) {
      final angle = (i / count) * 2 * math.pi + t * 0.5;
      final dx = math.cos(angle);
      final dy = math.sin(angle);
      canvas.drawLine(
        center + Offset(dx * inner, dy * inner),
        center + Offset(dx * outer, dy * outer),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_RayBurst old) => old.progress != progress;
}
