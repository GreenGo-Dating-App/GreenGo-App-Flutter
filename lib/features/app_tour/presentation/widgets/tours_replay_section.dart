import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/flavor_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection_container.dart' as di;
import '../../../../generated/app_localizations.dart';
import '../../../explore/presentation/screens/network_discovery_screen.dart';
import '../../../globe_explore/presentation/bloc/globe_bloc.dart';
import '../../../globe_explore/presentation/screens/globe_screen.dart';
import '../../../my_space/presentation/screens/my_space_screen.dart';
import '../../../referral/presentation/screens/referral_screen.dart';
import '../../../ticket_payments/presentation/screens/get_paid_screen.dart';
import '../../../user_experiences/presentation/screens/my_experiences_screen.dart';
import '../tour_controller.dart';

/// One replayable tour in the App Guide.
class TourEntry {
  const TourEntry(this.id, this.icon, this.name, {this.open});

  final String id;
  final IconData icon;
  final String Function(AppLocalizations l10n) name;

  /// Opens the tour's page (pages that need only the user id). Null: the user
  /// is told to open the page themselves.
  final Route<void> Function(String userId)? open;
}

/// Every tour, in App Guide order (main first). Kept in sync with
/// [TourController.allTourIds] by a unit test.
List<TourEntry> tourEntries() => [
      TourEntry(TourController.mainTourId, Icons.play_circle_outline,
          (l) => l.tourNameMain),
      TourEntry(TourController.discoverTourId, Icons.travel_explore,
          (l) => l.tourNameDiscover,
          open: (uid) => MaterialPageRoute<void>(
              builder: (_) => NetworkDiscoveryScreen(userId: uid))),
      if (FlavorConfig.enableWorldMap)
        TourEntry(TourController.worldMapTourId, Icons.public,
            (l) => l.tourNameWorldMap,
            open: (uid) => MaterialPageRoute<void>(
                builder: (_) => BlocProvider(
                      create: (_) => di.sl<GlobeBloc>(),
                      child: GlobeScreen(userId: uid),
                    ))),
      TourEntry(TourController.exploreTourId, Icons.explore_outlined,
          (l) => l.tourNameExplore),
      if (FlavorConfig.enableSwipeDiscovery)
        TourEntry(
            TourController.swipeTourId, Icons.swipe, (l) => l.tourNameSwipe),
      TourEntry(TourController.profileDetailTourId,
          Icons.photo_library_outlined, (l) => l.tourNameProfileDetail),
      TourEntry(TourController.followersPublicTourId, Icons.people_outline,
          (l) => l.tourNameFollowersPublic),
      TourEntry(TourController.safetyCenterTourId, Icons.shield_outlined,
          (l) => l.tourNameSafetyCenter),
      TourEntry(TourController.chatTourId, Icons.chat_bubble_outline,
          (l) => l.tourNameChat),
      TourEntry(TourController.chatExtrasTourId, Icons.translate,
          (l) => l.tourNameChatExtras),
      TourEntry(TourController.storyTourId, Icons.auto_stories_outlined,
          (l) => l.tourNameStory),
      TourEntry(TourController.communitiesTourId, Icons.groups_outlined,
          (l) => l.tourNameCommunities),
      TourEntry(TourController.communityDetailTourId, Icons.forum_outlined,
          (l) => l.tourNameCommunityDetail),
      TourEntry(
          TourController.eventsTourId, Icons.event, (l) => l.tourNameEvents),
      TourEntry(TourController.eventTicketsTourId,
          Icons.confirmation_number_outlined, (l) => l.tourNameEventTickets),
      TourEntry(TourController.experienceGuestTourId, Icons.event_available,
          (l) => l.tourNameExperienceGuest),
      TourEntry(TourController.experienceHostTourId,
          Icons.add_business_outlined, (l) => l.tourNameExperienceHost,
          open: (uid) => MyExperiencesScreen.route(uid)),
      TourEntry(TourController.experienceDatesTourId,
          Icons.calendar_month_outlined, (l) => l.tourNameExperienceDates),
      TourEntry(TourController.attractionsTourId, Icons.place_outlined,
          (l) => l.tourNameAttractions),
      TourEntry(TourController.profileTourId, Icons.person_outline,
          (l) => l.tourNameProfile),
      TourEntry(TourController.followersOwnTourId, Icons.people_alt_outlined,
          (l) => l.tourNameFollowersOwn),
      TourEntry(TourController.privacyLocationTourId,
          Icons.location_on_outlined, (l) => l.tourNamePrivacyLocation),
      TourEntry(TourController.verificationTourId, Icons.verified_outlined,
          (l) => l.tourNameVerification),
      TourEntry(TourController.notificationsTourId,
          Icons.notifications_outlined, (l) => l.tourNameNotifications),
      TourEntry(TourController.coinShopTourId, Icons.monetization_on_outlined,
          (l) => l.tourNameCoinShop),
      TourEntry(TourController.inviteFriendsTourId, Icons.card_giftcard,
          (l) => l.tourNameInviteFriends,
          open: (uid) => MaterialPageRoute<void>(
              builder: (_) => ReferralScreen(userId: uid))),
      TourEntry(TourController.safetyAppealTourId, Icons.gavel_outlined,
          (l) => l.tourNameSafetyAppeal),
      TourEntry(TourController.businessCenterTourId,
          Icons.business_center_outlined, (l) => l.tourNameBusinessCenter),
      TourEntry(TourController.storefrontEditorTourId,
          Icons.storefront_outlined, (l) => l.tourNameStorefrontEditor),
      TourEntry(TourController.mySpaceTourId, Icons.space_dashboard_outlined,
          (l) => l.tourNameMySpace,
          open: (uid) => MySpaceScreen.route(currentUserId: uid)),
      TourEntry(TourController.getPaidTourId, Icons.payments_outlined,
          (l) => l.tourNameGetPaid,
          open: (uid) => GetPaidScreen.route(uid)),
      TourEntry(TourController.promoteTourId, Icons.campaign_outlined,
          (l) => l.tourNamePromote),
    ];

/// App Guide "Tours" section: every tour with "Show me again".
///
/// [onReplayMain] restarts the main tour (the App Guide pops back to home).
class ToursReplaySection extends StatelessWidget {
  const ToursReplaySection({required this.onReplayMain, super.key});

  final VoidCallback onReplayMain;

  Future<void> _replay(BuildContext context, TourEntry entry) async {
    if (entry.id == TourController.mainTourId) {
      onReplayMain();
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    await TourController.instance.resetTour(entry.id, uid);
    final open = entry.open;
    if (open != null) {
      await navigator.push(open(uid));
      return;
    }
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.guideToursOpenPageHint(entry.name(l10n)))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.backgroundCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.richGold.withValues(alpha: 0.5)),
      ),
      // Own transparent Material so the tiles' ink splashes paint above the
      // card's background (ListTile assertion otherwise).
      child: Material(
        type: MaterialType.transparency,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: const ValueKey('guide-tours'),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.richGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.tour_outlined,
                  color: AppColors.richGold, size: 24),
            ),
            title: Text(
              l10n.guideToursTitle,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Text(
              l10n.guideToursSubtitle,
              style: const TextStyle(
                  color: AppColors.textTertiary, fontSize: 12.5),
            ),
            iconColor: AppColors.textSecondary,
            collapsedIconColor: AppColors.textTertiary,
            childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            children: [
              for (final e in tourEntries())
                ListTile(
                  key: ValueKey('guide-tour-${e.id}'),
                  dense: true,
                  leading: Icon(e.icon, color: AppColors.richGold, size: 20),
                  title: Text(
                    e.name(l10n),
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 14),
                  ),
                  trailing: TextButton(
                    onPressed: () => _replay(context, e),
                    child: Text(
                      l10n.guideToursShowAgain,
                      style: const TextStyle(color: AppColors.richGold),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
