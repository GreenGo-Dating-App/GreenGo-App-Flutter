import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../../core/config/flavor_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/country_names_l10n.dart';
import '../../../../generated/app_localizations.dart';
import '../../domain/entities/country_spotlight.dart';

/// Featured card for displaying the active country spotlight
class CountrySpotlightCard extends StatelessWidget {

  const CountrySpotlightCard({
    required this.spotlight, super.key,
    this.onTap,
  });
  final CountrySpotlight spotlight;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.backgroundCard,
          boxShadow: [
            BoxShadow(
              color: AppColors.richGold.withValues(alpha: 0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background image
            if (spotlight.imageUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: spotlight.imageUrl,
                fit: BoxFit.cover,
                memCacheWidth: 900,
                errorWidget: (context, _, __) => Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.richGold.withValues(alpha: 0.3),
                        AppColors.backgroundDark,
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.public,
                      size: 64,
                      color: AppColors.richGold,
                    ),
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.richGold.withValues(alpha: 0.3),
                      AppColors.backgroundDark,
                    ],
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.public,
                    size: 64,
                    color: AppColors.richGold,
                  ),
                ),
              ),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.backgroundDark.withValues(alpha: 0.8),
                    AppColors.backgroundDark,
                  ],
                  stops: const [0.3, 0.7, 1.0],
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.richGold,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      l10n.culturalExchangeSpotlightBadge,
                      style: const TextStyle(
                        color: AppColors.deepBlack,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Country name
                  Text(
                    localizedCountryName(l10n, spotlight.country),
                    style: const TextStyle(
                      color: AppColors.richGold,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Title
                  Text(
                    spotlight.title,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Sections preview
                  Row(
                    children: [
                      if (spotlight.cuisine != null)
                        _buildSectionChip(l10n.culturalExchangeSectionCuisine),
                      if (spotlight.customs != null)
                        _buildSectionChip(l10n.culturalExchangeSectionCustoms),
                      if (FlavorConfig.enableEtiquetteGuide &&
                          spotlight.datingEtiquette != null)
                        _buildSectionChip(l10n.culturalExchangeCategoryDating),
                      if (spotlight.keyPhrases != null)
                        _buildSectionChip(l10n.culturalExchangeSectionPhrases),
                    ],
                  ),
                ],
              ),
            ),

            // Tap indicator
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.backgroundDark.withValues(alpha: 0.6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward,
                  color: AppColors.richGold,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionChip(String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.backgroundInput.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.divider,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
