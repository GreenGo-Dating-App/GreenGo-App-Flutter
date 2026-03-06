import 'dart:math';

import 'package:flutter/material.dart';

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
  }

  @override
  void didUpdateWidget(BombWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Shake more as time runs out
    if (widget.remainingSeconds <= 3 && widget.remainingSeconds > 0) {
      _shakeController.repeat(reverse: true);
      // Tick sound in last 3 seconds
      if (oldWidget.remainingSeconds != widget.remainingSeconds) {
        AppSoundService().play(AppSound.bombTick);
      }
    }

    // Explosion sound
    if (widget.hasExploded && !oldWidget.hasExploded) {
      AppSoundService().play(AppSound.bombExplode);
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Color get _fuseColor {
    final ratio = widget.totalSeconds > 0
        ? widget.remainingSeconds / widget.totalSeconds
        : 0.0;
    if (ratio > 0.5) return AppColors.successGreen;
    if (ratio > 0.25) return AppColors.warningAmber;
    return AppColors.errorRed;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.hasExploded) {
      return _buildExploded();
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_shakeAnimation, _pulseAnimation]),
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            widget.remainingSeconds <= 3 ? _shakeAnimation.value : 0,
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
          // Fuse
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_fuseColor, AppColors.warningAmber],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Bomb body
          Container(
            width: 120,
            height: 120,
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
                // Prompt text (letter/syllable)
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
        ],
      ),
    );
  }

  Widget _buildExploded() {
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Explosion circles
          for (int i = 0; i < 8; i++)
            Positioned(
              left: 70 + 50 * cos(i * pi / 4),
              top: 70 + 50 * sin(i * pi / 4),
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i % 2 == 0
                      ? AppColors.errorRed
                      : AppColors.warningAmber,
                ),
              ),
            ),
          // BOOM text
          const Text(
            'BOOM!',
            style: TextStyle(
              color: AppColors.errorRed,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
