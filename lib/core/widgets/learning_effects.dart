import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../services/app_sound_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CONFETTI EFFECT — Burst of particles on achievement/level-up/correct answer
// ─────────────────────────────────────────────────────────────────────────────

class ConfettiOverlay extends StatefulWidget {
  final bool trigger;
  final Widget child;
  final int particleCount;
  final Duration duration;

  const ConfettiOverlay({
    super.key,
    required this.trigger,
    required this.child,
    this.particleCount = 50,
    this.duration = const Duration(milliseconds: 2000),
  });

  @override
  State<ConfettiOverlay> createState() => _ConfettiOverlayState();
}

class _ConfettiOverlayState extends State<ConfettiOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<_ConfettiParticle> _particles = [];
  bool _previousTrigger = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
  }

  @override
  void didUpdateWidget(ConfettiOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && !_previousTrigger) {
      _startConfetti();
    }
    _previousTrigger = widget.trigger;
  }

  void _startConfetti() {
    final random = Random();
    _particles = List.generate(widget.particleCount, (_) {
      return _ConfettiParticle(
        x: random.nextDouble(),
        y: -0.1,
        velocityX: (random.nextDouble() - 0.5) * 2,
        velocityY: random.nextDouble() * 3 + 2,
        rotation: random.nextDouble() * 360,
        rotationSpeed: (random.nextDouble() - 0.5) * 10,
        size: random.nextDouble() * 8 + 4,
        color: _confettiColors[random.nextInt(_confettiColors.length)],
      );
    });
    _controller.forward(from: 0);
    HapticFeedback.mediumImpact();
  }

  static const _confettiColors = [
    AppColors.richGold,
    Colors.redAccent,
    Colors.blueAccent,
    Colors.greenAccent,
    Colors.purpleAccent,
    Colors.orangeAccent,
    Colors.pinkAccent,
    Colors.cyanAccent,
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_particles.isNotEmpty)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                size: Size.infinite,
                painter: _ConfettiPainter(
                  particles: _particles,
                  progress: _controller.value,
                ),
              );
            },
          ),
      ],
    );
  }
}

class _ConfettiParticle {
  double x, y, velocityX, velocityY, rotation, rotationSpeed, size;
  Color color;

  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.velocityX,
    required this.velocityY,
    required this.rotation,
    required this.rotationSpeed,
    required this.size,
    required this.color,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final currentX = (p.x + p.velocityX * progress * 0.3) * size.width;
      final currentY = (p.y + p.velocityY * progress * 0.4) * size.height;
      final opacity = (1.0 - progress).clamp(0.0, 1.0);

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(currentX, currentY);
      canvas.rotate((p.rotation + p.rotationSpeed * progress) * pi / 180);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
          Radius.circular(p.size * 0.15),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// XP PROGRESS BAR — Animated bar with glow effect
// ─────────────────────────────────────────────────────────────────────────────

class XpProgressBar extends StatefulWidget {
  final int currentXp;
  final int maxXp;
  final int level;
  final bool showLabel;
  final double height;

  const XpProgressBar({
    super.key,
    required this.currentXp,
    required this.maxXp,
    required this.level,
    this.showLabel = true,
    this.height = 20,
  });

  @override
  State<XpProgressBar> createState() => _XpProgressBarState();
}

class _XpProgressBarState extends State<XpProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _previousProgress = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _previousProgress = widget.currentXp / widget.maxXp;
    _animation = Tween<double>(begin: 0, end: _previousProgress).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(XpProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentXp != widget.currentXp) {
      final newProgress = widget.currentXp / widget.maxXp;
      _animation = Tween<double>(begin: _previousProgress, end: newProgress)
          .animate(CurvedAnimation(
              parent: _controller, curve: Curves.easeOutCubic));
      _previousProgress = newProgress;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showLabel)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.richGold,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'LV ${widget.level}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  '${widget.currentXp} / ${widget.maxXp} XP',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        AnimatedBuilder(
          animation: _animation,
          builder: (context, _) {
            return Container(
              height: widget.height,
              decoration: BoxDecoration(
                color: AppColors.backgroundDark,
                borderRadius: BorderRadius.circular(widget.height / 2),
              ),
              child: Stack(
                children: [
                  // Progress fill
                  FractionallySizedBox(
                    widthFactor: _animation.value.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(widget.height / 2),
                        gradient: const LinearGradient(
                          colors: [
                            AppColors.richGold,
                            Color(0xFFFFD700),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.richGold.withValues(alpha: 0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Shine effect
                  if (_animation.value > 0.05)
                    FractionallySizedBox(
                      widthFactor: _animation.value.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius:
                              BorderRadius.circular(widget.height / 2),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: 0.3),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.5],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STREAK FLAME — Animated fire icon for learning streaks
// ─────────────────────────────────────────────────────────────────────────────

class StreakFlame extends StatefulWidget {
  final int streakDays;
  final bool isActive;
  final double size;

  const StreakFlame({
    super.key,
    required this.streakDays,
    this.isActive = true,
    this.size = 40,
  });

  @override
  State<StreakFlame> createState() => _StreakFlameState();
}

class _StreakFlameState extends State<StreakFlame>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = 1.0 + (_controller.value * 0.1);
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Transform.scale(
              scale: widget.isActive ? scale : 1.0,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (widget.isActive)
                    Icon(
                      Icons.local_fire_department,
                      size: widget.size + 4,
                      color: Colors.orange.withValues(
                          alpha: 0.3 + _controller.value * 0.2),
                    ),
                  Icon(
                    Icons.local_fire_department,
                    size: widget.size,
                    color: widget.isActive
                        ? Colors.orange
                        : AppColors.textTertiary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${widget.streakDays}',
              style: TextStyle(
                color: widget.isActive
                    ? AppColors.richGold
                    : AppColors.textTertiary,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CORRECT/WRONG ANSWER FEEDBACK — Animated feedback with sound
// ─────────────────────────────────────────────────────────────────────────────

class AnswerFeedback extends StatefulWidget {
  final bool isCorrect;
  final VoidCallback? onComplete;

  const AnswerFeedback({
    super.key,
    required this.isCorrect,
    this.onComplete,
  });

  @override
  State<AnswerFeedback> createState() => _AnswerFeedbackState();
}

class _AnswerFeedbackState extends State<AnswerFeedback>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.3), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_controller);

    // Play sound
    AppSoundService().play(
      widget.isCorrect ? AppSound.correctAnswer : AppSound.wrongAnswer,
    );

    // Haptic feedback
    if (widget.isCorrect) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.heavyImpact();
    }

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isCorrect
                    ? Colors.green.withValues(alpha: 0.2)
                    : Colors.red.withValues(alpha: 0.2),
                border: Border.all(
                  color: widget.isCorrect ? Colors.green : Colors.red,
                  width: 3,
                ),
              ),
              child: Icon(
                widget.isCorrect ? Icons.check : Icons.close,
                size: 60,
                color: widget.isCorrect ? Colors.green : Colors.red,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// XP GAINED POPUP — Floating +XP text that animates upward
// ─────────────────────────────────────────────────────────────────────────────

class XpGainedPopup extends StatefulWidget {
  final int xpAmount;
  final VoidCallback? onComplete;

  const XpGainedPopup({
    super.key,
    required this.xpAmount,
    this.onComplete,
  });

  @override
  State<XpGainedPopup> createState() => _XpGainedPopupState();
}

class _XpGainedPopupState extends State<XpGainedPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -1.5),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(_controller);

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.5, end: 1.2), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 70),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    AppSoundService().play(AppSound.xpGained);

    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return SlideTransition(
          position: _slideAnimation,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.richGold.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.richGold.withValues(alpha: 0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Text(
                  '+${widget.xpAmount} XP',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LEVEL UP CELEBRATION — Full screen overlay with confetti + sound
// ─────────────────────────────────────────────────────────────────────────────

class LevelUpCelebration extends StatefulWidget {
  final int newLevel;
  final String? title;
  final VoidCallback? onDismiss;

  const LevelUpCelebration({
    super.key,
    required this.newLevel,
    this.title,
    this.onDismiss,
  });

  @override
  State<LevelUpCelebration> createState() => _LevelUpCelebrationState();
}

class _LevelUpCelebrationState extends State<LevelUpCelebration>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 40),
    ]).animate(
        CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut));

    AppSoundService().play(AppSound.levelUp);
    HapticFeedback.heavyImpact();

    _scaleController.forward();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onDismiss,
      child: Container(
        color: Colors.black.withValues(alpha: 0.7),
        child: Center(
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, _) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'LEVEL UP!',
                      style: TextStyle(
                        color: AppColors.richGold,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                        shadows: [
                          Shadow(
                            blurRadius: 20,
                            color: AppColors.richGold,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    AnimatedBuilder(
                      animation: _glowController,
                      builder: (context, _) {
                        return Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                AppColors.richGold.withValues(
                                    alpha: 0.3 + _glowController.value * 0.3),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '${widget.newLevel}',
                              style: const TextStyle(
                                color: AppColors.richGold,
                                fontSize: 64,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    if (widget.title != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        widget.title!,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 18,
                        ),
                      ),
                    ],
                    const SizedBox(height: 32),
                    const Text(
                      'Tap to continue',
                      style: TextStyle(
                        color: AppColors.textTertiary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHAKE ANIMATION — Wraps a widget and shakes it on wrong answer
// ─────────────────────────────────────────────────────────────────────────────

class ShakeWidget extends StatefulWidget {
  final Widget child;
  final bool trigger;
  final double shakeOffset;

  const ShakeWidget({
    super.key,
    required this.child,
    required this.trigger,
    this.shakeOffset = 10.0,
  });

  @override
  State<ShakeWidget> createState() => _ShakeWidgetState();
}

class _ShakeWidgetState extends State<ShakeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _previousTrigger = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _animation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1, end: -1), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -1, end: 0.7), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.7, end: -0.5), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -0.5, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(ShakeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && !_previousTrigger) {
      _controller.forward(from: 0);
      HapticFeedback.heavyImpact();
    }
    _previousTrigger = widget.trigger;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_animation.value * widget.shakeOffset, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PULSE GLOW — Makes any widget pulse with a glow (for hints, achievements)
// ─────────────────────────────────────────────────────────────────────────────

class PulseGlow extends StatefulWidget {
  final Widget child;
  final Color glowColor;
  final bool isActive;

  const PulseGlow({
    super.key,
    required this.child,
    this.glowColor = AppColors.richGold,
    this.isActive = true,
  });

  @override
  State<PulseGlow> createState() => _PulseGlowState();
}

class _PulseGlowState extends State<PulseGlow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.isActive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PulseGlow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isActive && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: widget.glowColor
                    .withValues(alpha: 0.1 + _controller.value * 0.3),
                blurRadius: 8 + _controller.value * 8,
                spreadRadius: _controller.value * 2,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
