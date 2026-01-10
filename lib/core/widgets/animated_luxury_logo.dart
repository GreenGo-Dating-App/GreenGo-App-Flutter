import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import '../constants/app_colors.dart';

class AnimatedLuxuryLogo extends StatefulWidget {
  final String assetPath;
  final double size;

  const AnimatedLuxuryLogo({
    super.key,
    required this.assetPath,
    this.size = 200,
  });

  @override
  State<AnimatedLuxuryLogo> createState() => _AnimatedLuxuryLogoState();
}

class _AnimatedLuxuryLogoState extends State<AnimatedLuxuryLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _twinkleController;
  late Animation<double> _twinkleAnimation;

  @override
  void initState() {
    super.initState();

    // Subtle twinkle effect (opacity pulse)
    _twinkleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _twinkleAnimation = Tween<double>(
      begin: 0.3,
      end: 0.7,
    ).animate(CurvedAnimation(
      parent: _twinkleController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _twinkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _twinkleController,
      builder: (context, child) {
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Base logo image
              Image.asset(
                widget.assetPath,
                width: widget.size,
                height: widget.size,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.goldGradient,
                    ),
                    child: const Icon(
                      Icons.favorite,
                      size: 70,
                      color: AppColors.deepBlack,
                    ),
                  );
                },
              ),

              // Subtle static sparkle overlay - only on colored parts
              Opacity(
                opacity: _twinkleAnimation.value,
                child: ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return const RadialGradient(
                      center: Alignment.center,
                      radius: 0.8,
                      colors: [
                        Colors.white,
                        Colors.transparent,
                      ],
                      stops: [0.3, 1.0],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.srcATop,
                  child: Image.asset(
                    widget.assetPath,
                    width: widget.size,
                    height: widget.size,
                    fit: BoxFit.contain,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
