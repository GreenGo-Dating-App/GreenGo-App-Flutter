import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';
import '../../features/subscription/domain/entities/subscription.dart';

/// Full-screen luxury celebration animation for subscription purchase
class SubscriptionCelebrationScreen extends StatefulWidget {
  final String tierName;
  final SubscriptionTier? tier;
  final VoidCallback? onComplete;

  const SubscriptionCelebrationScreen({
    super.key,
    required this.tierName,
    this.tier,
    this.onComplete,
  });

  /// Navigate to this screen as a full-screen overlay
  static Future<void> show(
    BuildContext context, {
    required String tierName,
    SubscriptionTier? tier,
    VoidCallback? onComplete,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return SubscriptionCelebrationScreen(
            tierName: tierName,
            tier: tier,
            onComplete: onComplete,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  State<SubscriptionCelebrationScreen> createState() =>
      _SubscriptionCelebrationScreenState();
}

class _SubscriptionCelebrationScreenState
    extends State<SubscriptionCelebrationScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _particleController;
  late AnimationController _pulseController;
  late AnimationController _textController;
  late Animation<double> _crownScale;
  late Animation<double> _glowAnimation;
  late Animation<double> _textSlide;
  late Animation<double> _textOpacity;
  late Animation<double> _buttonOpacity;
  bool _showButton = false;

  List<_Particle> _particles = [];
  final _random = Random();

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();

    // Initialize particles
    _particles = List.generate(60, (_) => _Particle(_random));

    // Main controller for the crown entrance
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _crownScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.2).chain(CurveTween(curve: Curves.easeOut)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.2, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 40,
      ),
    ]).animate(_mainController);

    // Particle controller
    _particleController = AnimationController(
      duration: const Duration(milliseconds: 4000),
      vsync: this,
    );

    // Glow pulse
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Text animation
    _textController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _textSlide = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeOut),
    );

    _textOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );

    _buttonOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _textController, curve: const Interval(0.5, 1.0)),
    );

    // Start animation sequence
    _startAnimations();
  }

  Future<void> _startAnimations() async {
    // Start particles immediately
    _particleController.repeat();
    _pulseController.repeat(reverse: true);

    // Crown entrance
    await Future.delayed(const Duration(milliseconds: 300));
    _mainController.forward();

    // Text entrance
    await Future.delayed(const Duration(milliseconds: 1200));
    _textController.forward();

    // Show button
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) setState(() => _showButton = true);
  }

  @override
  void dispose() {
    _mainController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Color get _tierColor {
    final tier = widget.tierName.toLowerCase();
    if (tier.contains('platinum')) return AppColors.platinumBlue;
    if (tier.contains('gold')) return AppColors.richGold;
    if (tier.contains('base') || tier.contains('free')) return AppColors.basePurple;
    return const Color(0xFFC0C0C0); // silver
  }

  Color get _tierGlowColor {
    final tier = widget.tierName.toLowerCase();
    if (tier.contains('platinum')) return AppColors.platinumBlue;
    if (tier.contains('gold')) return AppColors.richGold;
    if (tier.contains('base') || tier.contains('free')) return AppColors.basePurple;
    return const Color(0xFFB0B0B0);
  }

  List<Color> get _tierGradient {
    final tier = widget.tierName.toLowerCase();
    if (tier.contains('platinum')) {
      return [AppColors.platinumBlueDark, AppColors.platinumBlue, const Color(0xFFB3E5FC)];
    }
    if (tier.contains('gold')) {
      return [const Color(0xFFB8860B), AppColors.richGold, const Color(0xFFFFD700)];
    }
    if (tier.contains('base') || tier.contains('free')) {
      return [AppColors.basePurpleDark, AppColors.basePurple, const Color(0xFFD1C4E9)];
    }
    return [const Color(0xFF808080), const Color(0xFFC0C0C0), const Color(0xFFD3D3D3)];
  }

  /// Build tier-specific benefit rows from the tier's features map
  List<Widget> _buildTierBenefits() {
    final tier = widget.tier;
    if (tier == null) {
      // Fallback to generic features if no tier provided
      return [
        _buildFeatureRow(Icons.favorite, 'Unlimited likes'),
        const SizedBox(height: 12),
        _buildFeatureRow(Icons.visibility, 'See who liked you'),
        const SizedBox(height: 12),
        _buildFeatureRow(Icons.flash_on, 'Priority matching'),
      ];
    }

    final features = tier.features;
    final rows = <Widget>[];

    void addRow(IconData icon, String label, String value) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 10));
      rows.add(_buildBenefitRow(icon, label, value));
    }

    // Daily Likes
    final dailyLikes = features['dailyLikes'] as int? ?? 0;
    if (dailyLikes == -1) {
      addRow(Icons.favorite, 'Daily Likes', 'Unlimited');
    } else if (dailyLikes > 0) {
      addRow(Icons.favorite, 'Daily Likes', '$dailyLikes');
    }

    // Super Likes
    final superLikes = features['superLikes'] as int? ?? 0;
    if (superLikes == -1) {
      addRow(Icons.star, 'Super Likes', 'Unlimited');
    } else if (superLikes > 0) {
      addRow(Icons.star, 'Super Likes', '$superLikes/day');
    }

    // Rewinds
    final rewinds = features['rewinds'] as int? ?? 0;
    if (rewinds == -1) {
      addRow(Icons.replay, 'Rewinds', 'Unlimited');
    } else if (rewinds > 0) {
      addRow(Icons.replay, 'Rewinds', '$rewinds/day');
    }

    // Badge
    if (features['badge'] == true) {
      addRow(Icons.workspace_premium, 'Badge', '✓');
    }

    // Read Receipts
    if (features['readReceipts'] == true) {
      addRow(Icons.done_all, 'Read Receipts', '✓');
    }

    // Advanced Filters
    if (features['advancedFilters'] == true) {
      addRow(Icons.tune, 'Advanced Filters', '✓');
    }

    // Incognito Mode
    if (features['incognitoMode'] == true) {
      addRow(Icons.visibility_off, 'Incognito Mode', '✓');
    }

    // Priority Support
    if (features['prioritySupport'] == true) {
      addRow(Icons.support_agent, 'Priority Support', '✓');
    }

    // Travelling (Platinum)
    if (features['travelling'] == true) {
      addRow(Icons.flight, 'Travelling', 'Unlimited');
    }

    // VIP Badge (Platinum)
    if (features['vipBadge'] == true) {
      addRow(Icons.verified, 'VIP Badge', '✓');
    }

    // Priority Matching (Platinum)
    if (features['priorityMatching'] == true) {
      addRow(Icons.flash_on, 'Priority Matching', '✓');
    }

    // Exclusive Events (Platinum)
    if (features['exclusiveEvents'] == true) {
      addRow(Icons.event_available, 'Exclusive Events', '✓');
    }

    return rows;
  }

  void _handleContinue() {
    Navigator.of(context).pop();
    widget.onComplete?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Dark background
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  AppColors.backgroundDark.withOpacity(0.95),
                  Colors.black,
                ],
              ),
            ),
          ),

          // Particle system
          AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                size: MediaQuery.of(context).size,
                painter: _ParticlePainter(
                  particles: _particles,
                  progress: _particleController.value,
                  color: _tierColor,
                ),
              );
            },
          ),

          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // Crown icon with glow
                AnimatedBuilder(
                  animation: Listenable.merge([_mainController, _pulseController]),
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _crownScale.value,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _tierGlowColor.withOpacity(0.4 * _glowAnimation.value),
                              blurRadius: 40 * _glowAnimation.value,
                              spreadRadius: 10 * _glowAnimation.value,
                            ),
                            BoxShadow(
                              color: _tierGlowColor.withOpacity(0.2 * _glowAnimation.value),
                              blurRadius: 80 * _glowAnimation.value,
                              spreadRadius: 20 * _glowAnimation.value,
                            ),
                          ],
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: _tierGradient,
                            ),
                          ),
                          child: const Icon(
                            Icons.workspace_premium,
                            size: 80,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),

                // Title text with shimmer
                AnimatedBuilder(
                  animation: _textController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _textSlide.value),
                      child: Opacity(
                        opacity: _textOpacity.value,
                        child: Column(
                          children: [
                            ShaderMask(
                              shaderCallback: (bounds) {
                                return LinearGradient(
                                  colors: _tierGradient,
                                ).createShader(bounds);
                              },
                              child: Text(
                                'Welcome to ${widget.tierName}!',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Your premium membership is now active',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textSecondary,
                                letterSpacing: 0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            // Tier-specific benefits
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 32),
                              child: Column(
                                children: _buildTierBenefits(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                const Spacer(),

                // Continue button
                AnimatedBuilder(
                  animation: _textController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _buttonOpacity.value,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _showButton ? _handleContinue : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _tierColor,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                              elevation: 8,
                              shadowColor: _tierColor.withOpacity(0.5),
                            ),
                            child: const Text(
                              'Continue',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: _tierColor, size: 20),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: _tierColor, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: _tierColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// A single particle for the celebration effect
class _Particle {
  late double x;
  late double y;
  late double size;
  late double speed;
  late double angle;
  late double opacity;

  _Particle(Random random) {
    x = random.nextDouble();
    y = random.nextDouble();
    size = 2 + random.nextDouble() * 4;
    speed = 0.2 + random.nextDouble() * 0.5;
    angle = random.nextDouble() * 2 * pi;
    opacity = 0.3 + random.nextDouble() * 0.7;
  }
}

/// CustomPainter for particle effects
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final Color color;

  _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final t = (progress + particle.speed) % 1.0;

      // Floating upward with slight horizontal drift
      final px = (particle.x + sin(t * 2 * pi + particle.angle) * 0.05) * size.width;
      final py = (1.0 - t) * size.height * 1.2 - size.height * 0.1;

      if (py < 0 || py > size.height) continue;

      final fadeFactor = t < 0.1 ? t / 0.1 : (t > 0.8 ? (1 - t) / 0.2 : 1.0);

      final paint = Paint()
        ..color = color.withOpacity(particle.opacity * fadeFactor * 0.6)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, particle.size * 0.5);

      canvas.drawCircle(Offset(px, py), particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}
