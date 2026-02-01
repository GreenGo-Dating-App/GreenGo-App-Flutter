import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Enhancement #14: Super Like Animation
/// Star animation effect for super likes
class SuperLikeAnimation extends StatefulWidget {
  final Widget child;
  final bool trigger;
  final VoidCallback? onComplete;

  const SuperLikeAnimation({
    super.key,
    required this.child,
    required this.trigger,
    this.onComplete,
  });

  @override
  State<SuperLikeAnimation> createState() => _SuperLikeAnimationState();
}

class _SuperLikeAnimationState extends State<SuperLikeAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  final List<_StarParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 2.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
        _controller.reset();
      }
    });

    // Generate particles
    for (int i = 0; i < 12; i++) {
      _particles.add(_StarParticle(
        angle: (i * 30) * (3.14159 / 180),
        delay: i * 0.05,
      ));
    }
  }

  @override
  void didUpdateWidget(SuperLikeAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && !oldWidget.trigger) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        widget.child,
        if (_controller.isAnimating)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // Central star
                  Opacity(
                    opacity: _opacityAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: const Icon(
                        Icons.star,
                        color: AppColors.infoBlue,
                        size: 60,
                      ),
                    ),
                  ),
                  // Particle stars
                  ..._particles.map((particle) {
                    final progress = (_controller.value - particle.delay)
                        .clamp(0.0, 1.0);
                    final distance = 80 * progress;
                    return Transform.translate(
                      offset: Offset(
                        distance * particle.dx,
                        distance * particle.dy,
                      ),
                      child: Opacity(
                        opacity: (1 - progress).clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: 0.5 + (0.5 * (1 - progress)),
                          child: const Icon(
                            Icons.star,
                            color: AppColors.infoBlue,
                            size: 20,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          ),
      ],
    );
  }
}

class _StarParticle {
  final double angle;
  final double delay;
  late double dx;
  late double dy;

  _StarParticle({required this.angle, required this.delay}) {
    dx = 1.0 * (angle / 3.14159).abs().clamp(0.1, 1.0) *
        (angle > 3.14159 / 2 && angle < 3.14159 * 1.5 ? -1 : 1);
    dy = 1.0 * ((angle - 3.14159 / 2).abs() / 3.14159).clamp(0.1, 1.0) *
        (angle > 3.14159 ? 1 : -1);
  }
}

/// Super like button with animation
class SuperLikeButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isEnabled;
  final int? remainingCount;

  const SuperLikeButton({
    super.key,
    this.onPressed,
    this.isEnabled = true,
    this.remainingCount,
  });

  @override
  State<SuperLikeButton> createState() => _SuperLikeButtonState();
}

class _SuperLikeButtonState extends State<SuperLikeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
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
    return GestureDetector(
      onTap: widget.isEnabled ? widget.onPressed : null,
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: widget.isEnabled ? _pulseAnimation.value : 1.0,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: widget.isEnabled
                        ? const LinearGradient(
                            colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
                          )
                        : null,
                    color: widget.isEnabled ? null : AppColors.backgroundInput,
                    shape: BoxShape.circle,
                    boxShadow: widget.isEnabled
                        ? [
                            BoxShadow(
                              color: AppColors.infoBlue.withOpacity(0.4),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    Icons.star,
                    color: widget.isEnabled
                        ? Colors.white
                        : AppColors.textTertiary,
                    size: 30,
                  ),
                ),
              );
            },
          ),
          if (widget.remainingCount != null && widget.remainingCount! > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.richGold,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${widget.remainingCount}',
                  style: const TextStyle(
                    color: AppColors.deepBlack,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
