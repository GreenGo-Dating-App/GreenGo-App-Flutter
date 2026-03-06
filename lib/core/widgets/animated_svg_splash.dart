import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import 'animated_svg_icon.dart';

/// Full-screen splash overlay shown when starting a game.
/// Displays an animated SVG icon with scale-in animation,
/// the game name, and a loading indicator.
/// Auto-dismisses after 2 seconds.
class AnimatedSvgSplash extends StatefulWidget {
  final String svgAssetPath;
  final String gameName;
  final VoidCallback onComplete;

  const AnimatedSvgSplash({
    super.key,
    required this.svgAssetPath,
    required this.gameName,
    required this.onComplete,
  });

  @override
  State<AnimatedSvgSplash> createState() => _AnimatedSvgSplashState();
}

class _AnimatedSvgSplashState extends State<AnimatedSvgSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _opacityAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();

    // Auto-dismiss after 2 seconds
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        widget.onComplete();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black87,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: AnimatedSvgIcon(
                  assetPath: widget.svgAssetPath,
                  width: 140,
                  height: 140,
                ),
              ),
              const SizedBox(height: 24),
              ScaleTransition(
                scale: _scaleAnimation,
                child: Text(
                  widget.gameName,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.richGold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
