/**
 * Level Up Animation Widget
 * Point 189: Animated level-up celebration with gold particles
 */

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../domain/entities/user_level.dart';

class LevelUpAnimation extends StatefulWidget {
  final int newLevel;
  final List<LevelReward> rewards;
  final bool isVIP;

  const LevelUpAnimation({
    Key? key,
    required this.newLevel,
    this.rewards = const [],
    this.isVIP = false,
  }) : super(key: key);

  @override
  State<LevelUpAnimation> createState() => _LevelUpAnimationState();
}

class _LevelUpAnimationState extends State<LevelUpAnimation>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _particleController;
  late AnimationController _rayController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Scale and fade animation
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: const Interval(0, 0.5, curve: Curves.easeIn),
      ),
    );

    // Gold particle animation
    _particleController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    // Ray animation (spinning rays of light)
    _rayController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );

    // Start animations
    _scaleController.forward();
    _particleController.repeat();
    _rayController.repeat();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _particleController.dispose();
    _rayController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          // Spinning rays
          AnimatedBuilder(
            animation: _rayController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rayController.value * 2 * math.pi,
                child: CustomPaint(
                  size: const Size(400, 400),
                  painter: RayPainter(
                    color: widget.isVIP
                        ? const Color(0xFFFFD700)
                        : Colors.blue.shade400,
                  ),
                ),
              );
            },
          ),

          // Gold particles
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(400, 400),
                painter: GoldParticlePainter(
                  progress: _particleController.value,
                ),
              );
            },
          ),

          // Main content
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 320,
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: widget.isVIP
                          ? [
                              const Color(0xFFFFD700),
                              const Color(0xFFFFA500),
                            ]
                          : [
                              Colors.blue.shade400,
                              Colors.blue.shade600,
                            ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: widget.isVIP
                            ? const Color(0xFFFFD700).withOpacity(0.5)
                            : Colors.blue.withOpacity(0.5),
                        blurRadius: 30,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Level Up Text
                      const Text(
                        'LEVEL UP!',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Level number with glow effect
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.8),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${widget.newLevel}',
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: widget.isVIP
                                      ? const Color(0xFFFFD700)
                                      : Colors.blue.shade600,
                                ),
                              ),
                              if (widget.isVIP)
                                const Icon(
                                  Icons.diamond,
                                  color: Color(0xFFFFD700),
                                  size: 24,
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // VIP Badge (Point 193)
                      if (widget.isVIP) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '👑',
                                style: TextStyle(fontSize: 20),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'VIP STATUS UNLOCKED!',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFFFD700),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Rewards (Point 190)
                      if (widget.rewards.isNotEmpty) ...[
                        const Text(
                          'REWARDS',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...widget.rewards.map((reward) {
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getRewardIcon(reward.type),
                                  size: 20,
                                  color: Colors.amber.shade700,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _getRewardText(reward),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 16),
                      ],

                      // Continue button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: widget.isVIP
                                ? const Color(0xFFFFD700)
                                : Colors.blue.shade600,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getRewardIcon(String type) {
    switch (type) {
      case 'coins':
        return Icons.monetization_on;
      case 'frame':
        return Icons.crop_square;
      case 'badge':
        return Icons.military_tech;
      case 'theme':
        return Icons.palette;
      case 'feature':
        return Icons.star;
      default:
        return Icons.card_giftcard;
    }
  }

  String _getRewardText(LevelReward reward) {
    if (reward.amount != null && reward.amount! > 0) {
      return '+${reward.amount} ${reward.type}';
    }
    return reward.itemId ?? 'New ${reward.type}';
  }
}

/// Gold particle painter
class GoldParticlePainter extends CustomPainter {
  final double progress;

  GoldParticlePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xFFFFD700);

    // Generate 30 gold particles
    for (int i = 0; i < 30; i++) {
      final angle = (i / 30) * 2 * math.pi;
      final distance = progress * size.width / 2;
      final sineWave = math.sin(progress * 4 * math.pi + i) * 20;

      final x = size.width / 2 + math.cos(angle) * distance + sineWave;
      final y = size.height / 2 + math.sin(angle) * distance;

      // Particle opacity fades out
      paint.color = Color(0xFFFFD700).withOpacity((1 - progress) * 0.8);

      // Varying particle sizes
      final particleSize = 3 + math.sin(i) * 2;

      canvas.drawCircle(
        Offset(x, y),
        particleSize * (1 - progress * 0.5),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(GoldParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Ray painter for spinning light rays
class RayPainter extends CustomPainter {
  final Color color;

  RayPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);

    // Draw 8 rays
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * math.pi;

      final path = Path();
      path.moveTo(center.dx, center.dy);

      final rayLength = size.width / 2;
      final rayWidth = 20.0;

      path.lineTo(
        center.dx + math.cos(angle - 0.1) * rayLength,
        center.dy + math.sin(angle - 0.1) * rayLength,
      );
      path.lineTo(
        center.dx + math.cos(angle + 0.1) * rayLength,
        center.dy + math.sin(angle + 0.1) * rayLength,
      );
      path.close();

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(RayPainter oldDelegate) => false;
}
