/**
 * Achievement Unlock Dialog
 * Points 176-185: Celebration animation when achievement is unlocked
 */

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../domain/entities/achievement.dart';

class AchievementUnlockDialog extends StatefulWidget {
  final Achievement achievement;

  const AchievementUnlockDialog({
    Key? key,
    required this.achievement,
  }) : super(key: key);

  @override
  State<AchievementUnlockDialog> createState() =>
      _AchievementUnlockDialogState();
}

class _AchievementUnlockDialogState extends State<AchievementUnlockDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  late AnimationController _particleController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    // Scale animation
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    // Rotation animation
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(
        parent: _rotationController,
        curve: Curves.easeInOut,
      ),
    );

    // Particle animation
    _particleController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // Start animations
    _scaleController.forward();
    _rotationController.forward();
    _particleController.repeat();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rotationController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          // Particle effects
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                size: const Size(300, 400),
                painter: ParticlePainter(
                  progress: _particleController.value,
                  color: _getRarityColor(widget.achievement.rarity),
                ),
              );
            },
          ),

          // Main content
          Center(
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 300,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _getRarityColor(widget.achievement.rarity)
                          .withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'ACHIEVEMENT UNLOCKED!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Animated achievement icon
                    AnimatedBuilder(
                      animation: _rotationAnimation,
                      builder: (context, child) {
                        return Transform.rotate(
                          angle: _rotationAnimation.value,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _getRarityColor(widget.achievement.rarity),
                              boxShadow: [
                                BoxShadow(
                                  color: _getRarityColor(
                                          widget.achievement.rarity)
                                      .withOpacity(0.5),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Icon(
                              _getCategoryIcon(widget.achievement.category),
                              color: Colors.white,
                              size: 50,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Achievement name
                    Text(
                      widget.achievement.name,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _getRarityColor(widget.achievement.rarity),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),

                    // Achievement description
                    Text(
                      widget.achievement.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Rarity badge
                    Chip(
                      label: Text(
                        _getRarityName(widget.achievement.rarity),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      backgroundColor:
                          _getRarityColor(widget.achievement.rarity),
                    ),
                    const SizedBox(height: 16),

                    // Reward
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getRewardIcon(widget.achievement.rewardType),
                            color: Colors.amber.shade700,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '+${widget.achievement.rewardAmount} ${widget.achievement.rewardType}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Close button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _getRarityColor(widget.achievement.rarity),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Awesome!',
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
        ],
      ),
    );
  }

  IconData _getCategoryIcon(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.social:
        return Icons.people;
      case AchievementCategory.engagement:
        return Icons.favorite;
      case AchievementCategory.premium:
        return Icons.diamond;
      case AchievementCategory.milestones:
        return Icons.flag;
      case AchievementCategory.special:
        return Icons.star;
    }
  }

  IconData _getRewardIcon(String rewardType) {
    switch (rewardType) {
      case 'xp':
        return Icons.trending_up;
      case 'coins':
        return Icons.monetization_on;
      case 'badge':
        return Icons.military_tech;
      default:
        return Icons.card_giftcard;
    }
  }

  Color _getRarityColor(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return Colors.grey;
      case AchievementRarity.uncommon:
        return Colors.green;
      case AchievementRarity.rare:
        return Colors.blue;
      case AchievementRarity.epic:
        return Colors.purple;
      case AchievementRarity.legendary:
        return Colors.amber;
    }
  }

  String _getRarityName(AchievementRarity rarity) {
    switch (rarity) {
      case AchievementRarity.common:
        return 'COMMON';
      case AchievementRarity.uncommon:
        return 'UNCOMMON';
      case AchievementRarity.rare:
        return 'RARE';
      case AchievementRarity.epic:
        return 'EPIC';
      case AchievementRarity.legendary:
        return 'LEGENDARY';
    }
  }
}

/// Particle painter for celebration effect
class ParticlePainter extends CustomPainter {
  final double progress;
  final Color color;

  ParticlePainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;

    // Generate particles
    for (int i = 0; i < 20; i++) {
      final angle = (i / 20) * 2 * math.pi;
      final distance = progress * size.width / 2;

      final x = size.width / 2 + math.cos(angle) * distance;
      final y = size.height / 2 + math.sin(angle) * distance;

      paint.color = color.withOpacity(1 - progress);
      canvas.drawCircle(
        Offset(x, y),
        4 * (1 - progress),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
