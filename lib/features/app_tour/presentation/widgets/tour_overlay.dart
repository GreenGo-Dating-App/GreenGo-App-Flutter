import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/tour_step.dart';
import 'tour_tooltip.dart';

/// Full-screen overlay for the app tour with luxury animated styling
class TourOverlay extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onSkip;
  final Function(int) onTabChange;

  const TourOverlay({
    super.key,
    required this.onComplete,
    required this.onSkip,
    required this.onTabChange,
  });

  @override
  State<TourOverlay> createState() => _TourOverlayState();
}

class _TourOverlayState extends State<TourOverlay>
    with TickerProviderStateMixin {
  int _currentStepIndex = 0;
  late AnimationController _fadeController;
  late AnimationController _particleController;
  late AnimationController _shimmerController;
  late AnimationController _floatController;
  late AnimationController _pulseController;
  late AnimationController _contentController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _floatAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _contentSlide;
  late Animation<double> _contentFade;

  // Random sparkle positions
  late List<_SparkleParticle> _sparkles;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _particleController = AnimationController(
      duration: const Duration(milliseconds: 6000),
      vsync: this,
    )..repeat();

    // Shimmer animation for the title
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _shimmerAnimation = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    // Floating animation for orbs
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Pulsing glow
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Content entry animation
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _contentSlide = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOutCubic),
    );
    _contentFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
    );

    // Generate sparkle particles
    final rng = math.Random(42);
    _sparkles = List.generate(30, (i) => _SparkleParticle(
      x: rng.nextDouble(),
      y: rng.nextDouble(),
      size: 1.0 + rng.nextDouble() * 2.5,
      speed: 0.3 + rng.nextDouble() * 0.7,
      phase: rng.nextDouble() * math.pi * 2,
    ));

    _fadeController.forward();
    _contentController.forward();

    // Navigate to first tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onTabChange(TourStep.allSteps[0].tabIndex);
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _particleController.dispose();
    _shimmerController.dispose();
    _floatController.dispose();
    _pulseController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStepIndex < TourStep.allSteps.length - 1) {
      // Animate out, change step, animate in
      _contentController.reverse().then((_) {
        setState(() {
          _currentStepIndex++;
        });
        widget.onTabChange(TourStep.allSteps[_currentStepIndex].tabIndex);
        _contentController.forward();
      });
    } else {
      _completeTour();
    }
  }

  void _completeTour() {
    _fadeController.reverse().then((_) {
      widget.onComplete();
    });
  }

  void _skipTour() {
    _fadeController.reverse().then((_) {
      widget.onSkip();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final steps = TourStep.allSteps;
    final currentStep = steps[_currentStepIndex];

    final title = _getLocalizedTitle(l10n, currentStep.titleKey);
    final description = _getLocalizedDescription(l10n, currentStep.descriptionKey);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Stack(
        children: [
          // Animated gradient background
          _buildAnimatedBackground(),

          // Floating gold orbs
          _buildFloatingOrbs(),

          // Sparkle particles
          _buildSparkleParticles(),

          // Diagonal luxury pattern
          _buildPatternOverlay(),

          // Blur overlay
          Positioned.fill(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(
                  color: Colors.black.withOpacity(0.15),
                ),
              ),
            ),
          ),

          // Vignette
          _buildVignetteOverlay(),

          // Main content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 32),

                // Shimmer title
                AnimatedBuilder(
                  animation: Listenable.merge([_shimmerAnimation, _pulseAnimation]),
                  builder: (context, child) {
                    return Container(
                      foregroundDecoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.richGold.withOpacity(0.06 * _pulseAnimation.value),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ShaderMask(
                        shaderCallback: (bounds) {
                          return LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: const [
                              Color(0xFFFFD700),
                              Color(0xFFFFF8DC),
                              Color(0xFFFFE55C),
                              AppColors.richGold,
                              Color(0xFFFFD700),
                            ],
                            stops: [
                              0.0,
                              (_shimmerAnimation.value - 0.1).clamp(0.0, 1.0),
                              _shimmerAnimation.value.clamp(0.0, 1.0),
                              (_shimmerAnimation.value + 0.2).clamp(0.0, 1.0),
                              1.0,
                            ],
                          ).createShader(bounds);
                        },
                        child: const Text(
                          'Welcome to GreenGo',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontFamily: 'Poppins',
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Animated gold accent line
                const SizedBox(height: 8),
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 40 + (20 * _pulseAnimation.value),
                      height: 2,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(1),
                        gradient: LinearGradient(
                          colors: [
                            AppColors.richGold.withOpacity(0.8),
                            AppColors.richGold.withOpacity(0.2),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const Spacer(flex: 1),

                // Animated tooltip content
                AnimatedBuilder(
                  animation: Listenable.merge([_contentSlide, _contentFade]),
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _contentSlide.value),
                      child: Opacity(
                        opacity: _contentFade.value,
                        child: child,
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: TourTooltip(
                      title: title,
                      description: description,
                      icon: currentStep.icon,
                      accentColor: const Color(0xFFFFD700),
                      currentStep: _currentStepIndex,
                      totalSteps: steps.length,
                      onNext: _nextStep,
                      onSkip: _skipTour,
                      isLast: _currentStepIndex == steps.length - 1,
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.black,
                Color.lerp(
                  const Color(0xFF0A0A0A),
                  const Color(0xFF121208),
                  _floatAnimation.value,
                )!,
                Color.lerp(
                  const Color(0xFF1A1A1A),
                  const Color(0xFF0D0D0D),
                  _floatAnimation.value,
                )!,
                const Color(0xFF050505),
                Colors.black,
              ],
              stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFloatingOrbs() {
    return AnimatedBuilder(
      animation: Listenable.merge([_floatAnimation, _pulseAnimation]),
      builder: (context, child) {
        final screenW = MediaQuery.of(context).size.width;
        final screenH = MediaQuery.of(context).size.height;
        return Stack(
          children: [
            // Large gold orb - top right
            Positioned(
              top: 60 + (_floatAnimation.value * 25),
              right: -60,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.richGold.withOpacity(0.18 * _pulseAnimation.value),
                      AppColors.richGold.withOpacity(0.08 * _pulseAnimation.value),
                      AppColors.richGold.withOpacity(0.02),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.3, 0.6, 1.0],
                  ),
                ),
              ),
            ),
            // Small gold orb - bottom left
            Positioned(
              bottom: 120 - (_floatAnimation.value * 20),
              left: -40,
              child: Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.richGold.withOpacity(0.12 * _pulseAnimation.value),
                      AppColors.richGold.withOpacity(0.04),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            // Medium accent orb
            Positioned(
              top: screenH * 0.35 + (_floatAnimation.value * 15),
              left: screenW * 0.55 + (_floatAnimation.value * 12),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFB8860B).withOpacity(0.10 * _pulseAnimation.value),
                      const Color(0xFFB8860B).withOpacity(0.03),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSparkleParticles() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        final screenW = MediaQuery.of(context).size.width;
        final screenH = MediaQuery.of(context).size.height;
        return CustomPaint(
          size: Size(screenW, screenH),
          painter: _SparklePainter(
            sparkles: _sparkles,
            progress: _particleController.value,
            pulseValue: _pulseAnimation.value,
          ),
        );
      },
    );
  }

  Widget _buildPatternOverlay() {
    return Positioned.fill(
      child: CustomPaint(
        painter: _LuxuryPatternPainter(
          color: AppColors.richGold.withOpacity(0.015),
        ),
      ),
    );
  }

  Widget _buildVignetteOverlay() {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 1.2,
              colors: [
                Colors.transparent,
                Colors.transparent,
                Colors.black.withOpacity(0.4),
              ],
              stops: const [0.0, 0.6, 1.0],
            ),
          ),
        ),
      ),
    );
  }

  String _getLocalizedTitle(AppLocalizations l10n, String key) {
    switch (key) {
      case 'tourDiscoveryTitle':
        return l10n.tourDiscoveryTitle;
      case 'tourMatchesTitle':
        return l10n.tourMatchesTitle;
      case 'tourMessagesTitle':
        return l10n.tourMessagesTitle;
      case 'tourShopTitle':
        return l10n.tourShopTitle;
      case 'tourProgressTitle':
        return l10n.tourProgressTitle;
      case 'tourProfileTitle':
        return l10n.tourProfileTitle;
      default:
        return key;
    }
  }

  String _getLocalizedDescription(AppLocalizations l10n, String key) {
    switch (key) {
      case 'tourDiscoveryDescription':
        return l10n.tourDiscoveryDescription;
      case 'tourMatchesDescription':
        return l10n.tourMatchesDescription;
      case 'tourMessagesDescription':
        return l10n.tourMessagesDescription;
      case 'tourShopDescription':
        return l10n.tourShopDescription;
      case 'tourProgressDescription':
        return l10n.tourProgressDescription;
      case 'tourProfileDescription':
        return l10n.tourProfileDescription;
      default:
        return key;
    }
  }
}

/// Sparkle particle data
class _SparkleParticle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double phase;

  const _SparkleParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.phase,
  });
}

/// Custom painter for sparkle particles
class _SparklePainter extends CustomPainter {
  final List<_SparkleParticle> sparkles;
  final double progress;
  final double pulseValue;

  _SparklePainter({
    required this.sparkles,
    required this.progress,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final sparkle in sparkles) {
      final t = (progress * sparkle.speed + sparkle.phase) % 1.0;
      final alpha = math.sin(t * math.pi) * 0.7 * pulseValue;
      if (alpha <= 0) continue;

      final paint = Paint()
        ..color = const Color(0xFFFFD700).withOpacity(alpha.clamp(0.0, 0.6))
        ..style = PaintingStyle.fill;

      final dx = sparkle.x * size.width;
      final dy = (sparkle.y - t * 0.15) * size.height;
      if (dy < 0 || dy > size.height) continue;

      final s = sparkle.size * (0.5 + 0.5 * pulseValue);
      canvas.drawCircle(Offset(dx, dy), s * 0.6, paint);

      final glowPaint = Paint()
        ..color = const Color(0xFFFFD700).withOpacity(alpha * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(Offset(dx, dy), s * 1.5, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) => true;
}

/// Luxury diagonal pattern painter
class _LuxuryPatternPainter extends CustomPainter {
  final Color color;

  _LuxuryPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const spacing = 50.0;

    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }

    final dotPaint = Paint()
      ..color = color.withOpacity(0.4)
      ..style = PaintingStyle.fill;

    for (double x = 0; x < size.width; x += spacing * 2) {
      for (double y = 0; y < size.height; y += spacing * 2) {
        canvas.drawCircle(Offset(x, y), 1, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
