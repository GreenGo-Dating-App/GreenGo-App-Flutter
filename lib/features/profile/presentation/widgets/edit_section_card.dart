import 'package:flutter/material.dart';

import '../../../../core/widgets/menu_row.dart';

/// A menu entry of the profile / business lists. Rendered as the app-wide
/// [MenuRow] (Business Center > Settings style, owner 2026-10-16).
class EditSectionCard extends StatelessWidget {
  const EditSectionCard({
    required this.title, required this.subtitle, required this.icon, required this.onTap, super.key,
    this.subtitleMaxLines = 1,
  });
  final String title;
  final String subtitle;

  /// Max lines for [subtitle]; `null` lets it wrap fully (no ellipsis), for
  /// subtitles that carry information the user must read in full.
  final int? subtitleMaxLines;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => MenuRow(
        title: title,
        subtitle: subtitle,
        icon: icon,
        onTap: onTap,
        subtitleMaxLines: subtitleMaxLines,
      );
}
