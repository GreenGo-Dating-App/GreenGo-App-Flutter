import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../generated/app_localizations.dart';

/// Chat · Tips · Announcements · Events · Experiences — the community detail
/// tab bar. Fills the full width (like the Events and Communities pages): the
/// tabs share it equally and a long translation scales down on one line
/// instead of overflowing or scrolling (5 tabs fit at 320 px).
class CommunityDetailTabBar extends StatelessWidget
    implements PreferredSizeWidget {
  const CommunityDetailTabBar({required this.controller, super.key});

  final TabController controller;

  /// Number of tabs (the TabController / TabBarView must match).
  static const int tabCount = 5;

  /// Index of the Experiences tab.
  static const int experiencesIndex = 4;

  @override
  Size get preferredSize => const Size.fromHeight(kTextTabBarHeight);

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final labels = [
      l.communitiesTabChat,
      l.communitiesTabTips,
      l.communitiesTabAnnouncements,
      l.communitiesTabEvents,
      l.eventsTabExperiences,
    ];
    assert(labels.length == tabCount);
    return TabBar(
      controller: controller,
      isScrollable: false,
      tabAlignment: TabAlignment.fill,
      // 5 equal tabs on a narrow phone: keep the side padding small so the
      // label (not the padding) gets the width.
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      indicatorColor: AppColors.richGold,
      labelColor: AppColors.richGold,
      unselectedLabelColor: AppColors.textTertiary,
      labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      tabs: [
        for (final label in labels)
          Tab(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label, maxLines: 1),
            ),
          ),
      ],
    );
  }
}
