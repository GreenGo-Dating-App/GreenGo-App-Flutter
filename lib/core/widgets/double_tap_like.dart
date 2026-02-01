import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Enhancement #25: Double Tap to Like
/// Heart animation on double tap (like Instagram)
class DoubleTapLike extends StatefulWidget {
  final Widget child;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onTap;
  final bool enabled;

  const DoubleTapLike({
    super.key,
    required this.child,
    this.onDoubleTap,
    this.onTap,
    this.enabled = true,
  });

  @override
  State<DoubleTapLike> createState() => _DoubleTapLikeState();
}

class _DoubleTapLikeState extends State<DoubleTapLike>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _showHeart = false;
  Offset _tapPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.4)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.4, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.0),
        weight: 40,
      ),
    ]).animate(_controller);

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 1.0),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0),
        weight: 20,
      ),
    ]).animate(_controller);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _showHeart = false;
        });
        _controller.reset();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDoubleTap(TapDownDetails details) {
    if (!widget.enabled) return;

    setState(() {
      _showHeart = true;
      _tapPosition = details.localPosition;
    });
    _controller.forward();
    widget.onDoubleTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onDoubleTapDown: _handleDoubleTap,
      onDoubleTap: () {}, // Required for onDoubleTapDown to work
      child: Stack(
        children: [
          widget.child,
          if (_showHeart)
            Positioned(
              left: _tapPosition.dx - 40,
              top: _tapPosition.dy - 40,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Opacity(
                    opacity: _opacityAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: const Icon(
                        Icons.favorite,
                        size: 80,
                        color: AppColors.errorRed,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Message like indicator
class MessageLikeIndicator extends StatelessWidget {
  final bool isLiked;
  final int likeCount;
  final VoidCallback? onTap;

  const MessageLikeIndicator({
    super.key,
    required this.isLiked,
    this.likeCount = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (likeCount == 0 && !isLiked) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.errorRed.withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLiked ? Icons.favorite : Icons.favorite_border,
              size: 14,
              color: AppColors.errorRed,
            ),
            if (likeCount > 0) ...[
              const SizedBox(width: 2),
              Text(
                '$likeCount',
                style: const TextStyle(
                  color: AppColors.errorRed,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
