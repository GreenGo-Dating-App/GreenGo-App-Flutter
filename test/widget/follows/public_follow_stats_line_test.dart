import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:greengo_chat/core/services/user_directory_service.dart';
import 'package:greengo_chat/features/business/data/business_upcoming_events.dart';
import 'package:greengo_chat/features/business/data/services/follow_service.dart';
import 'package:greengo_chat/features/business/data/services/rating_service.dart';
import 'package:greengo_chat/features/business/presentation/screens/business_storefront_screen.dart';
import 'package:greengo_chat/features/follows/presentation/follow_toggle_controller.dart';
import 'package:greengo_chat/features/follows/presentation/screens/follow_list_screen.dart';
import 'package:greengo_chat/features/follows/presentation/widgets/public_follow_stats_line.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

import '../../support/profile_fixtures.dart';
import 'follow_test_support.dart';

/// Public follow stats (owner decisions 2026-10-19): followers AND following
/// (counts and lists) of every user and business are public; only the
/// stores count stays private.
void main() {
  late FollowWorld w;

  setUp(() => w = FollowWorld());
  tearDown(() => w.dispose());

  Future<void> publicCount(String uid, int followers, [int following = 0]) => w.fs
      .collection(FollowService.publicCountsCollection)
      .doc(uid)
      .set({'followersCount': followers, 'followingCount': following});

  const line = Key('public_follow_stats_line');
  const followersPart = Key('public_line_followers');
  const followingPart = Key('public_line_following');

  Widget stats(String uid, {FollowToggleController? controller}) =>
      PublicFollowStatsLine(userId: uid, currentUserId: 'me', controller: controller);

  group("PublicFollowStatsLine (another user's profile, under the city)", () {
    testWidgets('shows "[people] 128 followers · [person] 64 following" (13 sp)', (tester) async {
      await publicCount('t', 128, 64);
      await tester.pumpWidget(wrapForTest(stats('t')));
      await tester.pumpAndSettle();

      expect(find.byKey(line), findsOneWidget);
      expect(find.text('128 followers'), findsOneWidget);
      expect(find.text('64 following'), findsOneWidget);
      expect(find.byIcon(Icons.people_alt_outlined), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
      expect(tester.widget<Text>(find.text('128 followers')).style?.fontSize, 13);
      expect(tester.widget<Text>(find.text('64 following')).style?.fontSize, 13);
      expect(tester.takeException(), isNull);
    });

    testWidgets('compact counts and singular plural', (tester) async {
      await publicCount('big', 1234, 2500);
      await publicCount('one', 1, 1);
      await tester.pumpWidget(wrapForTest(Column(children: [
        stats('big'),
        stats('one'),
      ])));
      await tester.pumpAndSettle();
      expect(find.text('1.2k followers'), findsOneWidget);
      expect(find.text('2.5k following'), findsOneWidget);
      expect(find.text('1 follower'), findsOneWidget);
      expect(find.text('1 following'), findsOneWidget);
    });

    testWidgets('shown at 0 and with no public doc (both parts, tappable)', (tester) async {
      await publicCount('zero', 0, 0);
      await tester.pumpWidget(wrapForTest(Column(children: [
        stats('zero'),
        stats('missing'),
      ])));
      await tester.pumpAndSettle();
      expect(find.byKey(line), findsNWidgets(2));
      expect(find.text('0 followers'), findsNWidgets(2));
      expect(find.text('0 following'), findsNWidgets(2));
    });

    testWidgets('never reads the private follow_counts (stores stays private)', (tester) async {
      await w.counts('t', followers: 50, following: 7, stores: 3);
      await publicCount('t', 4, 2);
      await tester.pumpWidget(wrapForTest(stats('t')));
      await tester.pumpAndSettle();
      expect(find.text('4 followers'), findsOneWidget);
      expect(find.text('2 following'), findsOneWidget);
      expect(find.textContaining('50'), findsNothing);
      expect(find.textContaining('3'), findsNothing);
    });

    testWidgets('tapping followers / following opens THAT account\'s list on the tab',
        (tester) async {
      await publicCount('t', 1, 1);
      await w.follow('u1', 't', followerName: 'ana');
      await w.follow('t', 'x1', followeeName: 'bia');
      w.briefs({
        'u1': const UserBrief(name: 'Ana'),
        'x1': const UserBrief(name: 'Bia'),
      });
      await tester.pumpWidget(wrapForTest(stats('t')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(followersPart));
      await tester.pumpAndSettle();
      var screen = tester.widget<FollowListScreen>(find.byType(FollowListScreen));
      expect(screen.userId, 't');
      expect(screen.currentUserId, 'me');
      expect(screen.initialTab, 0);
      expect(find.text('Ana'), findsOneWidget);
      expect(find.byKey(const Key('follow_list_unavailable')), findsNothing);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(followingPart));
      await tester.pumpAndSettle();
      screen = tester.widget<FollowListScreen>(find.byType(FollowListScreen));
      expect(screen.initialTab, 1);
      expect(find.text('Bia'), findsOneWidget);
    });

    testWidgets('tappable at 0: opens the empty state', (tester) async {
      await tester.pumpWidget(wrapForTest(stats('nobody')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(followingPart));
      await tester.pumpAndSettle();
      expect(find.byType(FollowListScreen), findsOneWidget);
      expect(find.byKey(const Key('follow_list_message')), findsOneWidget);
    });

    testWidgets('the page Follow button moves the followers number at once', (tester) async {
      await publicCount('t', 128, 5);
      final c = FollowToggleController(follow: () async {}, unfollow: () async {});
      addTearDown(c.dispose);
      await tester.pumpWidget(wrapForTest(stats('t', controller: c)));
      await tester.pumpAndSettle();
      expect(find.text('128 followers'), findsOneWidget);

      await c.toggle(); // follow
      await tester.pump();
      expect(find.text('129 followers'), findsOneWidget);
      expect(find.text('5 following'), findsOneWidget); // theirs, unchanged

      await c.toggle(); // unfollow
      await tester.pump();
      expect(find.text('128 followers'), findsOneWidget);

      // Unfollowing an already-counted follow goes DOWN (seeded baseline).
      final c2 = FollowToggleController(
          follow: () async {}, unfollow: () async {}, initiallyFollowing: true);
      addTearDown(c2.dispose);
      await tester.pumpWidget(wrapForTest(stats('t', controller: c2)));
      await tester.pumpAndSettle();
      expect(find.text('128 followers'), findsOneWidget);
      await c2.toggle();
      await tester.pump();
      expect(find.text('127 followers'), findsOneWidget);
    });
  });

  group('FollowService.publicFollowCounts', () {
    test('one get, cached; own follow / unfollow moves both sides', () async {
      final svc = GetIt.instance<FollowService>();
      await publicCount('t', 5, 2);
      await publicCount('me', 0, 10);
      expect(await svc.publicFollowerCount('t'), 5);
      expect((await svc.publicFollowCounts('t'))?.following, 2);
      expect((await svc.publicFollowCounts('me'))?.following, 10);
      // Cached: a server change is not re-read within the TTL ...
      await publicCount('t', 6, 2);
      expect(await svc.publicFollowerCount('t'), 5);
      // ... unless refreshed.
      expect(await svc.publicFollowerCount('t', refresh: true), 6);

      await svc.followUser(followeeId: 't', followerId: 'me');
      expect(await svc.publicFollowerCount('t'), 7);
      expect((await svc.publicFollowCounts('me'))?.following, 11);
      await svc.unfollowUser(followeeId: 't', followerId: 'me');
      expect(await svc.publicFollowerCount('t'), 6);
      expect((await svc.publicFollowCounts('me'))?.following, 10);
      final none = await svc.publicFollowCounts('nobody');
      expect(none?.followers, 0);
      expect(none?.following, 0);
    });
  });

  group('Business storefront', () {
    Widget storefront(String viewer) => MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: BusinessStorefrontScreen(
            business: buildBusinessProfile(coverImageUrl: ''),
            currentUserId: viewer,
            firestore: w.fs,
            eventsRepository: BusinessUpcomingEventsRepository(firestore: w.fs),
          ),
        );

    setUp(() {
      GetIt.instance.registerSingleton<RatingService>(RatingService(firestore: w.fs));
    });

    testWidgets('visitors see "followers · following" under the category', (tester) async {
      await publicCount('business_fixture_1', 2500, 3);
      await tester.pumpWidget(storefront('visitor'));
      await tester.pumpAndSettle();
      expect(find.byKey(line), findsOneWidget);
      expect(find.text('2.5k followers'), findsOneWidget);
      expect(find.text('3 following'), findsOneWidget);
    });

    testWidgets("visitors: tapping followers opens the business's followers (business_followers)",
        (tester) async {
      await publicCount('business_fixture_1', 0);
      await w.follow('u1', 'business_fixture_1', followerName: 'ana');
      w.briefs({'u1': const UserBrief(name: 'Ana')});
      await tester.pumpWidget(storefront('visitor'));
      await tester.pumpAndSettle();
      expect(find.text('0 followers'), findsOneWidget); // shown at 0
      await tester.ensureVisible(find.byKey(followersPart));
      await tester.tap(find.byKey(followersPart));
      await tester.pumpAndSettle();
      final screen = tester.widget<FollowListScreen>(find.byType(FollowListScreen));
      expect(screen.userId, 'business_fixture_1');
      expect(screen.initialTab, 0);
      expect(find.text('Ana'), findsOneWidget);
    });

    testWidgets('owner keeps the private live line (shown even at 0)', (tester) async {
      await w.counts('business_fixture_1', followers: 0);
      await tester.pumpWidget(storefront('business_fixture_1'));
      await tester.pumpAndSettle();
      expect(find.byKey(line), findsNothing);
      expect(find.text('No followers'), findsWidgets);
    });
  });
}
