import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../../events/domain/entities/external_event.dart';
import '../../../events/presentation/widgets/external_event_tiles.dart';
import '../../../user_experiences/domain/entities/user_experience.dart';
import '../../../user_experiences/presentation/widgets/experience_widgets.dart';
import '../../domain/top_experiences.dart';

/// Explore "Top experiences" — a horizontal row of up to 20 cards: featured
/// member experiences (gold frame + star), then top-rated member experiences
/// ([ExperienceCard]), then partner (Viator) ones ([ExternalEventGridTile] with
/// the "Partner" badge). [items] null (loading) or empty renders NOTHING (no
/// header, no skeleton) — the Explore rule for every section.
class TopExperiencesSection extends StatelessWidget {
  const TopExperiencesSection({
    super.key,
    required this.items,
    required this.reduceMotion,
    required this.onSeeAll,
    required this.onOpenCommunity,
    required this.onOpenPartner,
  });

  final List<TopExperienceItem>? items;
  final bool reduceMotion;
  final VoidCallback onSeeAll;
  final ValueChanged<UserExperience> onOpenCommunity;
  final ValueChanged<ExternalEvent> onOpenPartner;

  static const double cardWidth = 150;
  static const double cardHeight = 210;

  @override
  Widget build(BuildContext context) {
    final list = items;
    if (list == null || list.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    final l10n = AppLocalizations.of(context)!;
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.exploreTopExperiences,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onSeeAll,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    l10n.exploreSeeAll,
                    style: const TextStyle(
                      color: AppColors.richGold,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: cardHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: reduceMotion
                  ? const ClampingScrollPhysics()
                  : const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) => SizedBox(
                width: cardWidth,
                height: cardHeight,
                child: _card(context, l10n, list[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(
      BuildContext context, AppLocalizations l10n, TopExperienceItem item) {
    final c = item.community;
    if (c == null) {
      final p = item.partner!;
      return ExternalEventGridTile(
        event: p,
        showPartnerBadge: true,
        showReviewCount: true,
        onTap: () => onOpenPartner(p),
      );
    }
    final card = ExperienceCard(
      experience: c,
      compact: true,
      ratingWithCount: true,
      onTap: () => onOpenCommunity(c),
    );
    if (!item.featured || ExperienceCard.isHostHidden(c.hostId)) return card;
    // Featured: gold frame + a small star pill (top-right; the category
    // badge sits top-left).
    return Stack(
      fit: StackFit.expand,
      children: [
        card,
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.richGold, width: 1.5),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: IgnorePointer(
            child: Semantics(
              label: l10n.eventsFeatured,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.richGold,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.richGold.withValues(alpha: 0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: const Icon(Icons.star_rounded,
                    size: 12, color: AppColors.deepBlack),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
