import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/glass_container.dart';
import '../../../../generated/app_localizations.dart';
import '../../../events/presentation/screens/event_detail_loader_screen.dart';
import '../../domain/entities/community.dart';

/// Pinned promo card rendered at the very top of a sponsored community.
///
/// Glass surface with a gold "Sponsored" accent pill. Tapping it opens the
/// linked in-app event (via [EventDetailLoaderScreen]) when [PinnedPromo.linkEventId]
/// is set, otherwise the external [PinnedPromo.linkUrl].
class SponsoredPromoCard extends StatelessWidget {
  const SponsoredPromoCard({
    required this.promo,
    required this.currentUserId,
    super.key,
  });

  final PinnedPromo promo;
  final String currentUserId;

  Future<void> _handleTap(BuildContext context) async {
    final eventId = promo.linkEventId;
    if (eventId != null && eventId.isNotEmpty) {
      await Navigator.of(context).push(
        EventDetailLoaderScreen.route(
          eventId: eventId,
          currentUserId: currentUserId,
        ),
      );
      return;
    }

    final url = promo.linkUrl;
    if (url != null && url.isNotEmpty) {
      final uri = Uri.tryParse(url);
      if (uri != null) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      child: GlassContainer(
        active: true,
        borderRadius: 16,
        onTap: promo.hasTarget ? () => _handleTap(context) : null,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // "Sponsored" accent pill row
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.accentGold, AppColors.richGold],
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.workspace_premium,
                        size: 12,
                        color: AppColors.deepBlack,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.communitiesSponsored,
                        style: const TextStyle(
                          color: AppColors.deepBlack,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (promo.hasTarget)
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 13,
                    color: AppColors.richGold,
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // Optional promo image
            if (promo.imageUrl != null && promo.imageUrl!.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    promo.imageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.backgroundCard,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Title
            Text(
              promo.title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),

            // Body
            Text(
              promo.body,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.35,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
