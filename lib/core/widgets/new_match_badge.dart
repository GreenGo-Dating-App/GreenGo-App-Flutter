import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Enhancement #29: New Match Badge
/// Highlights recent matches with animated badge
class NewMatchBadge extends StatefulWidget {
  final Widget child;
  final bool isNew;
  final Duration newDuration;

  const NewMatchBadge({
    super.key,
    required this.child,
    this.isNew = true,
    this.newDuration = const Duration(hours: 24),
  });

  @override
  State<NewMatchBadge> createState() => _NewMatchBadgeState();
}

class _NewMatchBadgeState extends State<NewMatchBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.isNew) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(NewMatchBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isNew && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isNew && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isNew) return widget.child;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.child,
        Positioned(
          top: -6,
          right: -6,
          child: ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.richGold, Color(0xFFFFD700)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.richGold.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                'NEW',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Time-based new indicator
class TimedNewBadge extends StatelessWidget {
  final DateTime matchedAt;
  final Widget child;
  final Duration newThreshold;

  const TimedNewBadge({
    super.key,
    required this.matchedAt,
    required this.child,
    this.newThreshold = const Duration(hours: 24),
  });

  bool get isNew => DateTime.now().difference(matchedAt) < newThreshold;

  @override
  Widget build(BuildContext context) {
    return NewMatchBadge(
      isNew: isNew,
      child: child,
    );
  }
}

/// "Just matched" celebration indicator
class JustMatchedIndicator extends StatefulWidget {
  final VoidCallback? onDismiss;

  const JustMatchedIndicator({
    super.key,
    this.onDismiss,
  });

  @override
  State<JustMatchedIndicator> createState() => _JustMatchedIndicatorState();
}

class _JustMatchedIndicatorState extends State<JustMatchedIndicator>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late AnimationController _sparkleController;
  late Animation<double> _bounceAnimation;
  late Animation<double> _sparkleAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.9), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(parent: _bounceController, curve: Curves.easeOut));

    _sparkleAnimation = Tween<double>(begin: 0, end: 1).animate(_sparkleController);

    _bounceController.forward();
    _sparkleController.repeat();
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onDismiss,
      child: AnimatedBuilder(
        animation: _bounceAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _bounceAnimation.value,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.richGold,
                    AppColors.richGold.withOpacity(0.8),
                  ],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.richGold.withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _sparkleAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _sparkleAnimation.value * 2 * 3.14159,
                        child: const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 20,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "It's a Match!",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedBuilder(
                    animation: _sparkleAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: -_sparkleAnimation.value * 2 * 3.14159,
                        child: const Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
                          size: 20,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Match count badge for navigation
class MatchCountBadge extends StatelessWidget {
  final int totalMatches;
  final int newMatches;
  final Widget child;

  const MatchCountBadge({
    super.key,
    required this.totalMatches,
    required this.newMatches,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (newMatches == 0) return child;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          top: -4,
          right: -4,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.richGold,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: AppColors.richGold.withOpacity(0.4),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            constraints: const BoxConstraints(
              minWidth: 18,
              minHeight: 18,
            ),
            child: Center(
              child: Text(
                newMatches > 99 ? '99+' : '$newMatches',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
