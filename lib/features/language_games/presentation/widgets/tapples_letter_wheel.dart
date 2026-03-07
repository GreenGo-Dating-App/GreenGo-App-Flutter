import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';

/// Circular letter selector for Language Tapples.
/// 26 letters arranged around a circle with category info in the center.
/// Supports used-letter dimming, selected-letter glow, and entrance animation.
class TapplesLetterWheel extends StatefulWidget {
  final Set<String> usedLetters;
  final String? selectedLetter;
  final bool enabled;
  final ValueChanged<String>? onLetterTap;
  final String categoryName;
  final String categoryIcon;

  const TapplesLetterWheel({
    super.key,
    this.usedLetters = const {},
    this.selectedLetter,
    this.enabled = true,
    this.onLetterTap,
    this.categoryName = '',
    this.categoryIcon = '❓',
  });

  @override
  State<TapplesLetterWheel> createState() => _TapplesLetterWheelState();
}

class _TapplesLetterWheelState extends State<TapplesLetterWheel>
    with SingleTickerProviderStateMixin {
  static const _letters = [
    'A','B','C','D','E','F','G','H','I','J','K','L','M',
    'N','O','P','Q','R','S','T','U','V','W','X','Y','Z',
  ];

  late AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size.width * 0.75;
    final radius = size / 2;
    final center = Offset(radius, radius);
    final letterRadius = radius - 22;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Center: category icon + name
          Positioned.fill(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.categoryIcon,
                    style: const TextStyle(fontSize: 36),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.categoryName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Letters around the circle
          ..._letters.asMap().entries.map((entry) {
            final index = entry.key;
            final letter = entry.value;
            final angle = (2 * math.pi * index / _letters.length) - math.pi / 2;
            final x = center.dx + letterRadius * math.cos(angle) - 16;
            final y = center.dy + letterRadius * math.sin(angle) - 16;

            final isUsed = widget.usedLetters.contains(letter);
            final isSelected = letter == widget.selectedLetter;

            // Staggered entrance: each letter appears slightly after the previous
            final staggerDelay = index / _letters.length;

            return Positioned(
              left: x,
              top: y,
              child: AnimatedBuilder(
                animation: _entranceController,
                builder: (context, child) {
                  final t = ((_entranceController.value - staggerDelay) / (1 - staggerDelay))
                      .clamp(0.0, 1.0);
                  final scale = Curves.elasticOut.transform(t);
                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                child: GestureDetector(
                  onTap: (widget.enabled && !isUsed)
                      ? () {
                          HapticFeedback.selectionClick();
                          widget.onLetterTap?.call(letter);
                        }
                      : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? AppColors.richGold
                          : isUsed
                              ? AppColors.backgroundCard.withValues(alpha: 0.4)
                              : AppColors.backgroundCard,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.richGold
                            : isUsed
                                ? AppColors.divider.withValues(alpha: 0.3)
                                : AppColors.divider,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.richGold.withValues(alpha: 0.5),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          letter,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.backgroundDark
                                : isUsed
                                    ? AppColors.textTertiary.withValues(alpha: 0.4)
                                    : AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                        ),
                        // Strikethrough for used letters
                        if (isUsed)
                          Container(
                            width: 20,
                            height: 1.5,
                            color: AppColors.errorRed.withValues(alpha: 0.5),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
