import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../profile/domain/entities/profile.dart';

/// Amazing Match Screen with Dynamic Love Effects
///
/// Shows both user profile pictures with hearts, particles, and animations
class MatchNotification extends StatefulWidget {
  final Profile currentUserProfile;
  final Profile matchedProfile;
  final VoidCallback? onKeepSwiping;
  final VoidCallback? onSendMessage;
  final VoidCallback? onViewProfile;

  const MatchNotification({
    super.key,
    required this.currentUserProfile,
    required this.matchedProfile,
    this.onKeepSwiping,
    this.onSendMessage,
    this.onViewProfile,
  });

  @override
  State<MatchNotification> createState() => _MatchNotificationState();
}

class _MatchNotificationState extends State<MatchNotification>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _heartsController;
  late AnimationController _pulseController;
  late AnimationController _particleController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _photoLeftAnimation;
  late Animation<double> _photoRightAnimation;
  late Animation<double> _heartScaleAnimation;
  late Animation<double> _pulseAnimation;

  final List<_HeartParticle> _hearts = [];
  final List<_SparkleParticle> _sparkles = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();

    // Haptic feedback
    HapticFeedback.heavyImpact();

    // Main animation controller
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Hearts controller for floating hearts
    _heartsController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    )..repeat();

    // Pulse animation for the center heart
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    // Particle animation
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    // Scale animation for the whole dialog
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    // Fade animation
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    // Left photo slide animation
    _photoLeftAnimation = Tween<double>(begin: -100.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 0.7, curve: Curves.elasticOut),
      ),
    );

    // Right photo slide animation
    _photoRightAnimation = Tween<double>(begin: 100.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.2, 0.7, curve: Curves.elasticOut),
      ),
    );

    // Heart scale animation
    _heartScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.5, 1.0, curve: Curves.elasticOut),
      ),
    );

    // Pulse animation
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Generate floating hearts
    _generateHearts();
    _generateSparkles();

    _mainController.forward();
  }

  void _generateHearts() {
    for (int i = 0; i < 15; i++) {
      _hearts.add(_HeartParticle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: 12 + _random.nextDouble() * 20,
        speed: 0.3 + _random.nextDouble() * 0.5,
        delay: _random.nextDouble(),
      ));
    }
  }

  void _generateSparkles() {
    for (int i = 0; i < 30; i++) {
      _sparkles.add(_SparkleParticle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: 2 + _random.nextDouble() * 4,
        speed: 0.5 + _random.nextDouble() * 1.0,
        delay: _random.nextDouble(),
      ));
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _heartsController.dispose();
    _pulseController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Material(
        color: Colors.black.withOpacity(0.85),
        child: Stack(
          children: [
            // Floating hearts background
            AnimatedBuilder(
              animation: _heartsController,
              builder: (context, child) => _buildFloatingHearts(),
            ),

            // Sparkles
            AnimatedBuilder(
              animation: _particleController,
              builder: (context, child) => _buildSparkles(),
            ),

            // Main content
            Center(
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  margin: const EdgeInsets.all(24),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.backgroundDark.withOpacity(0.95),
                        AppColors.backgroundCard.withOpacity(0.95),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: AppColors.richGold.withOpacity(0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.richGold.withOpacity(0.3),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title with shimmer effect
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            AppColors.richGold,
                            Color(0xFFFFE55C),
                            AppColors.richGold,
                          ],
                        ).createShader(bounds),
                        child: const Text(
                          "IT'S A MATCH!",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        'You and ${widget.matchedProfile.displayName} have liked each other!',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Profile pictures with heart
                      SizedBox(
                        height: 180,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Left profile (current user)
                            AnimatedBuilder(
                              animation: _mainController,
                              builder: (context, child) => Transform.translate(
                                offset: Offset(_photoLeftAnimation.value, 0),
                                child: _buildProfilePhoto(
                                  widget.currentUserProfile,
                                  isLeft: true,
                                ),
                              ),
                            ),

                            // Right profile (matched user)
                            AnimatedBuilder(
                              animation: _mainController,
                              builder: (context, child) => Transform.translate(
                                offset: Offset(_photoRightAnimation.value, 0),
                                child: _buildProfilePhoto(
                                  widget.matchedProfile,
                                  isLeft: false,
                                ),
                              ),
                            ),

                            // Center heart with pulse
                            AnimatedBuilder(
                              animation: Listenable.merge([
                                _mainController,
                                _pulseController,
                              ]),
                              builder: (context, child) => Transform.scale(
                                scale: _heartScaleAnimation.value *
                                    _pulseAnimation.value,
                                child: Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.withOpacity(0.5),
                                        blurRadius: 20,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.favorite,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Start to Chat button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            Navigator.of(context).pop();
                            widget.onSendMessage?.call();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.richGold,
                            foregroundColor: AppColors.deepBlack,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 8,
                            shadowColor: AppColors.richGold.withOpacity(0.5),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble, size: 22),
                              SizedBox(width: 10),
                              Text(
                                "Let's Chat!",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // View Profile button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            widget.onViewProfile?.call();
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.richGold,
                            side: const BorderSide(
                              color: AppColors.richGold,
                              width: 2,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'View Profile',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Keep Swiping link
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          widget.onKeepSwiping?.call();
                        },
                        child: const Text(
                          'Keep Swiping',
                          style: TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 14,
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
      ),
    );
  }

  Widget _buildProfilePhoto(Profile profile, {required bool isLeft}) {
    final photoUrl = profile.photoUrls.isNotEmpty ? profile.photoUrls.first : null;
    final offset = isLeft ? -35.0 : 35.0;

    return Transform.translate(
      offset: Offset(offset, 0),
      child: Container(
        width: 130,
        height: 130,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.richGold,
            width: 4,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.richGold.withOpacity(0.3),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipOval(
          child: photoUrl != null
              ? CachedNetworkImage(
                  imageUrl: photoUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => _buildPhotoPlaceholder(),
                  errorWidget: (context, url, error) => _buildPhotoPlaceholder(),
                )
              : _buildPhotoPlaceholder(),
        ),
      ),
    );
  }

  Widget _buildPhotoPlaceholder() {
    return Container(
      color: AppColors.backgroundCard,
      child: const Icon(
        Icons.person,
        size: 50,
        color: AppColors.textTertiary,
      ),
    );
  }

  Widget _buildFloatingHearts() {
    return IgnorePointer(
      child: SizedBox.expand(
        child: CustomPaint(
          painter: _HeartsPainter(
            hearts: _hearts,
            progress: _heartsController.value,
          ),
        ),
      ),
    );
  }

  Widget _buildSparkles() {
    return IgnorePointer(
      child: SizedBox.expand(
        child: CustomPaint(
          painter: _SparklesPainter(
            sparkles: _sparkles,
            progress: _particleController.value,
          ),
        ),
      ),
    );
  }
}

class _HeartParticle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double delay;

  _HeartParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.delay,
  });
}

class _SparkleParticle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double delay;

  _SparkleParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.delay,
  });
}

class _HeartsPainter extends CustomPainter {
  final List<_HeartParticle> hearts;
  final double progress;

  _HeartsPainter({required this.hearts, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final heart in hearts) {
      final adjustedProgress = (progress + heart.delay) % 1.0;
      final y = size.height * (1 - adjustedProgress * heart.speed);
      final x = size.width * heart.x +
          math.sin(adjustedProgress * math.pi * 4) * 20;

      final opacity = adjustedProgress < 0.2
          ? adjustedProgress * 5
          : adjustedProgress > 0.8
              ? (1 - adjustedProgress) * 5
              : 1.0;

      final paint = Paint()
        ..color = Colors.red.withOpacity(opacity * 0.6)
        ..style = PaintingStyle.fill;

      _drawHeart(canvas, Offset(x, y), heart.size, paint);
    }
  }

  void _drawHeart(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    path.moveTo(center.dx, center.dy + size * 0.3);
    path.cubicTo(
      center.dx - size * 0.5,
      center.dy - size * 0.3,
      center.dx - size * 0.5,
      center.dy - size * 0.6,
      center.dx,
      center.dy - size * 0.3,
    );
    path.cubicTo(
      center.dx + size * 0.5,
      center.dy - size * 0.6,
      center.dx + size * 0.5,
      center.dy - size * 0.3,
      center.dx,
      center.dy + size * 0.3,
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _HeartsPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _SparklesPainter extends CustomPainter {
  final List<_SparkleParticle> sparkles;
  final double progress;

  _SparklesPainter({required this.sparkles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final sparkle in sparkles) {
      final adjustedProgress = (progress + sparkle.delay) % 1.0;

      final opacity = math.sin(adjustedProgress * math.pi);

      final paint = Paint()
        ..color = Colors.amber.withOpacity(opacity * 0.8)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(size.width * sparkle.x, size.height * sparkle.y),
        sparkle.size * (0.5 + opacity * 0.5),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _SparklesPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

/// Helper function to show match notification
Future<void> showMatchNotification(
  BuildContext context, {
  required Profile currentUserProfile,
  required Profile matchedProfile,
  VoidCallback? onKeepSwiping,
  VoidCallback? onSendMessage,
  VoidCallback? onViewProfile,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.transparent,
    pageBuilder: (context, animation, secondaryAnimation) => MatchNotification(
      currentUserProfile: currentUserProfile,
      matchedProfile: matchedProfile,
      onKeepSwiping: onKeepSwiping,
      onSendMessage: onSendMessage,
      onViewProfile: onViewProfile,
    ),
  );
}
