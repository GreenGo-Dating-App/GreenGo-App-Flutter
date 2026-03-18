import 'package:flutter/material.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import '../../../../core/constants/app_colors.dart';

/// App Guide screen that explains all functionalities of GreenGo.
/// Accessible from the question mark icon on the Network page.
class AppGuideScreen extends StatelessWidget {
  const AppGuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final sections = [
      _GuideSection(
        icon: Icons.rocket_launch,
        title: l10n.firstStepsTitle,
        items: [
          l10n.firstStepsReview,
          l10n.firstStepsStatusUpdate,
          l10n.firstStepsSupportChat,
        ],
      ),
      _GuideSection(
        icon: Icons.swipe,
        title: l10n.guideSwipeTitle,
        items: [
          l10n.guideSwipeItem1,
          l10n.guideSwipeItem2,
          l10n.guideSwipeItem3,
          l10n.guideSwipeItem4,
        ],
      ),
      _GuideSection(
        icon: Icons.grid_view,
        title: l10n.guideGridTitle,
        items: [
          l10n.guideGridItem1,
          l10n.guideGridItem2,
          l10n.guideGridItem3,
        ],
      ),
      _GuideSection(
        icon: Icons.favorite,
        title: l10n.guideConnectionsTitle,
        items: [
          l10n.guideConnectionsItem1,
          l10n.guideConnectionsItem2,
          l10n.guideConnectionsItem3,
          l10n.guideConnectionsItem4,
        ],
      ),
      _GuideSection(
        icon: Icons.chat_bubble_outline,
        title: l10n.guideChatTitle,
        items: [
          l10n.guideChatItem1,
          l10n.guideChatItem2,
          l10n.guideChatItem3,
          l10n.guideChatItem4,
        ],
      ),
      _GuideSection(
        icon: Icons.tune,
        title: l10n.guideFiltersTitle,
        items: [
          l10n.guideFiltersItem1,
          l10n.guideFiltersItem2,
          l10n.guideFiltersItem3,
        ],
      ),
      _GuideSection(
        icon: Icons.filter_list,
        title: l10n.guideGridFiltersTitle,
        items: [
          l10n.guideGridFiltersItem1,
          l10n.guideGridFiltersItem2,
          l10n.guideGridFiltersItem3,
          l10n.guideGridFiltersItem4,
          l10n.guideGridFiltersItem5,
          l10n.guideGridFiltersItem6,
        ],
      ),
      _GuideSection(
        icon: Icons.forum,
        title: l10n.guideExchangesTitle,
        items: [
          l10n.guideExchangesItem1,
          l10n.guideExchangesItem2,
          l10n.guideExchangesItem3,
          l10n.guideExchangesItem4,
          l10n.guideExchangesItem5,
          l10n.guideExchangesItem6,
          l10n.guideExchangesItem7,
          l10n.guideExchangesItem8,
          l10n.guideExchangesItem9,
        ],
      ),
      _GuideSection(
        icon: Icons.flight_takeoff,
        title: l10n.guideTravelTitle,
        items: [
          l10n.guideTravelItem1,
          l10n.guideTravelItem2,
          l10n.guideTravelItem3,
        ],
      ),
      _GuideSection(
        icon: Icons.card_membership,
        title: l10n.guideMembershipTitle,
        items: [
          l10n.guideMembershipItem1,
          l10n.guideMembershipItem2,
          l10n.guideMembershipItem3,
        ],
      ),
      _GuideSection(
        icon: Icons.star,
        title: l10n.guideTiersTitle,
        items: [
          l10n.guideTiersItem1,
          l10n.guideTiersItem2,
          l10n.guideTiersItem3,
          l10n.guideTiersItem4,
        ],
      ),
      _GuideSection(
        icon: Icons.monetization_on_outlined,
        title: l10n.guideCoinsTitle,
        items: [
          l10n.guideCoinsItem1,
          l10n.guideCoinsItem2,
          l10n.guideCoinsItem3,
          l10n.guideCoinsItem4,
          l10n.guideCoinsItem5,
        ],
      ),
      _GuideSection(
        icon: Icons.leaderboard_outlined,
        title: l10n.guideLeaderboardTitle,
        items: [
          l10n.guideLeaderboardItem1,
          l10n.guideLeaderboardItem2,
        ],
      ),
      _GuideSection(
        icon: Icons.shield_outlined,
        title: l10n.guideSafetyTitle,
        items: [
          l10n.guideSafetyItem1,
          l10n.guideSafetyItem2,
          l10n.guideSafetyItem3,
        ],
      ),
    ];

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        title: Text(
          l10n.guideTitle,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        itemCount: sections.length,
        itemBuilder: (context, index) {
          final section = sections[index];
          return _buildSectionCard(context, section);
        },
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, _GuideSection section) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.richGold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              section.icon,
              color: AppColors.richGold,
              size: 24,
            ),
          ),
          title: Text(
            section.title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          iconColor: AppColors.textSecondary,
          collapsedIconColor: AppColors.textTertiary,
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: section.items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(top: 7, right: 12, left: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.richGold.withValues(alpha: 0.6),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _GuideSection {
  final IconData icon;
  final String title;
  final List<String> items;

  const _GuideSection({
    required this.icon,
    required this.title,
    required this.items,
  });
}
