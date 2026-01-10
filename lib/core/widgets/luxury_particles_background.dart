import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../constants/app_colors.dart';

class LuxuryParticlesBackground extends StatefulWidget {
  final Widget child;
  const LuxuryParticlesBackground({super.key, required this.child});

  @override
  State<LuxuryParticlesBackground> createState() =>
      _LuxuryParticlesBackgroundState();
}

class _LuxuryParticlesBackgroundState extends State<LuxuryParticlesBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];
  final int _particleCount = 50;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    // Initialize particles
    for (int i = 0; i < _particleCount; i++) {
      _particles.add(Particle());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Gradient background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.deepBlack,
                AppColors.charcoal,
                AppColors.deepBlack,
              ],
              stops: [0.0, 0.5, 1.0],
            ),
          ),
        ),
        // Animated particles
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: ParticlesPainter(
                particles: _particles,
                animationValue: _controller.value,
              ),
              size: Size.infinite,
            );
          },
        ),
        // Content
        widget.child,
      ],
    );
  }
}

class Particle {
  late double x;
  late double y;
  late double size;
  late double speedX;
  late double speedY;
  late double opacity;
  late Color color;
  late double pulsePhase;
  late double sparkleSpeed;
  late double rotation;
  late double rotationSpeed;

  Particle() {
    final random = math.Random();
    x = random.nextDouble();
    y = -random.nextDouble() * 0.1; // Start above screen
    size = random.nextDouble() * 5 + 2; // 2-7 pixels (larger for sparkle)
    speedX = (random.nextDouble() - 0.5) * 0.002; // Gentle horizontal drift
    speedY = random.nextDouble() * 0.003 + 0.001; // Fall speed (0.001-0.004)
    opacity = random.nextDouble() * 0.6 + 0.4; // 0.4-1.0 opacity (brighter)
    pulsePhase = random.nextDouble() * 2 * math.pi;
    sparkleSpeed = random.nextDouble() * 3 + 2; // Fast sparkle (2-5x speed)
    rotation = random.nextDouble() * 2 * math.pi;
    rotationSpeed = (random.nextDouble() - 0.5) * 0.05; // Rotation speed

    // Bright gold particles with sparkle variation
    final colorVariation = random.nextInt(4);
    color = colorVariation == 0
        ? AppColors.accentGold // Bright gold
        : colorVariation == 1
            ? AppColors.richGold
            : colorVariation == 2
                ? const Color(0xFFFFE55C) // Light gold
                : const Color(0xFFFFFACD); // Pale gold
  }

  void update() {
    // Horizontal drift
    x += speedX;
    // Fall down
    y += speedY;
    // Rotate
    rotation += rotationSpeed;

    // Wrap horizontally
    if (x < -0.1) x = 1.1;
    if (x > 1.1) x = -0.1;

    // Reset to top when reaches bottom
    if (y > 1.1) {
      y = -0.1;
      x = math.Random().nextDouble();
    }
  }

  double getSparkleOpacity(double animationValue) {
    // Fast sparkle effect using sine wave
    final sparkle = math.sin(animationValue * 2 * math.pi * sparkleSpeed + pulsePhase);
    // Map from [-1, 1] to [0.3, 1.0] for bright sparkle
    final sparkleValue = (sparkle + 1) / 2; // Now [0, 1]
    return opacity * (0.3 + sparkleValue * 0.7);
  }

  double getSparkleScale(double animationValue) {
    // Scale pulse for sparkle effect
    final pulse = math.sin(animationValue * 2 * math.pi * sparkleSpeed + pulsePhase);
    return 0.8 + pulse * 0.3; // Scale between 0.5 and 1.1
  }
}

class ParticlesPainter extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;

  ParticlesPainter({
    required this.particles,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      particle.update();

      final sparkleOpacity = particle.getSparkleOpacity(animationValue);
      final sparkleScale = particle.getSparkleScale(animationValue);

      final position = Offset(
        particle.x * size.width,
        particle.y * size.height,
      );

      // Save canvas state for rotation
      canvas.save();
      canvas.translate(position.dx, position.dy);
      canvas.rotate(particle.rotation);

      // Sparkle glow (larger, more intense)
      final glowPaint = Paint()
        ..color = particle.color.withOpacity(sparkleOpacity * 0.4)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, particle.size * 2 * sparkleScale);
      canvas.drawCircle(Offset.zero, particle.size * 3 * sparkleScale, glowPaint);

      // Inner glow
      final innerGlowPaint = Paint()
        ..color = particle.color.withOpacity(sparkleOpacity * 0.6)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, particle.size * sparkleScale);
      canvas.drawCircle(Offset.zero, particle.size * 1.5 * sparkleScale, innerGlowPaint);

      // Core sparkle (star-shaped)
      final corePaint = Paint()
        ..color = particle.color.withOpacity(sparkleOpacity)
        ..style = PaintingStyle.fill;

      // Draw diamond/star shape for sparkle effect
      final path = Path();
      final scaledSize = particle.size * sparkleScale;

      // Create 4-pointed star
      path.moveTo(0, -scaledSize * 1.5); // Top point
      path.lineTo(scaledSize * 0.3, 0); // Right-center
      path.lineTo(scaledSize * 1.5, 0); // Right point
      path.lineTo(0, scaledSize * 0.3); // Center-bottom
      path.lineTo(0, scaledSize * 1.5); // Bottom point
      path.lineTo(-scaledSize * 0.3, 0); // Left-center
      path.lineTo(-scaledSize * 1.5, 0); // Left point
      path.lineTo(0, -scaledSize * 0.3); // Center-top
      path.close();

      canvas.drawPath(path, corePaint);

      // Bright center
      final centerPaint = Paint()
        ..color = Colors.white.withOpacity(sparkleOpacity * 0.8)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset.zero, scaledSize * 0.5, centerPaint);

      canvas.restore();

      // Draw light trails between nearby falling particles
      for (var other in particles) {
        if (particle == other) continue;

        final distance = math.sqrt(
          math.pow(particle.x - other.x, 2) +
              math.pow(particle.y - other.y, 2),
        );

        // Only connect particles that are close and falling together
        if (distance < 0.12 && (particle.y - other.y).abs() < 0.1) {
          final linePaint = Paint()
            ..color = AppColors.accentGold.withOpacity(
              (1 - distance / 0.12) * 0.15 * sparkleOpacity,
            )
            ..strokeWidth = 0.8;

          canvas.drawLine(
            position,
            Offset(
              other.x * size.width,
              other.y * size.height,
            ),
            linePaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant ParticlesPainter oldDelegate) {
    return true;
  }
}
