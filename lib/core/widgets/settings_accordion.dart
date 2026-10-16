import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import 'menu_row.dart';

/// A collapsible settings category used on the Profile screen.
///
/// The header is a [MenuRow] (the app's menu style, owner 2026-10-16) with an
/// expand / collapse arrow; when open, the grouped rows show right under it,
/// slightly indented. The rows keep their state while collapsed.
class SettingsAccordion extends StatefulWidget {
  const SettingsAccordion({
    required this.title, required this.icon, required this.children, super.key,
    this.initiallyExpanded = false,
    this.accentColor,
  });
  final String title;
  final IconData icon;
  final List<Widget> children;
  final bool initiallyExpanded;
  final Color? accentColor;

  @override
  State<SettingsAccordion> createState() => _SettingsAccordionState();
}

class _SettingsAccordionState extends State<SettingsAccordion> {
  late bool _open = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor ?? AppColors.richGold;
    return Padding(
      padding: const EdgeInsets.only(bottom: MenuRow.gap),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        MenuRow(
          title: widget.title,
          icon: widget.icon,
          iconColor: accent,
          onTap: () => setState(() => _open = !_open),
          trailing: AnimatedRotation(
            turns: _open ? 0.5 : 0,
            duration: const Duration(milliseconds: 200),
            child: Icon(Icons.expand_more, color: accent),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: Visibility(
            visible: _open,
            maintainState: true,
            child: Padding(
              padding: const EdgeInsets.only(left: 12, top: MenuRow.gap),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: widget.children),
            ),
          ),
        ),
      ]),
    );
  }
}
