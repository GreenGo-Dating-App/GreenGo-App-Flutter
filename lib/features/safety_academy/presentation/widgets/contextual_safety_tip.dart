import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

/// Collapsible banner widget that shows contextual safety tips in chat.
///
/// Monitors message text for keywords related to meeting up (e.g., "meet",
/// "coffee", "date", "address", "where") and displays a relevant safety
/// tip in a dismissible card at the top of the chat.
class ContextualSafetyTip extends StatefulWidget {
  /// The latest message text to check for trigger keywords
  final String messageText;

  /// Optional callback when the tip is dismissed
  final VoidCallback? onDismiss;

  const ContextualSafetyTip({
    super.key,
    required this.messageText,
    this.onDismiss,
  });

  @override
  State<ContextualSafetyTip> createState() => _ContextualSafetyTipState();
}

class _ContextualSafetyTipState extends State<ContextualSafetyTip>
    with SingleTickerProviderStateMixin {
  bool _isDismissed = false;
  bool _isExpanded = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  /// Keywords that trigger meeting-related safety tips
  static const _meetingKeywords = [
    'meet',
    'meeting',
    'coffee',
    'date',
    'address',
    'where',
    'location',
    'place',
    'pick up',
    'pickup',
    'come over',
    'my place',
    'your place',
    'hotel',
    'apartment',
    'house',
    'drink',
    'drinks',
    'dinner',
    'lunch',
  ];

  /// Safety tips to rotate through
  static const _safetyTips = [
    'Always meet in a public place for your first few dates.',
    'Share your date plans with a friend or family member.',
    'Arrange your own transportation to and from the date.',
    'Trust your instincts. If something feels off, it is okay to leave.',
    'Keep your personal information (home address, workplace) private until you feel safe.',
    'Consider a video call before meeting in person for the first time.',
  ];

  bool get _shouldShow {
    if (_isDismissed) return false;
    final text = widget.messageText.toLowerCase();
    return _meetingKeywords.any((keyword) => text.contains(keyword));
  }

  String get _tipText {
    // Deterministic tip selection based on message content hash
    final hash = widget.messageText.hashCode.abs();
    return _safetyTips[hash % _safetyTips.length];
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    if (_shouldShow) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(ContextualSafetyTip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.messageText != oldWidget.messageText) {
      _isDismissed = false;
      if (_shouldShow) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_shouldShow) return const SizedBox.shrink();

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.infoBlue.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            // Header (always visible)
            InkWell(
              onTap: () => setState(() => _isExpanded = !_isExpanded),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
                bottom: Radius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.shield,
                      color: AppColors.infoBlue,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Safety Tip',
                        style: TextStyle(
                          color: AppColors.infoBlue,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Collapse / expand
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: AppColors.textTertiary,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    // Dismiss button
                    GestureDetector(
                      onTap: () {
                        setState(() => _isDismissed = true);
                        _animationController.reverse();
                        widget.onDismiss?.call();
                      },
                      child: const Icon(
                        Icons.close,
                        color: AppColors.textTertiary,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Tip content (collapsible)
            AnimatedCrossFade(
              firstChild: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Text(
                  _tipText,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
              secondChild: const SizedBox.shrink(),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }
}
