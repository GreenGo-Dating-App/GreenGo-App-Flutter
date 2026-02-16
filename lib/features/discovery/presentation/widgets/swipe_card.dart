import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/widgets/membership_badge.dart';
import '../../../membership/domain/entities/membership.dart';
import '../../domain/entities/discovery_card.dart';

/// Swipeable Card Widget
///
/// Displays a profile card with directional gradient overlay on swipe.
/// Card stays in place — a color gradient fades in to indicate the action,
/// then the next card appears seamlessly.
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
  bool _isDragging = false;
  bool _hasTriggeredHaptic = false;
  Offset _cumulativeOffset = Offset.zero;

  SwipeDirection? _swipeDirection;
  double _swipeIntensity = 0.0;

  late AnimationController _animationController;
  late AnimationController _indicatorBounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );

    _indicatorBounceController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _bounceAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(
        parent: _indicatorBounceController,
        curve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _indicatorBounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return GestureDetector(
      onPanStart: widget.isFront ? _onPanStart : null,
      onPanUpdate: widget.isFront ? _onPanUpdate : null,
      onPanEnd: widget.isFront ? _onPanEnd : null,
      child: SizedBox(
        height: screenSize.height * 0.75,
        child: Stack(
          children: [
            _buildCard(screenSize),
            _buildInfoGradient(),
            _buildProfileInfo(),
            _buildGradientOverlay(),
            if (_swipeDirection != null && _swipeIntensity > 0)
              _buildSwipeIndicators(),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Size screenSize) {
    return Container(
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
                width: double.infinity,
                height: double.infinity,
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

  Widget _buildInfoGradient() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          gradient: const LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            stops: [0.0, 0.33, 0.66],
            colors: [
              Colors.black,
              Color(0xAA000000),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfo() {
    final profile = widget.card.candidate.profile;
    final interests = profile.interests;
    final languages = profile.languages;

    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Name, age, and membership badge
          Row(
            children: [
              Flexible(
                child: Text(
                  '${widget.card.displayName}, ${widget.card.age}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(color: Colors.black54, blurRadius: 4),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.card.membershipTier != MembershipTier.free) ...[
                const SizedBox(width: 8),
                MembershipBadge(
                  tier: widget.card.membershipTier,
                  compact: true,
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),

          // Location
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.white70, size: 16),
              const SizedBox(width: 4),
              Text(
                widget.card.distanceText,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Languages
          if (languages.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.translate, color: Colors.white70, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    languages.join(', '),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          // Interests
          if (interests.isNotEmpty) ...[
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: interests.take(5).map((interest) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(
                    interest,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
          ],

          // Match percentage
          Row(
            children: [
              const Icon(Icons.favorite, color: AppColors.richGold, size: 16),
              const SizedBox(width: 4),
              Text(
                '${widget.card.matchPercentage} match',
                style: const TextStyle(
                  color: AppColors.richGold,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Bio
          if (widget.card.bioPreview.isNotEmpty)
            Text(
              widget.card.bioPreview,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 13,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
    );
  }

  Widget _buildGradientOverlay() {
    if (_swipeDirection == null || _swipeIntensity <= 0) {
      return const SizedBox.shrink();
    }

    final color = _getGradientColor(_swipeDirection!);

    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
          gradient: LinearGradient(
            begin: _getGradientBegin(_swipeDirection!),
            end: _getGradientEnd(_swipeDirection!),
            colors: [
              color.withOpacity(_swipeIntensity * 0.7),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }

  Color _getGradientColor(SwipeDirection direction) {
    switch (direction) {
      case SwipeDirection.left:
        return AppColors.errorRed;
      case SwipeDirection.right:
        return AppColors.successGreen;
      case SwipeDirection.up:
        return AppColors.richGold;
      case SwipeDirection.down:
        return AppColors.infoBlue;
    }
  }

  Alignment _getGradientBegin(SwipeDirection direction) {
    switch (direction) {
      case SwipeDirection.left:
        return Alignment.centerLeft;
      case SwipeDirection.right:
        return Alignment.centerRight;
      case SwipeDirection.up:
        return Alignment.bottomCenter;
      case SwipeDirection.down:
        return Alignment.topCenter;
    }
  }

  Alignment _getGradientEnd(SwipeDirection direction) {
    switch (direction) {
      case SwipeDirection.left:
        return Alignment.centerRight;
      case SwipeDirection.right:
        return Alignment.centerLeft;
      case SwipeDirection.up:
        return Alignment.topCenter;
      case SwipeDirection.down:
        return Alignment.bottomCenter;
    }
  }

  Widget _buildSwipeIndicators() {
    final opacity = _swipeIntensity.clamp(0.0, 1.0);

    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Stack(
          children: [
            // Like indicator (right swipe)
            if (_swipeDirection == SwipeDirection.right)
              Positioned(
                top: 50,
                left: 50,
                child: Transform.rotate(
                  angle: -0.3,
                  child: Transform.scale(
                    scale: _bounceAnimation.value,
                    child: _buildIndicatorBox(
                      'LIKE',
                      AppColors.successGreen,
                      opacity,
                    ),
                  ),
                ),
              ),

            // Nope indicator (left swipe)
            if (_swipeDirection == SwipeDirection.left)
              Positioned(
                top: 50,
                right: 50,
                child: Transform.rotate(
                  angle: 0.3,
                  child: Transform.scale(
                    scale: _bounceAnimation.value,
                    child: _buildIndicatorBox(
                      'NOPE',
                      AppColors.errorRed,
                      opacity,
                    ),
                  ),
                ),
              ),

            // Super Like indicator (up swipe)
            if (_swipeDirection == SwipeDirection.up)
              Positioned(
                top: 50,
                left: 0,
                right: 0,
                child: Center(
                  child: Transform.scale(
                    scale: _bounceAnimation.value,
                    child: _buildIndicatorBox(
                      'SUPER LIKE',
                      AppColors.richGold,
                      opacity,
                    ),
                  ),
                ),
              ),

            // Skip indicator (down swipe)
            if (_swipeDirection == SwipeDirection.down)
              Positioned(
                top: 50,
                left: 0,
                right: 0,
                child: Center(
                  child: Transform.scale(
                    scale: _bounceAnimation.value,
                    child: _buildIndicatorBox(
                      'SKIP',
                      AppColors.infoBlue,
                      opacity,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildIndicatorBox(String text, Color color, double opacity) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: color.withOpacity(opacity),
          width: 4,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(opacity * 0.5),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color.withOpacity(opacity),
          fontSize: 42,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(
              color: color.withOpacity(opacity * 0.8),
              blurRadius: 15,
            ),
          ],
        ),
      ),
    );
  }

  SwipeDirection _computeDominantDirection(Offset offset) {
    final absX = offset.dx.abs();
    final absY = offset.dy.abs();

    if (absX > absY) {
      return offset.dx > 0 ? SwipeDirection.right : SwipeDirection.left;
    } else {
      return offset.dy < 0 ? SwipeDirection.up : SwipeDirection.down;
    }
  }

  void _onPanStart(DragStartDetails details) {
    _animationController.stop();
    setState(() {
      _isDragging = true;
      _cumulativeOffset = Offset.zero;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;

    setState(() {
      _cumulativeOffset += details.delta;

      // Compute dominant direction
      _swipeDirection = _computeDominantDirection(_cumulativeOffset);

      // Compute intensity based on magnitude relative to threshold
      final threshold = screenWidth * 0.25;
      final magnitude = _cumulativeOffset.distance;
      _swipeIntensity = (magnitude / threshold).clamp(0.0, 1.0);
    });

    // Report drag progress for back card parallax
    widget.onDragProgress?.call(_swipeIntensity);

    // Trigger haptic feedback when crossing threshold
    final screenWidth2 = MediaQuery.of(context).size.width;
    final threshold = screenWidth2 * 0.15;
    final magnitude = _cumulativeOffset.distance;
    if (!_hasTriggeredHaptic && magnitude > threshold) {
      _hasTriggeredHaptic = true;
      HapticFeedback.mediumImpact();
      _indicatorBounceController.forward(from: 0);
    } else if (_hasTriggeredHaptic && magnitude < threshold) {
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
    final velocityThreshold = 800.0;
    final positionThreshold = screenWidth * 0.25;

    // Determine if the swipe crosses threshold
    SwipeDirection? direction;

    if (_cumulativeOffset.dx.abs() > positionThreshold ||
        velocity.dx.abs() > velocityThreshold) {
      if (_cumulativeOffset.dx > 0 || velocity.dx > velocityThreshold) {
        direction = SwipeDirection.right;
      } else if (_cumulativeOffset.dx < 0 || velocity.dx < -velocityThreshold) {
        direction = SwipeDirection.left;
      }
    } else if (_cumulativeOffset.dy < -80 || velocity.dy < -velocityThreshold) {
      direction = SwipeDirection.up;
    } else if (_cumulativeOffset.dy > 80 || velocity.dy > velocityThreshold) {
      direction = SwipeDirection.down;
    }

    if (direction != null) {
      HapticFeedback.heavyImpact();
      _completeSwipe(direction);
    } else {
      _cancelSwipe();
    }
  }

  void _completeSwipe(SwipeDirection direction) {
    // Set direction for the completion animation
    setState(() {
      _swipeDirection = direction;
    });

    // Animate intensity to 1.0
    final startIntensity = _swipeIntensity;
    _animationController.duration = const Duration(milliseconds: 250);

    late Animation<double> intensityAnim;
    intensityAnim = Tween<double>(begin: startIntensity, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    void listener() {
      if (mounted) {
        setState(() {
          _swipeIntensity = intensityAnim.value;
        });
      }
    }

    intensityAnim.addListener(listener);

    _animationController.forward(from: 0).then((_) {
      intensityAnim.removeListener(listener);
      widget.onSwipe?.call(direction);
      _reset();
    });
  }

  void _cancelSwipe() {
    final startIntensity = _swipeIntensity;
    final startDirection = _swipeDirection;

    _animationController.duration = const Duration(milliseconds: 150);

    late Animation<double> intensityAnim;
    intensityAnim = Tween<double>(begin: startIntensity, end: 0.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );

    void listener() {
      if (mounted) {
        setState(() {
          _swipeIntensity = intensityAnim.value;
          _swipeDirection = startDirection;
        });
      }
    }

    intensityAnim.addListener(listener);

    _animationController.forward(from: 0).then((_) {
      intensityAnim.removeListener(listener);
      _reset();
    });
  }

  void _reset() {
    setState(() {
      _swipeDirection = null;
      _swipeIntensity = 0.0;
      _cumulativeOffset = Offset.zero;
    });
    widget.onDragProgress?.call(0.0);
  }
}

/// Swipe Direction Enum
enum SwipeDirection {
  left,   // Pass / Nope
  right,  // Like
  up,     // Super Like
  down,   // Skip
}
