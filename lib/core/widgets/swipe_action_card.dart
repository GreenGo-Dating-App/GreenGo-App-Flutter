import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Enhancement #20 & #21: Swipe Actions for Block/Report
/// Swipeable card with block and report actions
class SwipeActionCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onBlock;
  final VoidCallback? onReport;
  final VoidCallback? onDelete;
  final bool enableBlock;
  final bool enableReport;
  final bool enableDelete;

  const SwipeActionCard({
    super.key,
    required this.child,
    this.onBlock,
    this.onReport,
    this.onDelete,
    this.enableBlock = true,
    this.enableReport = true,
    this.enableDelete = false,
  });

  @override
  State<SwipeActionCard> createState() => _SwipeActionCardState();
}

class _SwipeActionCardState extends State<SwipeActionCard> {
  double _dragOffset = 0;
  final double _actionThreshold = 80;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragUpdate: (details) {
        setState(() {
          _dragOffset += details.delta.dx;
          // Limit drag range
          _dragOffset = _dragOffset.clamp(-160.0, 0.0);
        });
      },
      onHorizontalDragEnd: (details) {
        if (_dragOffset < -_actionThreshold * 1.5) {
          // Keep showing actions
          setState(() {
            _dragOffset = -160;
          });
        } else {
          // Snap back
          setState(() {
            _dragOffset = 0;
          });
        }
      },
      child: Stack(
        children: [
          // Action buttons behind
          Positioned.fill(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (widget.enableReport)
                  _ActionButton(
                    icon: Icons.flag,
                    label: 'Report',
                    color: AppColors.warningAmber,
                    onTap: () {
                      _resetDrag();
                      widget.onReport?.call();
                    },
                  ),
                if (widget.enableBlock)
                  _ActionButton(
                    icon: Icons.block,
                    label: 'Block',
                    color: AppColors.errorRed,
                    onTap: () {
                      _resetDrag();
                      widget.onBlock?.call();
                    },
                  ),
                if (widget.enableDelete)
                  _ActionButton(
                    icon: Icons.delete,
                    label: 'Delete',
                    color: AppColors.errorRed,
                    onTap: () {
                      _resetDrag();
                      widget.onDelete?.call();
                    },
                  ),
              ],
            ),
          ),
          // Main content
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            transform: Matrix4.translationValues(_dragOffset, 0, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }

  void _resetDrag() {
    setState(() {
      _dragOffset = 0;
    });
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        color: color,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Quick action buttons row
class QuickActionButtons extends StatelessWidget {
  final VoidCallback? onBlock;
  final VoidCallback? onReport;
  final VoidCallback? onUnmatch;

  const QuickActionButtons({
    super.key,
    this.onBlock,
    this.onReport,
    this.onUnmatch,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _QuickActionButton(
          icon: Icons.flag_outlined,
          label: 'Report',
          color: AppColors.warningAmber,
          onTap: onReport,
        ),
        _QuickActionButton(
          icon: Icons.block,
          label: 'Block',
          color: AppColors.errorRed,
          onTap: onBlock,
        ),
        _QuickActionButton(
          icon: Icons.heart_broken,
          label: 'Unmatch',
          color: AppColors.textTertiary,
          onTap: onUnmatch,
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
