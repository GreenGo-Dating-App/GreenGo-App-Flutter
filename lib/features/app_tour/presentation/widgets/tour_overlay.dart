import 'package:flutter/material.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/tour_step.dart';
import 'tour_tooltip.dart';

/// Full-screen overlay for the app tour
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
    with SingleTickerProviderStateMixin {
  int _currentStepIndex = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _animationController.forward();

    // Navigate to first tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onTabChange(TourStep.allSteps[0].tabIndex);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStepIndex < TourStep.allSteps.length - 1) {
      _animationController.reverse().then((_) {
        setState(() {
          _currentStepIndex++;
        });
        widget.onTabChange(TourStep.allSteps[_currentStepIndex].tabIndex);
        _animationController.forward();
      });
    } else {
      _completeTour();
    }
  }

  void _completeTour() {
    _animationController.reverse().then((_) {
      widget.onComplete();
    });
  }

  void _skipTour() {
    _animationController.reverse().then((_) {
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
      child: Container(
        color: Colors.black.withOpacity(0.85),
        child: SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Tour tooltip
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: TourTooltip(
                  title: title,
                  description: description,
                  icon: currentStep.icon,
                  accentColor: currentStep.accentColor,
                  currentStep: _currentStepIndex,
                  totalSteps: steps.length,
                  onNext: _nextStep,
                  onSkip: _skipTour,
                  isLast: _currentStepIndex == steps.length - 1,
                ),
              ),

              const Spacer(flex: 3),

              // Bottom nav indicator highlight
              _buildNavHighlight(currentStep),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavHighlight(TourStep step) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: step.accentColor.withOpacity(0.5),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.touch_app,
            color: step.accentColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Tap the ${_getTabName(step.id)} tab below',
            style: TextStyle(
              color: step.accentColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
