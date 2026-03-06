import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/learning_effects.dart';
import '../widgets/learning_path_node.dart';

/// A star node in the Galaxy Map. Renders as a 64x64 circle with
/// type-specific icons and status-based appearance.
///
/// Visual spec:
/// - Completed: green bg, white icon, check overlay (pop animation)
/// - Next Lesson: dark blue bg, gold border 3px, gold icon, BreathingFloat + PulseGlow
/// - Available: dark blue bg, gold border 2px, gold icon
/// - Locked: dark grey bg, grey border, lock icon, breathing opacity (0.4–0.55)
class GalaxyNode extends StatefulWidget {
  final PathNodeType type;
  final PathNodeStatus status;
  final String title;
  final int xpReward;
  final VoidCallback? onTap;
  final bool isNextLesson;
  final int starCount;

  const GalaxyNode({
    super.key,
    required this.type,
    required this.status,
    required this.title,
    required this.xpReward,
    this.onTap,
    this.isNextLesson = false,
    this.starCount = 0,
  });

  @override
  State<GalaxyNode> createState() => _GalaxyNodeState();
}

class _GalaxyNodeState extends State<GalaxyNode>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  // Completed check pop
  late AnimationController _checkPopController;
  late Animation<double> _checkPopAnimation;

  // Locked opacity breathing
  late AnimationController _lockedBreathController;

  @override
  void initState() {
    super.initState();

    // Bounce on tap
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _bounceAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    // Check pop for completed
    _checkPopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _checkPopAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.3), weight: 60),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(
      parent: _checkPopController,
      curve: Curves.elasticOut,
    ));
    if (widget.status == PathNodeStatus.completed) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _checkPopController.forward();
      });
    }

    // Locked breathing
    _lockedBreathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    );
    if (widget.status == PathNodeStatus.locked) {
      _lockedBreathController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(GalaxyNode oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.status == PathNodeStatus.locked &&
        !_lockedBreathController.isAnimating) {
      _lockedBreathController.repeat(reverse: true);
    } else if (widget.status != PathNodeStatus.locked) {
      _lockedBreathController.stop();
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _checkPopController.dispose();
    _lockedBreathController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (widget.status == PathNodeStatus.locked) return;
    HapticFeedback.lightImpact();
    _bounceController.forward().then((_) {
      _bounceController.reverse();
    });
    widget.onTap?.call();
  }

  IconData get _nodeIcon {
    switch (widget.type) {
      case PathNodeType.lesson:
        return Icons.menu_book;
      case PathNodeType.quiz:
        return Icons.quiz;
      case PathNodeType.flashcard:
        return Icons.style;
      case PathNodeType.aiCoach:
        return Icons.smart_toy;
    }
  }

  Color get _backgroundColor {
    switch (widget.status) {
      case PathNodeStatus.locked:
        return const Color(0xFF2A2A2A);
      case PathNodeStatus.available:
      case PathNodeStatus.inProgress:
        return const Color(0xFF1A1A2E);
      case PathNodeStatus.completed:
        return AppColors.successGreen;
    }
  }

  Color get _borderColor {
    switch (widget.status) {
      case PathNodeStatus.locked:
        return const Color(0xFF3A3A3A);
      case PathNodeStatus.available:
      case PathNodeStatus.inProgress:
        return AppColors.richGold;
      case PathNodeStatus.completed:
        return AppColors.successGreen;
    }
  }

  Color get _iconColor {
    switch (widget.status) {
      case PathNodeStatus.locked:
        return AppColors.textTertiary;
      case PathNodeStatus.available:
      case PathNodeStatus.inProgress:
        return AppColors.richGold;
      case PathNodeStatus.completed:
        return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _bounceAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _bounceAnimation.value,
            child: child,
          );
        },
        child: _buildOpacityWrapper(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildNodeCircle(),
              const SizedBox(height: 6),
              // Title label
              SizedBox(
                width: 100,
                child: Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: widget.status == PathNodeStatus.locked
                        ? AppColors.textTertiary
                        : AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 3),
              // Star rating for completed nodes, XP badge otherwise
              if (widget.status == PathNodeStatus.completed && widget.starCount > 0)
                _buildStarRating()
              else
                _buildXpBadge(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOpacityWrapper({required Widget child}) {
    if (widget.status == PathNodeStatus.locked) {
      return AnimatedBuilder(
        animation: _lockedBreathController,
        builder: (context, c) {
          final opacity = 0.4 + _lockedBreathController.value * 0.15;
          return Opacity(opacity: opacity, child: c);
        },
        child: child,
      );
    }
    return child;
  }

  Widget _buildNodeCircle() {
    final circle = Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _backgroundColor,
        border: Border.all(
          color: _borderColor,
          width: widget.isNextLesson
              ? 3
              : widget.status == PathNodeStatus.available
                  ? 2
                  : 2,
        ),
        boxShadow: widget.status == PathNodeStatus.completed
            ? [
                BoxShadow(
                  color: AppColors.successGreen.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : (widget.status == PathNodeStatus.available ||
                    widget.isNextLesson)
                ? [
                    BoxShadow(
                      color: AppColors.richGold.withValues(alpha: 0.2),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Main icon
          Icon(
            widget.status == PathNodeStatus.locked
                ? Icons.lock_rounded
                : _nodeIcon,
            size: 28,
            color: _iconColor,
          ),
          // Completed check overlay (animated pop)
          if (widget.status == PathNodeStatus.completed)
            AnimatedBuilder(
              animation: _checkPopAnimation,
              builder: (context, child) {
                return Positioned(
                  bottom: 2,
                  right: 2,
                  child: Transform.scale(
                    scale: _checkPopAnimation.value,
                    child: child,
                  ),
                );
              },
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                ),
                child: const Icon(
                  Icons.check,
                  size: 14,
                  color: AppColors.successGreen,
                ),
              ),
            ),
        ],
      ),
    );

    // Only the NEXT lesson gets BreathingFloat + PulseGlow
    if (widget.isNextLesson) {
      return BreathingFloat(
        amplitude: 3.0,
        child: PulseGlow(
          glowColor: AppColors.richGold,
          isActive: true,
          child: circle,
        ),
      );
    }

    return circle;
  }

  Widget _buildStarRating() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Icon(
          i < widget.starCount ? Icons.star : Icons.star_border,
          size: 14,
          color: i < widget.starCount
              ? AppColors.richGold
              : Colors.grey.withValues(alpha: 0.5),
        );
      }),
    );
  }

  Widget _buildXpBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: widget.status == PathNodeStatus.completed
            ? AppColors.successGreen.withValues(alpha: 0.15)
            : AppColors.richGold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '+${widget.xpReward} XP',
        style: TextStyle(
          color: widget.status == PathNodeStatus.completed
              ? AppColors.successGreen
              : AppColors.richGold,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
