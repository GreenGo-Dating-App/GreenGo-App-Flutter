import 'package:flutter/material.dart';
import '../../../profile/domain/entities/profile.dart';

/// Traveler Overlay Widget
///
/// Overlay for swipe/grid cards when the user is an active traveler.
/// Shows origin city -> current traveling city, flight icon, and "Traveler" badge.
class TravelerOverlay extends StatelessWidget {
  /// The traveler's profile
  final Profile profile;

  /// Whether to use compact mode (for grid cards)
  final bool compact;

  const TravelerOverlay({
    super.key,
    required this.profile,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!profile.isTravelerActive) return const SizedBox.shrink();

    final originCity = profile.location.city.isNotEmpty
        ? profile.location.city
        : profile.location.country;
    final travelCity = profile.travelerLocation?.city ?? '';

    if (compact) return _buildCompact(originCity, travelCity);
    return _buildFull(originCity, travelCity);
  }

  Widget _buildCompact(String originCity, String travelCity) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1565C0).withOpacity(0.9),
            const Color(0xFF1E88E5).withOpacity(0.9),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.flight, size: 10, color: Colors.white),
          const SizedBox(width: 3),
          if (travelCity.isNotEmpty)
            Flexible(
              child: Text(
                travelCity,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            )
          else
            const Text(
              'Traveler',
              style: TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFull(String originCity, String travelCity) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1565C0), Color(0xFF1E88E5)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withOpacity(0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Traveler badge
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.flight, size: 14, color: Colors.white),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Traveler',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (originCity.isNotEmpty && travelCity.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      originCity,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 10,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        Icons.arrow_forward,
                        size: 10,
                        color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                    Text(
                      travelCity,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              else if (travelCity.isNotEmpty)
                Text(
                  'In $travelCity',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 10,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
