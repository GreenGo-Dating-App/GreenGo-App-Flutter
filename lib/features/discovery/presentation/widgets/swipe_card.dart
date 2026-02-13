import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../domain/entities/discovery_card.dart';

/// Swipeable Card Widget
///
/// Displays a profile card that can be swiped left/right/up
class SwipeCard extends StatefulWidget {
  final DiscoveryCard card;
  final Function(SwipeDirection)? onSwipe;
  final VoidCallback? onTap;
  final bool isFront;
  final ValueChanged<double>? onDragProgress;

  const SwipeCard({
    super.key,
    required this.card,
    this.onSwipe,
    this.onTap,
    this.isFront = false,
    this.onDragProgress,
  });

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard>
    with TickerProviderStateMixin {
  Offset _position = Offset.zero;
  bool _isDragging = false;
  double _angle = 0;
  bool _hasTriggeredHaptic = false;

  late AnimationController _animationController;
  late AnimationController _indicatorBounceController;
  late AnimationController _sparkleController;
  late Animation<Offset> _animation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _sparkleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _indicatorBounceController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _indicatorBounceController,
        curve: Curves.elasticOut,
      ),
    );

    _sparkleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _sparkleController,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _indicatorBounceController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final milliseconds = _isDragging ? 0 : 500;

    return AnimatedContainer(
      duration: Duration(milliseconds: milliseconds),
      curve: Curves.easeOutBack,
      transform: Matrix4.identity()
        ..translate(_position.dx, _position.dy)
        ..rotateZ(_angle),
      child: GestureDetector(
        onPanStart: widget.isFront ? _onPanStart : null,
        onPanUpdate: widget.isFront ? _onPanUpdate : null,
        onPanEnd: widget.isFront ? _onPanEnd : null,
        onTap: widget.onTap,
        child: Stack(
          children: [
            // Card background
            _buildCard(screenSize),

            // Swipe indicators
            if (_isDragging && widget.isFront) _buildSwipeIndicators(),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Size screenSize) {
    return Container(
      height: screenSize.height * 0.75,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        child: widget.card.primaryPhoto != null
            ? Image.network(
                widget.card.primaryPhoto!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    _buildPlaceholder(),
              )
            : _buildPlaceholder(),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: AppColors.backgroundCard,
      child: const Center(
        child: Icon(
          Icons.person,
          size: 100,
          color: AppColors.textTertiary,
        ),
      ),
    );
  }

  Widget _buildSwipeIndicators() {
    final opacity = (_position.dx.abs() / 100).clamp(0.0, 1.0);
    final verticalOpacity = (_position.dy.abs() / 100).clamp(0.0, 1.0);

    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            // Like indicator (right swipe) with glow effect
            if (_position.dx > 20)
              Positioned(
                top: 50,
                left: 50,
                child: Transform.rotate(
                  angle: -0.3,
                  child: Transform.scale(
                    scale: _bounceAnimation.value,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.successGreen.withOpacity(opacity),
                          width: 4,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.successGreen.withOpacity(opacity * 0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Text(
                        'LIKE',
                        style: TextStyle(
                          color: AppColors.successGreen.withOpacity(opacity),
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: AppColors.successGreen.withOpacity(opacity * 0.8),
                              blurRadius: 15,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Nope indicator (left swipe) with glow effect
            if (_position.dx < -20)
              Positioned(
                top: 50,
                right: 50,
                child: Transform.rotate(
                  angle: 0.3,
                  child: Transform.scale(
                    scale: _bounceAnimation.value,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.errorRed.withOpacity(opacity),
                          width: 4,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.errorRed.withOpacity(opacity * 0.5),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Text(
                        'NOPE',
                        style: TextStyle(
                          color: AppColors.errorRed.withOpacity(opacity),
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: AppColors.errorRed.withOpacity(opacity * 0.8),
                              blurRadius: 15,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // Super Like indicator (up swipe) with sparkle effect
            if (_position.dy < -20)
              Positioned(
                bottom: 100,
                left: 0,
                right: 0,
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Sparkle particles
                      ...List.generate(8, (index) {
                        final angle = (index / 8) * 2 * math.pi;
                        final radius = 60 * _sparkleAnimation.value;
                        return Positioned(
                          left: math.cos(angle) * radius + 80,
                          top: math.sin(angle) * radius + 30,
                          child: Opacity(
                            opacity: verticalOpacity * (1 - _sparkleAnimation.value),
                            child: Icon(
                              Icons.star,
                              color: AppColors.richGold,
                              size: 16,
                            ),
                          ),
                        );
                      }),
                      // Main indicator
                      Transform.scale(
                        scale: _bounceAnimation.value,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: AppColors.richGold.withOpacity(verticalOpacity),
                              width: 4,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.richGold.withOpacity(verticalOpacity * 0.6),
                                blurRadius: 25,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.star,
                                color: AppColors.richGold.withOpacity(verticalOpacity),
                                size: 32,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'SUPER LIKE',
                                style: TextStyle(
                                  color: AppColors.richGold.withOpacity(verticalOpacity),
                                  fontSize: 42,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      color: AppColors.richGold.withOpacity(verticalOpacity * 0.8),
                                      blurRadius: 15,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;

    setState(() {
      _position += details.delta;

      // Calculate rotation angle based on horizontal position
      final x = _position.dx;
      _angle = (x / 1000).clamp(-0.3, 0.3);
    });

    // Report drag progress for back card parallax
    final progress = (_position.dx.abs() / (screenWidth * 0.25)).clamp(0.0, 1.0);
    widget.onDragProgress?.call(progress);

    // Trigger haptic feedback when crossing threshold
    final threshold = screenWidth * 0.15;
    if (!_hasTriggeredHaptic &&
        (_position.dx.abs() > threshold || _position.dy < -50)) {
      _hasTriggeredHaptic = true;
      HapticFeedback.mediumImpact();
      _indicatorBounceController.forward(from: 0);

      // Start sparkle animation for super like
      if (_position.dy < -50) {
        _sparkleController.forward(from: 0);
      }
    } else if (_hasTriggeredHaptic &&
        _position.dx.abs() < threshold &&
        _position.dy > -50) {
      _hasTriggeredHaptic = false;
    }
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
      _hasTriggeredHaptic = false;
    });

    final screenWidth = MediaQuery.of(context).size.width;
    final velocity = details.velocity.pixelsPerSecond;

    // Determine swipe direction
    SwipeDirection? direction;

    // Reduced threshold from 0.4 to 0.25 for easier swipes
    // Also add velocity-based detection for fast flicks
    final velocityThreshold = 800.0;

    if (_position.dx.abs() > screenWidth * 0.25 ||
        velocity.dx.abs() > velocityThreshold) {
      // Horizontal swipe (position-based or velocity-based)
      if (_position.dx > 0 || velocity.dx > velocityThreshold) {
        direction = SwipeDirection.right;
      } else if (_position.dx < 0 || velocity.dx < -velocityThreshold) {
        direction = SwipeDirection.left;
      }
    } else if (_position.dy < -80 || velocity.dy < -velocityThreshold) {
      // Up swipe (super like) - reduced threshold from -100 to -80
      direction = SwipeDirection.up;
    }

    if (direction != null) {
      // Heavy haptic feedback on swipe complete
      HapticFeedback.heavyImpact();
      // Animate card off screen
      _animateCardOffScreen(direction);
    } else {
      // Return to center
      _resetPosition();
    }
  }

  void _animateCardOffScreen(SwipeDirection direction) {
    final screenSize = MediaQuery.of(context).size;

    Offset endPosition;
    switch (direction) {
      case SwipeDirection.left:
        endPosition = Offset(-screenSize.width * 1.5, _position.dy);
        break;
      case SwipeDirection.right:
        endPosition = Offset(screenSize.width * 1.5, _position.dy);
        break;
      case SwipeDirection.up:
        endPosition = Offset(_position.dx, -screenSize.height * 1.5);
        break;
    }

    _animation = Tween<Offset>(
      begin: _position,
      end: endPosition,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.fastOutSlowIn,
    ));

    // FIX: Add listener BEFORE forward() to ensure animation updates are captured
    _animation.addListener(() {
      if (mounted) {
        setState(() {
          _position = _animation.value;
        });
      }
    });

    _animationController.forward(from: 0).then((_) {
      widget.onSwipe?.call(direction);
      _resetPosition();
    });
  }

  void _resetPosition() {
    setState(() {
      _position = Offset.zero;
      _angle = 0;
    });
    widget.onDragProgress?.call(0.0);
  }
}

/// Swipe Direction Enum
enum SwipeDirection {
  left,   // Pass
  right,  // Like
  up,     // Super Like
}
