import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// One call-to-action of a [HelpfulEmptyState].
class HelpfulEmptyAction {
  const HelpfulEmptyAction({
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
}

/// Empty state that tells the user what to do next instead of only saying
/// "nothing here": an icon, one sentence and up to two action buttons.
///
/// The first action is the primary (gold) button, the second an outlined one.
class HelpfulEmptyState extends StatelessWidget {
  const HelpfulEmptyState({
    required this.icon,
    required this.message,
    super.key,
    this.title,
    this.actions = const <HelpfulEmptyAction>[],
    this.compact = false,
  });

  final IconData icon;
  final String? title;
  final String message;
  final List<HelpfulEmptyAction> actions;

  /// Smaller paddings/icon for use inside cards or short tabs.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    assert(actions.length <= 2, 'At most two actions');
    final padding = EdgeInsets.symmetric(
      horizontal: 32,
      vertical: compact ? 16 : 32,
    );
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 56 : 72,
          height: compact ? 56 : 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.richGold.withValues(alpha: 0.12),
          ),
          child: Icon(
            icon,
            size: compact ? 28 : 36,
            color: AppColors.richGold,
          ),
        ),
        SizedBox(height: compact ? 12 : 18),
        if (title != null) ...[
          Text(
            title!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
            height: 1.45,
          ),
        ),
        if (actions.isNotEmpty) SizedBox(height: compact ? 14 : 22),
        for (var i = 0; i < actions.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _buildButton(actions[i], primary: i == 0),
        ],
      ],
    );
    // Scrolls when space is short; inside another scroll view (unbounded
    // height) it lays out as a plain column.
    return LayoutBuilder(
      builder: (context, constraints) => Center(
        child: constraints.hasBoundedHeight
            ? SingleChildScrollView(padding: padding, child: content)
            : Padding(padding: padding, child: content),
      ),
    );
  }

  Widget _buildButton(HelpfulEmptyAction a, {required bool primary}) {
    final child = Text(
      a.label,
      textAlign: TextAlign.center,
      style: const TextStyle(fontWeight: FontWeight.w600),
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );
    if (primary) {
      return a.icon == null
          ? ElevatedButton(
              onPressed: a.onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.richGold,
                foregroundColor: AppColors.deepBlack,
                shape: shape,
              ),
              child: child,
            )
          : ElevatedButton.icon(
              onPressed: a.onPressed,
              icon: Icon(a.icon, size: 18),
              label: child,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.richGold,
                foregroundColor: AppColors.deepBlack,
                shape: shape,
              ),
            );
    }
    final style = OutlinedButton.styleFrom(
      foregroundColor: AppColors.richGold,
      side: BorderSide(color: AppColors.richGold.withValues(alpha: 0.6)),
      shape: shape,
    );
    return a.icon == null
        ? OutlinedButton(onPressed: a.onPressed, style: style, child: child)
        : OutlinedButton.icon(
            onPressed: a.onPressed,
            icon: Icon(a.icon, size: 18),
            label: child,
            style: style,
          );
  }
}
