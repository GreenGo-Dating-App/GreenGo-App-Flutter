import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Enhancement #13: Undo Swipe Button
/// Allows users to undo their last swipe (premium feature)
class UndoSwipeButton extends StatefulWidget {
  final bool isEnabled;
  final bool isPremiumFeature;
  final int remainingUndos;
  final VoidCallback? onUndo;
  final VoidCallback? onUpgradePressed;

  const UndoSwipeButton({
    super.key,
    this.isEnabled = true,
    this.isPremiumFeature = false,
    this.remainingUndos = -1, // -1 means unlimited
    this.onUndo,
    this.onUpgradePressed,
  });

  @override
  State<UndoSwipeButton> createState() => _UndoSwipeButtonState();
}

class _UndoSwipeButtonState extends State<UndoSwipeButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _rotateAnimation = Tween<double>(begin: 0.0, end: -0.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.isEnabled) {
      if (widget.isPremiumFeature) {
        widget.onUpgradePressed?.call();
      }
      return;
    }

    _controller.forward().then((_) {
      _controller.reverse();
      widget.onUndo?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final canUndo = widget.isEnabled &&
        (widget.remainingUndos == -1 || widget.remainingUndos > 0);

    return GestureDetector(
      onTap: _handleTap,
      child: Stack(
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotateAnimation.value,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: canUndo
                        ? AppColors.warningAmber
                        : AppColors.backgroundInput,
                    shape: BoxShape.circle,
                    boxShadow: canUndo
                        ? [
                            BoxShadow(
                              color: AppColors.warningAmber.withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    Icons.replay,
                    color: canUndo ? Colors.white : AppColors.textTertiary,
                    size: 28,
                  ),
                ),
              );
            },
          ),
          // Premium lock indicator
          if (widget.isPremiumFeature && !widget.isEnabled)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: AppColors.richGold,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock,
                  color: AppColors.deepBlack,
                  size: 12,
                ),
              ),
            ),
          // Remaining count indicator
          if (widget.remainingUndos > 0 && widget.remainingUndos < 10)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.richGold,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${widget.remainingUndos}',
                  style: const TextStyle(
                    color: AppColors.deepBlack,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
