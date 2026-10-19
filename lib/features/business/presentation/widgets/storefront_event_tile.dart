import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../data/business_upcoming_events.dart';

/// One event row on a business storefront (and its "See all" list).
class StorefrontEventTile extends StatelessWidget {
  const StorefrontEventTile({required this.event, required this.onTap, super.key});

  final StorefrontEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final e = event;
    final dpr = MediaQuery.of(context).devicePixelRatio;
    final locale = Localizations.localeOf(context).toLanguageTag();
    String fmt(DateTime d) {
      try {
        return DateFormat.yMMMEd(locale).add_Hm().format(d);
      } catch (_) {
        return DateFormat.yMMMEd().add_Hm().format(d);
      }
    }

    return InkWell(
      key: ValueKey('storefront-event-${e.id}'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.backgroundCard,
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.richGold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppDimensions.radiusS),
                image: e.imageUrl != null
                    ? DecorationImage(
                        image: ResizeImage.resizeIfNeeded((48 * dpr).round(),
                            null, CachedNetworkImageProvider(e.imageUrl!)),
                        fit: BoxFit.cover)
                    : null,
              ),
              child: e.imageUrl == null
                  ? const Icon(Icons.event, color: AppColors.richGold)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (e.startDate != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      fmt(e.startDate!),
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
