import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/app_sound_service.dart';

/// Animated bomb widget for Word Bomb game
class BombWidget extends StatefulWidget {
  final int remainingSeconds;
  final int totalSeconds;
  final String prompt;
  final bool hasExploded;

  const BombWidget({
    super.key,
    required this.remainingSeconds,
    required this.totalSeconds,
    required this.prompt,
    this.hasExploded = false,
  });

  @override
  State<BombWidget> createState() => _BombWidgetState();
}

class _BombWidgetState extends State<BombWidget>
    with TickerProviderStateMixin {
  late AnimationController _shakeController;
  late AnimationController _pulseController;
  late Animation<double> _shakeAnimation;
  late Animation<double> _pulseAnimation;

  // Explosion animation
  late AnimationController _explosionController;
  late Animation<double> _explosionScale;
  late Animation<double> _explosionFade;
  late AnimationController _particleController;
  late Animation<double> _particleSpread;
  late Animation<double> _particleFade;
  late AnimationController _flashController;
  late Animation<double> _flashOpacity;
  late AnimationController _boomController;
  late Animation<double> _boomScale;

  bool _hasTriggeredExplosion = false;

  @override
  void initState() {
    super.initState();

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _shakeAnimation = Tween<double>(begin: -3, end: 3).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Explosion: bomb scales up then disappears
    _explosionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _explosionScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.5), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.5, end: 0.0), weight: 70),
    ]).animate(CurvedAnimation(parent: _explosionController, curve: Curves.easeOut));
    _explosionFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _explosionController, curve: const Interval(0.4, 1.0)),
    );

    // Radial particles
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _particleSpread = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _particleController, curve: Curves.easeOut),
    );
    _particleFade = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _particleController, curve: const Interval(0.3, 1.0)),
    );

    // Screen flash
    _flashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _flashOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.3), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.3, end: 0.0), weight: 70),
    ]).animate(_flashController);

    // BOOM text
    _boomController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _boomScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _boomController, curve: Curves.elasticOut),
    );

    _updateShakeIntensity();
  }

  @override
  void didUpdateWidget(BombWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    _updateShakeIntensity();

    // Tick sound when remaining changes
    if (widget.remainingSeconds != oldWidget.remainingSeconds &&
        widget.remainingSeconds <= 3 &&
        widget.remainingSeconds > 0) {
      AppSoundService().play(AppSound.bombTick);
    }

    // Trigger explosion animation
    if (widget.hasExploded && !oldWidget.hasExploded) {
      _triggerExplosion();
    }
  }

  void _updateShakeIntensity() {
    if (widget.hasExploded || widget.totalSeconds <= 0) return;

    final ratio = widget.totalSeconds > 0
        ? widget.remainingSeconds / widget.totalSeconds
        : 1.0;

    if (ratio < 0.6) {
      // Intensifying shake — amplitude increases as time decreases
      final intensity = (1.0 - ratio).clamp(0.0, 1.0);
      _shakeAnimation = Tween<double>(
        begin: -(3 + intensity * 6),
        end: 3 + intensity * 6,
      ).animate(CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn));

      if (!_shakeController.isAnimating) {
        _shakeController.repeat(reverse: true);
      }
      // Speed up shake as time decreases
      _shakeController.duration = Duration(
        milliseconds: (120 - (intensity * 60).toInt()).clamp(50, 120),
      );
    } else {
      _shakeController.stop();
      _shakeController.reset();
    }
  }

  void _triggerExplosion() {
    if (_hasTriggeredExplosion) return;
    _hasTriggeredExplosion = true;

    AppSoundService().play(AppSound.bombExplode);
    HapticFeedback.heavyImpact();

    _shakeController.stop();
    _pulseController.stop();

    _explosionController.forward();
    _particleController.forward();
    _flashController.forward();

    // BOOM text appears after bomb disappears
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _boomController.forward();
    });
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _pulseController.dispose();
    _explosionController.dispose();
    _particleController.dispose();
    _flashController.dispose();
    _boomController.dispose();
    super.dispose();
  }

  double get _timeRatio => widget.totalSeconds > 0
      ? widget.remainingSeconds / widget.totalSeconds
      : 0.0;

  Color get _fuseColor {
    if (_timeRatio > 0.5) return AppColors.successGreen;
    if (_timeRatio > 0.25) return AppColors.warningAmber;
    return AppColors.errorRed;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.hasExploded) {
      return _buildExplosionAnimation();
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_shakeAnimation, _pulseAnimation]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            _shakeController.isAnimating ? _shakeAnimation.value : 0,
            0,
          ),
          child: Transform.scale(
            scale: _pulseAnimation.value,
            child: child,
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Fuse with burn-down animation
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 4,
            height: 20 * _timeRatio.clamp(0.05, 1.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_fuseColor, AppColors.warningAmber],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Bomb body with countdown ring
          SizedBox(
            width: 130,
            height: 130,
            child: CustomPaint(
              painter: _CountdownRingPainter(
                ratio: _timeRatio,
                color: _fuseColor,
              ),
              child: Center(
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.backgroundCard,
                    border: Border.all(
                      color: _fuseColor,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _fuseColor.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Prompt text
                      Text(
                        widget.prompt.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.richGold,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Timer
                      Text(
                        '${widget.remainingSeconds}s',
                        style: TextStyle(
                          color: _fuseColor,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExplosionAnimation() {
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Screen flash overlay
          AnimatedBuilder(
            animation: _flashOpacity,
            builder: (context, _) {
              return Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: _flashOpacity.value),
                ),
              );
            },
          ),

          // Radial particles
          AnimatedBuilder(
            animation: Listenable.merge([_particleSpread, _particleFade]),
            builder: (context, _) {
              return CustomPaint(
                size: const Size(200, 200),
                painter: _ExplosionParticlePainter(
                  spread: _particleSpread.value,
                  opacity: _particleFade.value,
                ),
              );
            },
          ),

          // Bomb scaling out
          AnimatedBuilder(
            animation: Listenable.merge([_explosionScale, _explosionFade]),
            builder: (context, _) {
              return Opacity(
                opacity: _explosionFade.value,
                child: Transform.scale(
                  scale: _explosionScale.value,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.backgroundCard,
                      border: Border.all(color: AppColors.errorRed, width: 3),
                    ),
                    child: const Center(
                      child: Text(
                        '💥',
                        style: TextStyle(fontSize: 40),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // BOOM! text
          AnimatedBuilder(
            animation: _boomScale,
            builder: (context, _) {
              return Transform.scale(
                scale: _boomScale.value,
                child: const Text(
                  'BOOM!',
                  style: TextStyle(
                    color: AppColors.errorRed,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: AppColors.warningAmber,
                        blurRadius: 20,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Draws a depleting arc around the bomb body
class _CountdownRingPainter extends CustomPainter {
  final double ratio;
  final Color color;

  _CountdownRingPainter({required this.ratio, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Background track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color.withValues(alpha: 0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    // Progress arc
    final sweepAngle = 2 * pi * ratio;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      sweepAngle,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _CountdownRingPainter oldDelegate) {
    return oldDelegate.ratio != ratio || oldDelegate.color != color;
  }
}

/// Draws 12 radial particles flying outward
class _ExplosionParticlePainter extends CustomPainter {
  final double spread;
  final double opacity;

  _ExplosionParticlePainter({required this.spread, required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const particleCount = 12;
    final maxRadius = size.width / 2;

    for (int i = 0; i < particleCount; i++) {
      final angle = (2 * pi / particleCount) * i;
      final distance = maxRadius * spread;
      final particleSize = (6.0 - spread * 4.0).clamp(1.0, 6.0);

      final px = center.dx + cos(angle) * distance;
      final py = center.dy + sin(angle) * distance;

      final color = i % 3 == 0
          ? AppColors.errorRed
          : i % 3 == 1
              ? AppColors.warningAmber
              : AppColors.richGold;

      canvas.drawCircle(
        Offset(px, py),
        particleSize,
        Paint()..color = color.withValues(alpha: opacity),
      );

      // Glow
      canvas.drawCircle(
        Offset(px, py),
        particleSize * 2.5,
        Paint()..color = color.withValues(alpha: opacity * 0.3),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ExplosionParticlePainter oldDelegate) {
    return oldDelegate.spread != spread || oldDelegate.opacity != opacity;
  }
}
