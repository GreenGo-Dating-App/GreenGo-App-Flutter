import 'package:flutter/material.dart';
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

  const SwipeCard({
    super.key,
    required this.card,
    this.onSwipe,
    this.onTap,
    this.isFront = false,
  });

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard>
    with SingleTickerProviderStateMixin {
  Offset _position = Offset.zero;
  bool _isDragging = false;
  double _angle = 0;

  late AnimationController _animationController;
  late Animation<Offset> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final milliseconds = _isDragging ? 0 : 400;

    return AnimatedContainer(
      duration: Duration(milliseconds: milliseconds),
      curve: Curves.easeInOut,
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
      height: screenSize.height * 0.65,
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
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            widget.card.primaryPhoto != null
                ? Image.network(
                    widget.card.primaryPhoto!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        _buildPlaceholder(),
                  )
                : _buildPlaceholder(),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),

            // Profile info
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildProfileInfo(),
            ),

            // Match percentage badge
            if (widget.card.isRecommended)
              Positioned(
                top: 16,
                right: 16,
                child: _buildMatchBadge(),
              ),
          ],
        ),
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

  Widget _buildProfileInfo() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(
                widget.card.displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${widget.card.age}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.location_on,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                widget.card.distanceText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          if (widget.card.bioPreview.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              widget.card.bioPreview,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMatchBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.richGold,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.richGold.withOpacity(0.5),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.auto_awesome,
            color: AppColors.deepBlack,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            widget.card.matchPercentage,
            style: const TextStyle(
              color: AppColors.deepBlack,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwipeIndicators() {
    final opacity = (_position.dx.abs() / 100).clamp(0.0, 1.0);

    return Stack(
      children: [
        // Like indicator (right swipe)
        if (_position.dx > 20)
          Positioned(
            top: 50,
            left: 50,
            child: Transform.rotate(
              angle: -0.3,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.successGreen.withOpacity(opacity),
                    width: 4,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'LIKE',
                  style: TextStyle(
                    color: AppColors.successGreen.withOpacity(opacity),
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

        // Nope indicator (left swipe)
        if (_position.dx < -20)
          Positioned(
            top: 50,
            right: 50,
            child: Transform.rotate(
              angle: 0.3,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.errorRed.withOpacity(opacity),
                    width: 4,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'NOPE',
                  style: TextStyle(
                    color: AppColors.errorRed.withOpacity(opacity),
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

        // Super Like indicator (up swipe)
        if (_position.dy < -20)
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.richGold.withOpacity(opacity),
                    width: 4,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'SUPER LIKE',
                  style: TextStyle(
                    color: AppColors.richGold.withOpacity(opacity),
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _position += details.delta;

      // Calculate rotation angle based on horizontal position
      final x = _position.dx;
      _angle = (x / 1000).clamp(-0.3, 0.3);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });

    final screenWidth = MediaQuery.of(context).size.width;

    // Determine swipe direction
    SwipeDirection? direction;

    if (_position.dx.abs() > screenWidth * 0.4) {
      // Horizontal swipe
      direction = _position.dx > 0 ? SwipeDirection.right : SwipeDirection.left;
    } else if (_position.dy < -100) {
      // Up swipe (super like)
      direction = SwipeDirection.up;
    }

    if (direction != null) {
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
      curve: Curves.easeOut,
    ));

    _animationController.forward(from: 0).then((_) {
      widget.onSwipe?.call(direction);
      _resetPosition();
    });

    _animation.addListener(() {
      setState(() {
        _position = _animation.value;
      });
    });
  }

  void _resetPosition() {
    setState(() {
      _position = Offset.zero;
      _angle = 0;
    });
  }
}

/// Swipe Direction Enum
enum SwipeDirection {
  left,   // Pass
  right,  // Like
  up,     // Super Like
}
