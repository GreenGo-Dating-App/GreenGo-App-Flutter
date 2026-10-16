import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// The app's menu-list row (owner, 2026-10-16: "the menu in Business Center >
/// Settings is the style I want for every menu list"): a flat card with a
/// plain icon, a title, a one-line subtitle and a chevron. Rows are spaced
/// with [MenuRow.gap].
class MenuRow extends StatelessWidget {
  const MenuRow({
    required this.title,
    required this.onTap,
    this.icon,
    this.leading,
    this.subtitle,
    this.subtitleColor,
    this.iconColor,
    this.subtitleMaxLines = 1,
    this.trailing,
    this.subtitleKey,
    super.key,
  });

  /// Space between two rows.
  static const double gap = 8;

  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  /// Leading icon (ignored when [leading] is given).
  final IconData? icon;
  final Widget? leading;
  final Color? iconColor;
  final Color? subtitleColor;

  /// `null` lets the subtitle wrap fully.
  final int? subtitleMaxLines;

  /// Defaults to a chevron.
  final Widget? trailing;

  /// Key on the subtitle text (tests).
  final Key? subtitleKey;

  @override
  Widget build(BuildContext context) {
    final sub = subtitle;
    return Material(
      color: AppColors.backgroundCard,
      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            leading ?? Icon(icon, color: iconColor ?? AppColors.richGold),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                if (sub != null && sub.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    sub,
                    key: subtitleKey,
                    maxLines: subtitleMaxLines,
                    overflow: subtitleMaxLines == null ? TextOverflow.visible : TextOverflow.ellipsis,
                    style: TextStyle(color: subtitleColor ?? AppColors.textSecondary, fontSize: 12.5),
                  ),
                ],
              ]),
            ),
            trailing ?? const Icon(Icons.chevron_right, color: AppColors.textTertiary),
          ]),
        ),
      ),
    );
  }
}
