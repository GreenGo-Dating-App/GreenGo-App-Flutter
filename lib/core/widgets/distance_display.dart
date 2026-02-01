import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Enhancement #16: Distance Display
/// Shows distance between users
class DistanceDisplay extends StatelessWidget {
  final double distanceKm;
  final bool isCompact;
  final bool showIcon;

  const DistanceDisplay({
    super.key,
    required this.distanceKm,
    this.isCompact = false,
    this.showIcon = true,
  });

  String _formatDistance() {
    if (distanceKm < 1) {
      return '< 1 km';
    } else if (distanceKm < 10) {
      return '${distanceKm.toStringAsFixed(1)} km';
    } else {
      return '${distanceKm.toInt()} km';
    }
  }

  Color _getDistanceColor() {
    if (distanceKm < 5) return AppColors.successGreen;
    if (distanceKm < 20) return AppColors.richGold;
    if (distanceKm < 50) return AppColors.warningAmber;
    return AppColors.textTertiary;
  }

  @override
  Widget build(BuildContext context) {
    if (isCompact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon)
            Icon(
              Icons.location_on,
              size: 14,
              color: _getDistanceColor(),
            ),
          if (showIcon) const SizedBox(width: 2),
          Text(
            _formatDistance(),
            style: TextStyle(
              color: _getDistanceColor(),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _getDistanceColor().withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getDistanceColor().withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on,
            size: 16,
            color: _getDistanceColor(),
          ),
          const SizedBox(width: 4),
          Text(
            _formatDistance(),
            style: TextStyle(
              color: _getDistanceColor(),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'away',
            style: TextStyle(
              color: _getDistanceColor().withOpacity(0.7),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

/// Distance badge for profile cards
class DistanceBadge extends StatelessWidget {
  final double distanceKm;

  const DistanceBadge({
    super.key,
    required this.distanceKm,
  });

  @override
  Widget build(BuildContext context) {
    final isNearby = distanceKm < 5;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isNearby
            ? AppColors.successGreen.withOpacity(0.9)
            : AppColors.backgroundCard.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isNearby ? Icons.near_me : Icons.location_on,
            size: 12,
            color: isNearby ? Colors.white : AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            distanceKm < 1
                ? 'Nearby'
                : distanceKm < 10
                    ? '${distanceKm.toStringAsFixed(1)} km'
                    : '${distanceKm.toInt()} km',
            style: TextStyle(
              color: isNearby ? Colors.white : AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
