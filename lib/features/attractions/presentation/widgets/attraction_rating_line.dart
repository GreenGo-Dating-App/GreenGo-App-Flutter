import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/attraction_rating.dart';

/// "★ 4.6 (23)" for GreenGo users' rating, "★ 4.5" for the Google fallback.
/// Renders nothing when [display] is null (see [AttractionRatingDisplay.of]).
class AttractionRatingLine extends StatelessWidget {
  const AttractionRatingLine({
    super.key,
    required this.display,
    this.fontSize = 10,
    this.color = AppColors.textTertiary,
  });

  final AttractionRatingDisplay? display;
  final double fontSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final d = display;
    if (d == null) return const SizedBox.shrink();
    final text = d.isGreenGo ? '${d.valueLabel} (${d.count})' : d.valueLabel;
    return Row(
      key: const ValueKey('attrRatingLine'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: fontSize + 1, color: AppColors.richGold),
        const SizedBox(width: 2),
        Flexible(
          child: Text(text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontSize: fontSize)),
        ),
      ],
    );
  }
}
