import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import '../../../../core/constants/app_colors.dart';

/// Luxury glass-morphism tooltip widget for the app tour
class TourTooltip extends StatefulWidget {
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
  State<TourTooltip> createState() => _TourTooltipState();
}

class _TourTooltipState extends State<TourTooltip>
    with SingleTickerProviderStateMixin {
  late AnimationController _iconPulseController;
  late Animation<double> _iconPulse;

  @override
  void initState() {
    super.initState();
    _iconPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _iconPulse = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _iconPulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _iconPulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const goldColor = Color(0xFFFFD700);
    const darkGold = Color(0xFFB8860B);

    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: AnimatedBuilder(
          animation: _iconPulse,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.09),
                    Colors.white.withOpacity(0.04),
                    Colors.white.withOpacity(0.02),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
                border: Border.all(
                  color: AppColors.richGold.withOpacity(0.15 + 0.08 * _iconPulse.value),
                  width: 1.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                  BoxShadow(
                    color: AppColors.richGold.withOpacity(0.04 * _iconPulse.value),
                    blurRadius: 20,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: child,
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animated icon with pulsing glow
              AnimatedBuilder(
                animation: _iconPulse,
                builder: (context, child) {
                  return Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          goldColor,
                          goldColor.withOpacity(0.6),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: goldColor.withOpacity(0.3 * _iconPulse.value),
                          blurRadius: 20 + (10 * _iconPulse.value),
                          spreadRadius: 2 * _iconPulse.value,
                        ),
                      ],
                    ),
                    child: Icon(
                      widget.icon,
                      color: Colors.black,
                      size: 42,
                    ),
                  );
                },
              ),

              const SizedBox(height: 28),

              // Title with gold shimmer
              Text(
                widget.title,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Poppins',
                  letterSpacing: -0.3,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Gold accent line
              Container(
                width: 40,
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
              ),

              const SizedBox(height: 16),

              // Description
              Text(
                widget.description,
                style: TextStyle(
                  fontSize: 16,
                  fontFamily: 'Poppins',
                  color: Colors.white.withOpacity(0.75),
                  height: 1.6,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 28),

              // Step indicators with animated active dot
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.totalSteps, (index) {
                  final isActive = index == widget.currentStep;
                  final isPast = index < widget.currentStep;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    width: isActive ? 32 : 10,
                    height: 10,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      gradient: isActive
                          ? const LinearGradient(
                              colors: [goldColor, darkGold],
                            )
                          : null,
                      color: isActive
                          ? null
                          : isPast
                              ? goldColor.withOpacity(0.6)
                              : Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(5),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: goldColor.withOpacity(0.4),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                  );
                }),
              ),

              const SizedBox(height: 28),

              // Buttons
              Row(
                children: [
                  // Skip button - glass style
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: TextButton(
                          onPressed: widget.onSkip,
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.white.withOpacity(0.06),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: AppColors.richGold.withOpacity(0.2),
                              ),
                            ),
                          ),
                          child: Text(
                            l10n.tourSkip,
                            style: TextStyle(
                              color: AppColors.richGold.withOpacity(0.8),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Next/Done button with gold gradient and glow
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [goldColor, AppColors.richGold, darkGold],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.richGold.withOpacity(0.4),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: widget.onNext,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.isLast ? l10n.tourDone : l10n.tourNext,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Poppins',
                                color: Colors.black,
                                letterSpacing: 0.5,
                              ),
                            ),
                            if (!widget.isLast) ...[
                              const SizedBox(width: 8),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 20,
                                color: Colors.black,
                              ),
                            ],
                            if (widget.isLast) ...[
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
        ),
      ),
    );
  }
}
