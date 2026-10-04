import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/attraction_icons.dart';
import '../../domain/attraction_rating.dart';
import '../../domain/entities/attraction.dart';
import 'attraction_rating_line.dart';
import 'attraction_score_badge.dart';

/// One cell of the Attractions grid.
///
/// Image (with its overlays: GreenGo Score, importance, UNESCO and — when the
/// licence requires it — the photo credit), then EXACTLY these text lines:
///  1. title (max 2 lines)
///  2. "City - Country" (1 line)
///  3. distance from the user (hidden when unknown)
///  4. rating: GreenGo users' ★ avg (count), else Google ★, else nothing.
///
/// The image is the flexible part, so the cell's aspect ratio holds whatever
/// lines are present (no overflow at 320 px / 3 columns in any locale).
class AttractionGridTile extends StatelessWidget {
  const AttractionGridTile({
    super.key,
    required this.attraction,
    required this.image,
    required this.cityCountry,
    required this.onTap,
    this.distance,
    this.rating,
    this.attribution,
  });

  final Attraction attraction;
  final Widget image;
  final String cityCountry;
  final String? distance;
  final AttractionRatingDisplay? rating;

  /// Photo credit (only when the image licence demands one).
  final String? attribution;
  final VoidCallback onTap;

  static const TextStyle _sub =
      TextStyle(color: AppColors.textSecondary, fontSize: 10);
  static const TextStyle _muted =
      TextStyle(color: AppColors.textTertiary, fontSize: 10);

  @override
  Widget build(BuildContext context) {
    final a = attraction;
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          color: AppColors.backgroundCard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(fit: StackFit.expand, children: [
                  Semantics(label: a.altText ?? a.name, child: image),
                  Positioned(
                      top: 4,
                      left: 4,
                      child: AttractionScoreBadge(attraction: a, size: 10)),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Icon(AttractionIcons.importance(a.importanceIcon),
                        size: 14,
                        color: AttractionIcons.importanceColor(a.importanceKey)),
                  ),
                  if (attribution != null)
                    Positioned(
                      left: a.unesco ? 20 : 4,
                      right: 4,
                      bottom: 3,
                      child: Text(
                        attribution!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 7.5,
                          shadows: [Shadow(blurRadius: 3, color: Colors.black)],
                        ),
                      ),
                    ),
                  if (a.unesco)
                    const Positioned(
                        bottom: 4,
                        left: 4,
                        child: Icon(Icons.verified,
                            size: 13, color: AppColors.richGold)),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.all(6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(a.name,
                        key: const ValueKey('attrTileTitle'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(cityCountry,
                        key: const ValueKey('attrTilePlace'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _sub),
                    if (distance != null)
                      Text(distance!,
                          key: const ValueKey('attrTileDistance'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: _muted),
                    if (rating != null)
                      AttractionRatingLine(display: rating, fontSize: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
