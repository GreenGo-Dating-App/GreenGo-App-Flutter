import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/widgets/interactive_location_map.dart'
    show LocationMapColors;
import '../../domain/entities/globe_user.dart';

/// Ring colour of the signed-in user's own pin (connections are gold).
const Color kGlobeSelfColor = Color(0xFFD64545);

/// Traveler badge / flight-path colour.
const Color kGlobeTravelerColor = Color(0xFF1E88E5);

/// Online dot colour.
const Color kGlobeOnlineColor = Color(0xFF2E9E5B);

/// Ring / badge colour of a business pin.
const Color kGlobeBusinessColor = Color(0xFF00897B);

/// Badge icon + colour per network relation (pin badges, chips, legend).
IconData globeRelationIcon(GlobeRelation r) => switch (r) {
      GlobeRelation.following => Icons.person_add_alt_1,
      GlobeRelation.follower => Icons.group,
      GlobeRelation.chatted => Icons.chat_bubble,
    };

Color globeRelationColor(GlobeRelation r) => switch (r) {
      GlobeRelation.following => const Color(0xFF7E57C2),
      GlobeRelation.follower => const Color(0xFFEF6C00),
      GlobeRelation.chatted => const Color(0xFF1E88E5),
    };

/// A person on the network map: round photo with a ring (gold for a
/// connection, red for the user), online dot, traveler badge and, for the
/// user, a "You" tag. Stateless and cheap: the photo is decoded at ~2x the
/// pin size and comes from the shared image cache.
class GlobeAvatarPin extends StatelessWidget {
  const GlobeAvatarPin({
    required this.name,
    super.key,
    this.photoUrl,
    this.isOnline = false,
    this.isTraveler = false,
    this.selfLabel,
    this.relations = const {},
    this.isBusiness = false,
  });

  /// Pin diameter for a connection / for the user.
  static const double size = 44;
  static const double selfSize = 50;

  /// Marker box that fits the pin, its badges and the "You" tag.
  static const double boxWidth = selfSize + 12;
  static const double boxHeight = selfSize + 18;

  /// Marker box of a business pin (wider: its name is shown under it).
  static const double businessBoxWidth = 104;
  static const double businessBoxHeight = selfSize + 24;

  final String name;
  final String? photoUrl;
  final bool isOnline;
  final bool isTraveler;

  /// Non-null for the user's own pin: the tag shown under it.
  final String? selfLabel;

  /// How the person / business is connected to the user (small badges).
  final Set<GlobeRelation> relations;

  /// A business: square-ish pin, storefront badge, name under it.
  final bool isBusiness;

  bool get _isSelf => selfLabel != null;

  Widget _initial() => Container(
        color: LocationMapColors.background,
        alignment: Alignment.center,
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: LocationMapColors.goldDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  static Widget _badge(IconData icon, Color color, double size, double iconSize) =>
      Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: LocationMapColors.surface, width: 1.5),
        ),
        child: Icon(icon, color: LocationMapColors.surface, size: iconSize),
      );

  @override
  Widget build(BuildContext context) {
    final d = _isSelf ? selfSize : size;
    final ring = _isSelf
        ? kGlobeSelfColor
        : (isBusiness ? kGlobeBusinessColor : LocationMapColors.gold);
    final url = photoUrl;
    final shape = isBusiness
        ? BoxShape.rectangle
        : BoxShape.circle;
    final radius = isBusiness ? BorderRadius.circular(12) : null;
    final ordered = [
      for (final r in GlobeRelation.values)
        if (relations.contains(r)) r,
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: d,
              height: d,
              decoration: BoxDecoration(
                shape: shape,
                borderRadius: radius,
                color: LocationMapColors.surface,
                border: Border.all(color: ring, width: 3),
                boxShadow: const [
                  BoxShadow(color: Color(0x55000000), blurRadius: 4),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(isBusiness ? 9 : d),
                child: url == null || url.isEmpty
                    ? _initial()
                    : CachedNetworkImage(
                        imageUrl: url,
                        fit: BoxFit.cover,
                        // Tiny pin: decode ~2x its box, not the full photo.
                        memCacheWidth: (d * 2).round(),
                        fadeInDuration: Duration.zero,
                        placeholder: (_, __) => _initial(),
                        errorWidget: (_, __, ___) => _initial(),
                      ),
              ),
            ),
            if (isOnline)
              Positioned(
                right: -1,
                top: -1,
                child: Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    color: kGlobeOnlineColor,
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: LocationMapColors.surface, width: 2),
                  ),
                ),
              ),
            if (isBusiness)
              Positioned(
                left: -4,
                top: -4,
                child: _badge(Icons.storefront, kGlobeBusinessColor, 18, 10),
              ),
            if (ordered.isNotEmpty)
              Positioned(
                right: -6,
                bottom: -4,
                child: Row(
                  key: const ValueKey('globe-pin-badges'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final r in ordered)
                      Padding(
                        padding: const EdgeInsets.only(left: 1),
                        child: _badge(globeRelationIcon(r),
                            globeRelationColor(r), 15, 8),
                      ),
                  ],
                ),
              ),
            if (isTraveler && !isBusiness)
              Positioned(
                left: -4,
                top: -4,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: kGlobeTravelerColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: LocationMapColors.surface, width: 1.5),
                  ),
                  child: const Icon(Icons.flight,
                      color: LocationMapColors.surface, size: 10),
                ),
              ),
          ],
        ),
        if (isBusiness && !_isSelf)
          Transform.translate(
            offset: const Offset(0, 1),
            child: Container(
              constraints:
                  const BoxConstraints(maxWidth: businessBoxWidth - 4),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: LocationMapColors.surface.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: kGlobeBusinessColor, width: 0.8),
              ),
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: LocationMapColors.text,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        if (_isSelf)
          Transform.translate(
            offset: const Offset(0, -6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: kGlobeSelfColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                selfLabel!,
                style: const TextStyle(
                  color: LocationMapColors.surface,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
