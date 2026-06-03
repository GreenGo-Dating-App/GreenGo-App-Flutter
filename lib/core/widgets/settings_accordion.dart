import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// A collapsible/expandable settings category used on the Profile screen.
///
/// Renders a styled [ExpansionTile] (dark + gold theme) with a leading icon and
/// title; tapping the header expands/collapses the grouped settings cards.
class SettingsAccordion extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final bool initiallyExpanded;
  final Color? accentColor;

  const SettingsAccordion({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.initiallyExpanded = false,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? AppColors.richGold;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider.withValues(alpha: 0.6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        // Hide ExpansionTile's default top/bottom divider lines.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          maintainState: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          iconColor: accent,
          collapsedIconColor: accent,
          leading: Icon(icon, color: accent),
          title: Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          children: children,
        ),
      ),
    );
  }
}
