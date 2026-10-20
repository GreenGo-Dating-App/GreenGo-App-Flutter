import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';
import '../../../app_tour/presentation/widgets/tours_replay_section.dart';
import '../faq_entries.dart';

/// App Guide screen that explains all functionalities of GreenGo, with a
/// searchable FAQ. Accessible from the question mark icon on the Network page.
class AppGuideScreen extends StatefulWidget {
  const AppGuideScreen({super.key});

  /// Pop result that asks the caller to restart the gesture tutorial.
  static const String replayTourResult = 'replay_tour';

  /// Pop result that asks the caller to replay only the main tour.
  static const String replayMainTourResult = 'replay_main_tour';

  @override
  State<AppGuideScreen> createState() => _AppGuideScreenState();
}

class _AppGuideScreenState extends State<AppGuideScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

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
        icon: Icons.groups,
        title: l10n.guideGroupsTitle,
        items: [
          l10n.guideGroupsItem1,
          l10n.guideGroupsItem2,
          l10n.guideGroupsItem3,
          l10n.guideGroupsItem4,
          l10n.guideGroupsItem5,
        ],
      ),
      _GuideSection(
        icon: Icons.event,
        title: l10n.guideEventsTitle,
        items: [
          l10n.guideEventsItem1,
          l10n.guideEventsItem2,
          l10n.guideEventsItem3,
          l10n.guideEventsItem4,
          l10n.guideEventsItem5,
          l10n.guideEventsItem6,
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
          // guideMembershipItem2 ("starts with a free trial") removed: no
          // free trial on any platform (owner 2026-10-17).
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
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        key: const Key('app_guide_list'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          if (_query.isEmpty) _buildReplayTourCard(context, l10n),
          // Every tour, each with "Show me again".
          if (_query.isEmpty)
            ToursReplaySection(
              onReplayMain: () =>
                  Navigator.of(context).pop(AppGuideScreen.replayMainTourResult),
            ),
          ..._buildFaq(context, l10n),
          // The guide sections stay out of the way while searching the FAQ.
          if (_query.isEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 12),
              child: Text(
                l10n.xplGuideFeaturesTitle,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            for (final section in sections) _buildSectionCard(context, section),
          ],
        ],
      ),
    );
  }

  /// FAQ: title, search field and the (filtered) questions.
  List<Widget> _buildFaq(BuildContext context, AppLocalizations l10n) {
    final entries = filterFaq(buildFaqEntries(l10n), _query);
    return [
      Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 10),
        child: Text(
          l10n.xplFaqTitle,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      TextField(
        key: const Key('faq_search'),
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _query = v.trim()),
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          isDense: true,
          hintText: l10n.xplFaqSearchHint,
          hintStyle: const TextStyle(color: AppColors.textTertiary),
          prefixIcon: const Icon(Icons.search, color: AppColors.textTertiary),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  tooltip: l10n.userFollowSearchClear,
                  icon: const Icon(Icons.clear, color: AppColors.textTertiary),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _query = '');
                  },
                ),
          filled: true,
          fillColor: AppColors.backgroundCard,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: AppColors.divider),
          ),
        ),
      ),
      const SizedBox(height: 12),
      if (entries.isEmpty)
        Padding(
          key: const Key('faq_no_results'),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            l10n.xplFaqNoResults,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      for (final e in entries) _buildFaqCard(context, e),
      const SizedBox(height: 8),
    ];
  }

  Widget _buildFaqCard(BuildContext context, FaqEntry e) {
    return Container(
      key: Key('faq_${e.id}'),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      // Own Material so the tile's ink is not hidden by the card colour.
      child: Material(
        type: MaterialType.transparency,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            // A search opens the matching answers right away.
            initiallyExpanded: _query.isNotEmpty,
            key: PageStorageKey<String>('faq_${e.id}_${_query.isNotEmpty}'),
            title: Text(
              e.question,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            iconColor: AppColors.textSecondary,
            collapsedIconColor: AppColors.textTertiary,
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                e.answer,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Gold call-to-action card that restarts the interactive gesture tour.
  Widget _buildReplayTourCard(BuildContext context, AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.richGold),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: ListTile(
          onTap: () =>
              Navigator.of(context).pop(AppGuideScreen.replayTourResult),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.richGold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.play_circle_outline,
              color: AppColors.richGold,
              size: 24,
            ),
          ),
          title: Text(
            l10n.guideReplayTour,
            style: const TextStyle(
              color: AppColors.richGold,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right,
            color: AppColors.richGold,
          ),
        ),
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
      // Own Material so the tile's ink is not hidden by the card colour.
      child: Material(
        type: MaterialType.transparency,
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
      ),
    );
  }
}

class _GuideSection {
  const _GuideSection({
    required this.icon,
    required this.title,
    required this.items,
  });
  final IconData icon;
  final String title;
  final List<String> items;
}
