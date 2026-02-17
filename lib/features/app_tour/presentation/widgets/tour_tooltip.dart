import 'package:flutter/material.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

/// Clean tooltip widget for the app tour - no blur/shader effects
class TourTooltip extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final int currentStep;
  final int totalSteps;
  final VoidCallback onNext;
  final VoidCallback onSkip;
  final bool isLast;

  const TourTooltip({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.accentColor,
    required this.currentStep,
    required this.totalSteps,
    required this.onNext,
    required this.onSkip,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const goldColor = Color(0xFFFFD700);
    const darkGold = Color(0xFFB8860B);

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.75),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: goldColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon container - simple circle
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: goldColor.withOpacity(0.15),
              border: Border.all(
                color: goldColor.withOpacity(0.4),
                width: 1.5,
              ),
            ),
            child: Icon(
              icon,
              color: goldColor,
              size: 40,
            ),
          ),

          const SizedBox(height: 24),

          // Title - plain gold text, app default font
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: goldColor,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Description
          Text(
            description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.85),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 28),

          // Step indicators - simple dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(totalSteps, (index) {
              final isActive = index == currentStep;
              final isPast = index < currentStep;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: isActive ? 28 : 10,
                height: 10,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  color: isActive || isPast
                      ? goldColor
                      : Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(5),
                ),
              );
            }),
          ),

          const SizedBox(height: 28),

          // Buttons
          Row(
            children: [
              // Skip button
              Expanded(
                child: TextButton(
                  onPressed: onSkip,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                  ),
                  child: Text(
                    l10n.tourSkip,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Next/Done button with gold gradient
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [goldColor, darkGold],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ElevatedButton(
                    onPressed: onNext,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isLast ? l10n.tourDone : l10n.tourNext,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        if (!isLast) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            size: 20,
                            color: Colors.black,
                          ),
                        ],
                        if (isLast) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.check_rounded,
                            size: 20,
                            color: Colors.black,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
