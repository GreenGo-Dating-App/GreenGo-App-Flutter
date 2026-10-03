import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/attraction_icons.dart';
import '../../domain/entities/attraction.dart';

/// The GreenGo Score pill (0-100, tier-coloured) of an attraction card —
/// shared by the Attractions tab cards and Explore "Featured attractions" so
/// both read the same.
class AttractionScoreBadge extends StatelessWidget {
  const AttractionScoreBadge(
      {super.key, required this.attraction, this.size = 11});

  final Attraction attraction;

  /// Font size; the padding scales with it.
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = AttractionIcons.tierColor(attraction.scoreTier);
    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: size * 0.5, vertical: size * 0.16),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text('${attraction.greengoScore}',
          style: TextStyle(
              color: AppColors.deepBlack,
              fontSize: size,
              fontWeight: FontWeight.bold)),
    );
  }
}
