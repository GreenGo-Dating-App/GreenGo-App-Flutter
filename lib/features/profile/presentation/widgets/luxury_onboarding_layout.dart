import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// A luxury onboarding layout with glass morphism effects, gradients, and patterns.
/// Wraps onboarding screens to provide a consistent premium feel.
class LuxuryOnboardingLayout extends StatefulWidget {
  final Widget child;
  final String title;
  final String subtitle;
  final Widget? progressBar;
  final VoidCallback? onBack;
  final bool showBackButton;

  const LuxuryOnboardingLayout({
    super.key,
    required this.child,
    required this.title,
    required this.subtitle,
    this.progressBar,
    this.onBack,
    this.showBackButton = true,
  });

  @override
  State<LuxuryOnboardingLayout> createState() => _LuxuryOnboardingLayoutState();
}

class _LuxuryOnboardingLayoutState extends State<LuxuryOnboardingLayout>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;
  late AnimationController _floatController;
  late AnimationController _pulseController;
  late AnimationController _sparkleController;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _floatAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _sparkleAnimation;

  // Random sparkle positions generated once
  late List<_SparkleParticle> _sparkles;

  @override
  void initState() {
    super.initState();

    // Shimmer animation for the title
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _shimmerAnimation = Tween<double>(begin: -1, end: 2).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    // Floating animation for decorative elements
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);

    _floatAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );

    // Pulsing glow animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Sparkle animation
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    _sparkleAnimation = Tween<double>(begin: 0, end: 1).animate(_sparkleController);

    // Generate random sparkle particles
    final rng = math.Random(42);
    _sparkles = List.generate(25, (i) => _SparkleParticle(
      x: rng.nextDouble(),
      y: rng.nextDouble(),
      size: 1.0 + rng.nextDouble() * 2.5,
      speed: 0.3 + rng.nextDouble() * 0.7,
      phase: rng.nextDouble() * math.pi * 2,
    ));
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    _floatController.dispose();
    _pulseController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Animated gradient background
          _buildAnimatedBackground(),

          // Floating particles/orbs
          _buildFloatingOrbs(),

          // Sparkle particles
          _buildSparkleParticles(),

          // Diagonal pattern overlay
          _buildPatternOverlay(),

          // 20% background blur overlay
          Positioned.fill(
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: Container(
                  color: Colors.black.withOpacity(0.05),
                ),
              ),
            ),
          ),

          // Vignette overlay
          _buildVignetteOverlay(),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // App bar with glass effect
                _buildGlassAppBar(context),

                // Header section with title
                _buildHeader(context),

                // Content area
                Expanded(child: widget.child),
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
            // Large gold orb - top right with pulsing glow
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

            // Medium accent orb - center right, slow drift
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

            // Tiny warm orb - top left
            Positioned(
              top: screenH * 0.15 - (_floatAnimation.value * 10),
              left: screenW * 0.1 + (_floatAnimation.value * 8),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFDAA520).withOpacity(0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Subtle warm orb - mid bottom
            Positioned(
              bottom: screenH * 0.25 + (_floatAnimation.value * 12),
              right: screenW * 0.15,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFFD700).withOpacity(0.06 * _pulseAnimation.value),
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
      animation: _sparkleAnimation,
      builder: (context, child) {
        final screenW = MediaQuery.of(context).size.width;
        final screenH = MediaQuery.of(context).size.height;
        return CustomPaint(
          size: Size(screenW, screenH),
          painter: _SparklePainter(
            sparkles: _sparkles,
            progress: _sparkleAnimation.value,
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

  Widget _buildGlassAppBar(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withOpacity(0.06),
                    Colors.white.withOpacity(0.02),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.richGold.withOpacity(0.08 * _pulseAnimation.value),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  if (widget.showBackButton)
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.06),
                        border: Border.all(
                          color: AppColors.richGold.withOpacity(0.15 + 0.1 * _pulseAnimation.value),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.richGold.withOpacity(0.05 * _pulseAnimation.value),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: widget.onBack ?? () => Navigator.of(context).pop(),
                      ),
                    )
                  else
                    const SizedBox(width: 48),

                  // Progress bar in center
                  if (widget.progressBar != null)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: widget.progressBar!,
                      ),
                    )
                  else
                    const Expanded(child: SizedBox()),

                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Animated shimmer title with glow
          AnimatedBuilder(
            animation: Listenable.merge([_shimmerAnimation, _pulseAnimation]),
            builder: (context, child) {
              return Container(
                foregroundDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
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
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 10),

          // Animated gold accent line
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

          const SizedBox(height: 10),

          Text(
            widget.subtitle,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.55),
              letterSpacing: 0.3,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
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
      // Fade in-out: sparkle appears and disappears
      final alpha = math.sin(t * math.pi) * 0.7 * pulseValue;
      if (alpha <= 0) continue;

      final paint = Paint()
        ..color = const Color(0xFFFFD700).withOpacity(alpha.clamp(0.0, 0.6))
        ..style = PaintingStyle.fill;

      // Slow upward drift
      final dx = sparkle.x * size.width;
      final dy = (sparkle.y - t * 0.15) * size.height;
      if (dy < 0 || dy > size.height) continue;

      // Draw cross-shaped sparkle
      final s = sparkle.size * (0.5 + 0.5 * pulseValue);
      canvas.drawCircle(Offset(dx, dy), s * 0.6, paint);

      // Tiny glow
      final glowPaint = Paint()
        ..color = const Color(0xFFFFD700).withOpacity(alpha * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      canvas.drawCircle(Offset(dx, dy), s * 1.5, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklePainter oldDelegate) => true;
}

/// Luxury glass card for content sections
class LuxuryGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const LuxuryGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: padding ?? const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.white.withOpacity(0.05),
                ],
              ),
              border: Border.all(
                color: AppColors.richGold.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Luxury button with gradient and glass effect
class LuxuryButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSecondary;

  const LuxuryButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
  });

  @override
  State<LuxuryButton> createState() => _LuxuryButtonState();
}

class _LuxuryButtonState extends State<LuxuryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.isLoading ? null : widget.onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.identity()
          ..scale(_isPressed ? 0.98 : 1.0),
        margin: const EdgeInsets.symmetric(horizontal: 24),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: widget.isSecondary
                    ? null
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFFFFD700),
                          AppColors.richGold,
                          const Color(0xFFB8860B),
                        ],
                      ),
                color: widget.isSecondary
                    ? Colors.white.withOpacity(0.1)
                    : null,
                border: widget.isSecondary
                    ? Border.all(
                        color: AppColors.richGold.withOpacity(0.5),
                        width: 1.5,
                      )
                    : null,
                boxShadow: widget.isSecondary
                    ? null
                    : [
                        BoxShadow(
                          color: AppColors.richGold.withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
              ),
              child: Center(
                child: widget.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        widget.text,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: widget.isSecondary
                              ? AppColors.richGold
                              : Colors.black,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Luxury text field with glass effect
class LuxuryTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;

  const LuxuryTextField({
    super.key,
    this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.suffix,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withOpacity(0.08),
                Colors.white.withOpacity(0.03),
              ],
            ),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            maxLines: maxLines,
            validator: validator,
            onChanged: onChanged,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              labelStyle: TextStyle(
                color: Colors.white.withOpacity(0.6),
              ),
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.3),
              ),
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon, color: AppColors.richGold)
                  : null,
              suffix: suffix,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: AppColors.richGold.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Luxury selection chip
class LuxuryChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final IconData? icon;

  const LuxuryChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: isSelected
              ? const LinearGradient(
                  colors: [Color(0xFFFFD700), AppColors.richGold],
                )
              : null,
          color: isSelected ? null : Colors.white.withOpacity(0.05),
          border: Border.all(
            color: isSelected
                ? AppColors.richGold
                : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.richGold.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 18,
                color: isSelected ? Colors.black : Colors.white.withOpacity(0.7),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.black : Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for luxury diagonal pattern
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

    // Draw diagonal lines
    for (double i = -size.height; i < size.width + size.height; i += spacing) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }

    // Draw small dots at intersections
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
