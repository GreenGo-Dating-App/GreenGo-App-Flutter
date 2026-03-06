import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/learning_effects.dart';

/// Node types available in the learning path.
enum PathNodeType { lesson, quiz, flashcard, aiCoach }

/// Status of a learning path node.
enum PathNodeStatus { locked, available, inProgress, completed }

/// Individual node in the Duolingo-style learning path.
/// Displays a circular icon with status-based appearance, title,
/// and XP reward badge.
class LearningPathNode extends StatefulWidget {
  final PathNodeType type;
  final PathNodeStatus status;
  final String title;
  final int xpReward;
  final VoidCallback? onTap;
  final int nodeIndex;

  const LearningPathNode({
    super.key,
    required this.type,
    required this.status,
    required this.title,
    required this.xpReward,
    this.onTap,
    required this.nodeIndex,
  });

  @override
  State<LearningPathNode> createState() => _LearningPathNodeState();
}

class _LearningPathNodeState extends State<LearningPathNode>
    with TickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;
  late AnimationController _entranceController;
  late Animation<double> _entranceFade;
  late Animation<double> _entranceScale;

  // For completed check pop
  late AnimationController _checkPopController;
  late Animation<double> _checkPopAnimation;

  // For locked opacity breathing
  late AnimationController _lockedBreathController;

  // For in-progress fill animation
  late AnimationController _fillController;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _bounceAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    // Entrance animation with staggered delay
    final delay = Duration(
      milliseconds: (widget.nodeIndex * 80).clamp(0, 1200),
    );
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _entranceFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOut),
    );
    _entranceScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: Curves.easeOutBack),
    );
    Future.delayed(delay, () {
      if (mounted) _entranceController.forward();
    });

    // Check pop for completed nodes
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
      Future.delayed(delay + const Duration(milliseconds: 300), () {
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

    // In-progress fill
    _fillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    if (widget.status == PathNodeStatus.inProgress) {
      Future.delayed(delay, () {
        if (mounted) _fillController.forward();
      });
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    _entranceController.dispose();
    _checkPopController.dispose();
    _lockedBreathController.dispose();
    _fillController.dispose();
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
        return const Color(0xFF1A1A2E);
      case PathNodeStatus.inProgress:
        return AppColors.richGold.withValues(alpha: 0.2);
      case PathNodeStatus.completed:
        return AppColors.successGreen;
    }
  }

  Color get _borderColor {
    switch (widget.status) {
      case PathNodeStatus.locked:
        return const Color(0xFF3A3A3A);
      case PathNodeStatus.available:
        return AppColors.richGold;
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
        return AppColors.richGold;
      case PathNodeStatus.inProgress:
        return AppColors.richGold;
      case PathNodeStatus.completed:
        return Colors.white;
    }
  }

  double get _opacity {
    return widget.status == PathNodeStatus.locked ? 0.5 : 1.0;
  }

  String get _statusLabel {
    switch (widget.status) {
      case PathNodeStatus.locked:
        return 'Locked';
      case PathNodeStatus.available:
        return 'Available';
      case PathNodeStatus.inProgress:
        return 'In Progress';
      case PathNodeStatus.completed:
        return 'Completed';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _entranceController,
      builder: (context, _) {
        return Opacity(
          opacity: _entranceFade.value,
          child: Transform.scale(
            scale: _entranceScale.value,
            child: _buildAnimatedNode(),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedNode() {
    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _bounceAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: _handleTap,
        child: _buildOpacityWrapper(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Node circle
              _buildNodeCircle(),
              const SizedBox(height: 8),
              // Title
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
              const SizedBox(height: 4),
              // XP reward badge
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
    return Opacity(opacity: _opacity, child: child);
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
          width: widget.status == PathNodeStatus.available ? 3 : 2,
        ),
        boxShadow: widget.status == PathNodeStatus.completed
            ? [
                BoxShadow(
                  color: AppColors.successGreen.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : widget.status == PathNodeStatus.available
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
          // In-progress partial fill effect (animated)
          if (widget.status == PathNodeStatus.inProgress)
            AnimatedBuilder(
              animation: _fillController,
              builder: (context, _) {
                return Positioned.fill(
                  child: ClipOval(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: FractionallySizedBox(
                        heightFactor: 0.4 * _fillController.value,
                        widthFactor: 1.0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.richGold.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
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

    // Wrap available nodes with BreathingFloat + PulseGlow
    if (widget.status == PathNodeStatus.available) {
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
