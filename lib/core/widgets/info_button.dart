import 'package:flutter/material.dart';

import '../../generated/app_localizations.dart';
import '../constants/app_colors.dart';
import 'explain_sheet.dart';

/// Small (i) icon that opens a glass bottom sheet with a title and a short
/// explanation. Place it next to a label whose meaning is not obvious
/// (visibility options, fees, plan offers...).
///
/// The tap target is 40x40 (visual icon [size]) and carries a localized
/// tooltip + semantic label ("More info: <title>").
class InfoButton extends StatelessWidget {
  const InfoButton({
    required this.title,
    required this.message,
    super.key,
    this.bullets = const <String>[],
    this.size = 18,
    this.color,
    this.icon = Icons.info_outline,
  });

  final String title;
  final String message;
  final List<String> bullets;
  final double size;
  final Color? color;
  final IconData icon;

  /// Shows the explanation sheet without a button (e.g. from a menu row).
  static Future<void> showInfoSheet(
    BuildContext context, {
    required String title,
    required String message,
    List<String> bullets = const <String>[],
    IconData icon = Icons.info_outline,
  }) {
    return showExplainSheet<void>(
      context,
      builder: (ctx) => ExplainSheetFrame(
        title: title,
        message: message,
        bullets: bullets,
        icon: icon,
        actions: [
          ExplainPrimaryButton(
            label: explainGotIt(ctx),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final label = AppLocalizations.of(context)!.xplMoreInfoAbout(title);
    return IconButton(
      tooltip: label,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      iconSize: size,
      icon: Icon(
        icon,
        color: color ?? AppColors.textTertiary,
        semanticLabel: label,
      ),
      onPressed: () => showInfoSheet(
        context,
        title: title,
        message: message,
        bullets: bullets,
      ),
    );
  }
}
