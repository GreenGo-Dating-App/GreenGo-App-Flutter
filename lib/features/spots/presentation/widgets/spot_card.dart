import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/spot.dart';

/// A card widget displaying a cultural spot in a list.
///
/// Shows the spot's photo, name, category badge, rating stars,
/// review count, and optional distance.
class SpotCard extends StatelessWidget {
  final Spot spot;
  final VoidCallback? onTap;
  final double? distanceKm;

  const SpotCard({
    super.key,
    required this.spot,
    this.onTap,
    this.distanceKm,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider, width: 0.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo
            if (spot.photos.isNotEmpty)
              SizedBox(
                height: 160,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      spot.photos.first,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.backgroundInput,
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          color: AppColors.textTertiary,
                          size: 40,
                        ),
                      ),
                    ),
                    // Category badge overlay
                    Positioned(
                      top: 12,
                      left: 12,
                      child: _buildCategoryBadge(),
                    ),
                  ],
                ),
              )
            else
              Container(
                height: 120,
                width: double.infinity,
                color: AppColors.backgroundInput,
                child: Stack(
                  children: [
                    const Center(
                      child: Icon(
                        Icons.place_outlined,
                        color: AppColors.textTertiary,
                        size: 40,
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: _buildCategoryBadge(),
                    ),
                  ],
                ),
              ),
            // Info section
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    spot.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Rating and reviews row
                  Row(
                    children: [
                      // Stars
                      ..._buildStars(spot.rating),
                      const SizedBox(width: 6),
                      Text(
                        spot.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: AppColors.richGold,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '(${spot.reviewCount})',
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      // Distance (if provided)
                      if (distanceKm != null) ...[
                        const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.textTertiary,
                          size: 14,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '${distanceKm!.toStringAsFixed(1)} km',
                          style: const TextStyle(
                            color: AppColors.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getCategoryColor().withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getCategoryIcon(),
            color: Colors.white,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            spot.category.displayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildStars(double rating) {
    final List<Widget> stars = [];
    final fullStars = rating.floor();
    final hasHalfStar = (rating - fullStars) >= 0.5;

    for (int i = 0; i < 5; i++) {
      if (i < fullStars) {
        stars.add(const Icon(Icons.star, color: AppColors.richGold, size: 16));
      } else if (i == fullStars && hasHalfStar) {
        stars.add(
            const Icon(Icons.star_half, color: AppColors.richGold, size: 16));
      } else {
        stars.add(const Icon(Icons.star_border,
            color: AppColors.textTertiary, size: 16));
      }
    }
    return stars;
  }

  Color _getCategoryColor() {
    switch (spot.category) {
      case SpotCategory.restaurant:
        return const Color(0xFFE65100);
      case SpotCategory.cafe:
        return const Color(0xFF6D4C41);
      case SpotCategory.culturalSite:
        return const Color(0xFF1565C0);
      case SpotCategory.market:
        return const Color(0xFF2E7D32);
      case SpotCategory.viewpoint:
        return const Color(0xFF7B1FA2);
    }
  }

  IconData _getCategoryIcon() {
    switch (spot.category) {
      case SpotCategory.restaurant:
        return Icons.restaurant;
      case SpotCategory.cafe:
        return Icons.local_cafe;
      case SpotCategory.culturalSite:
        return Icons.account_balance;
      case SpotCategory.market:
        return Icons.storefront;
      case SpotCategory.viewpoint:
        return Icons.landscape;
    }
  }
}
