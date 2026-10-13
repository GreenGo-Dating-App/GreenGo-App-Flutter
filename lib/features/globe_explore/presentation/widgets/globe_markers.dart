import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/widgets/interactive_location_map.dart'
    show LocationMapColors;

/// Ring colour of the signed-in user's own pin (connections are gold).
const Color kGlobeSelfColor = Color(0xFFD64545);

/// Traveler badge / flight-path colour.
const Color kGlobeTravelerColor = Color(0xFF1E88E5);

/// Online dot colour.
const Color kGlobeOnlineColor = Color(0xFF2E9E5B);

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
  });

  /// Pin diameter for a connection / for the user.
  static const double size = 44;
  static const double selfSize = 50;

  /// Marker box that fits the pin, its badges and the "You" tag.
  static const double boxWidth = selfSize + 12;
  static const double boxHeight = selfSize + 18;

  final String name;
  final String? photoUrl;
  final bool isOnline;
  final bool isTraveler;

  /// Non-null for the user's own pin: the tag shown under it.
  final String? selfLabel;

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

  @override
  Widget build(BuildContext context) {
    final d = _isSelf ? selfSize : size;
    final ring = _isSelf ? kGlobeSelfColor : LocationMapColors.gold;
    final url = photoUrl;
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
                shape: BoxShape.circle,
                color: LocationMapColors.surface,
                border: Border.all(color: ring, width: 3),
                boxShadow: const [
                  BoxShadow(color: Color(0x55000000), blurRadius: 4),
                ],
              ),
              child: ClipOval(
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
            if (isTraveler)
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
