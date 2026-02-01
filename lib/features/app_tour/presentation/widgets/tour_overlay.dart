import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/tour_step.dart';
import 'tour_tooltip.dart';

/// Full-screen overlay for the app tour with luxury black & gold styling
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
  late AnimationController _shimmerController;
  late AnimationController _particleController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _particleController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    )..repeat();

    _fadeController.forward();

    // Navigate to first tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onTabChange(TourStep.allSteps[0].tabIndex);
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _shimmerController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStepIndex < TourStep.allSteps.length - 1) {
      _fadeController.reverse().then((_) {
        setState(() {
          _currentStepIndex++;
        });
        widget.onTabChange(TourStep.allSteps[_currentStepIndex].tabIndex);
        _fadeController.forward();
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

    // Get localized strings for current step
    final title = _getLocalizedTitle(l10n, currentStep.titleKey);
    final description = _getLocalizedDescription(l10n, currentStep.descriptionKey);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Stack(
        children: [
          // Luxury black background with gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF0A0A0A),
                  Color(0xFF1A1A1A),
                  Color(0xFF0D0D0D),
                ],
              ),
            ),
          ),

          // Golden particle system
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                painter: _GoldenParticlePainter(
                  progress: _particleController.value,
                ),
                size: Size.infinite,
              );
            },
          ),

          // Glass blur effect overlay
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 2, sigmaY: 2),
            child: Container(
              color: Colors.black.withOpacity(0.3),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Luxury header with shimmer
                _buildLuxuryHeader(),

                const Spacer(flex: 1),

                // Tour tooltip with gold styling
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: TourTooltip(
                    title: title,
                    description: description,
                    icon: currentStep.icon,
                    accentColor: const Color(0xFFFFD700), // Gold for all steps
                    currentStep: _currentStepIndex,
                    totalSteps: steps.length,
                    onNext: _nextStep,
                    onSkip: _skipTour,
                    isLast: _currentStepIndex == steps.length - 1,
                  ),
                ),

                const Spacer(flex: 2),

                // Bottom nav indicator highlight
                _buildNavHighlight(currentStep),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLuxuryHeader() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: const [
                Color(0xFFFFD700),
                Color(0xFFFFF8DC),
                Color(0xFFFFD700),
                Color(0xFFB8860B),
                Color(0xFFFFD700),
              ],
              stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
              transform: _ShimmerTransform(_shimmerController.value),
            ).createShader(bounds);
          },
          child: const Text(
            'Welcome to GreenGo',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1.5,
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavHighlight(TourStep step) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFFFD700).withOpacity(0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD700).withOpacity(0.2),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withOpacity(0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.touch_app,
                  color: Colors.black,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Tap the ${_getTabName(step.id)} tab below',
                style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTabName(String stepId) {
    switch (stepId) {
      case 'discovery':
        return 'Discover';
      case 'matches':
        return 'Matches';
      case 'messages':
        return 'Messages';
      case 'shop':
        return 'Shop';
      case 'progress':
        return 'Progress';
      case 'profile':
        return 'Profile';
      default:
        return stepId;
    }
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

/// Shimmer transform for gradient animation
class _ShimmerTransform extends GradientTransform {
  final double progress;

  const _ShimmerTransform(this.progress);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(
      bounds.width * (progress * 2 - 1),
      0,
      0,
    );
  }
}

/// Golden particle painter for luxury effect
class _GoldenParticlePainter extends CustomPainter {
  final double progress;
  final math.Random _random = math.Random(42);

  _GoldenParticlePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 30; i++) {
      final baseX = _random.nextDouble() * size.width;
      final baseY = _random.nextDouble() * size.height;
      final particleProgress = (progress + i * 0.033) % 1.0;

      final x = baseX;
      final y = baseY - (particleProgress * size.height * 0.3);
      final opacity = (1 - particleProgress) * 0.6;
      final radius = 1.5 + _random.nextDouble() * 2;

      paint.color = Color(0xFFFFD700).withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);

      // Add glow effect
      paint.color = Color(0xFFFFD700).withOpacity(opacity * 0.3);
      canvas.drawCircle(Offset(x, y), radius * 2.5, paint);
    }
  }

  @override
  bool shouldRepaint(_GoldenParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
