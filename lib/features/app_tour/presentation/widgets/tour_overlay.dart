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
    _particleController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStepIndex < TourStep.allSteps.length - 1) {
      setState(() {
        _currentStepIndex++;
      });
      widget.onTabChange(TourStep.allSteps[_currentStepIndex].tabIndex);
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
          // Gradient blur: 0% at bottom to 20% at top
          Positioned.fill(
            child: Column(
              children: [
                // Top half: 20% blur
                Expanded(
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                      child: Container(
                        color: Colors.black.withOpacity(0.20),
                      ),
                    ),
                  ),
                ),
                // Bottom half: no blur, just light tint
                Expanded(
                  child: Container(
                    color: Colors.black.withOpacity(0.05),
                  ),
                ),
              ],
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

          // Main content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Header - same font style as "There's no others to see"
                const Text(
                  'Welcome to GreenGo',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),

                const Spacer(flex: 1),

                // Tour tooltip - no effects
                Padding(
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

                const Spacer(flex: 2),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
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
