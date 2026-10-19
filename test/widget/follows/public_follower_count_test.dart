import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:greengo_chat/features/business/data/business_upcoming_events.dart';
import 'package:greengo_chat/features/business/data/services/follow_service.dart';
import 'package:greengo_chat/features/business/data/services/rating_service.dart';
import 'package:greengo_chat/features/business/presentation/screens/business_storefront_screen.dart';
import 'package:greengo_chat/features/follows/presentation/follow_toggle_controller.dart';
import 'package:greengo_chat/features/follows/presentation/screens/follow_list_screen.dart';
import 'package:greengo_chat/features/follows/presentation/widgets/public_follower_count_line.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

import '../../support/profile_fixtures.dart';
import 'follow_test_support.dart';

/// Public follower count (owner decision 2026-10-19): the NUMBER of
/// followers of every user and business is public (who follows, following
/// and stores stay private).
void main() {
  late FollowWorld w;

  setUp(() => w = FollowWorld());
  tearDown(() => w.dispose());

  Future<void> publicCount(String uid, int n) => w.fs
      .collection(FollowService.publicCountsCollection)
      .doc(uid)
      .set({'followersCount': n});

  const line = Key('public_follower_count_line');

  group('PublicFollowerCountLine (another user\'s profile, under the city)', () {
    testWidgets('shows "[people] 128 followers" (13 sp, textSecondary)', (tester) async {
      await publicCount('t', 128);
      await tester.pumpWidget(wrapForTest(const PublicFollowerCountLine(userId: 't')));
      await tester.pumpAndSettle();

      expect(find.byKey(line), findsOneWidget);
      expect(find.text('128 followers'), findsOneWidget);
      expect(find.byIcon(Icons.people_alt_outlined), findsOneWidget);
      final text = tester.widget<Text>(find.text('128 followers'));
      expect(text.style?.fontSize, 13);
      expect(tester.takeException(), isNull);
    });

    testWidgets('compact counts and singular plural', (tester) async {
      await publicCount('big', 1234);
      await publicCount('one', 1);
      await tester.pumpWidget(wrapForTest(const Column(children: [
        PublicFollowerCountLine(userId: 'big'),
        PublicFollowerCountLine(userId: 'one'),
      ])));
      await tester.pumpAndSettle();
      expect(find.text('1.2k followers'), findsOneWidget);
      expect(find.text('1 follower'), findsOneWidget);
    });

    testWidgets('hidden at 0 and when there is no public doc', (tester) async {
      await publicCount('zero', 0);
      await tester.pumpWidget(wrapForTest(const Column(children: [
        PublicFollowerCountLine(userId: 'zero'),
        PublicFollowerCountLine(userId: 'missing'),
      ])));
      await tester.pumpAndSettle();
      expect(find.byKey(line), findsNothing);
      expect(find.textContaining('follower'), findsNothing);
    });

    testWidgets('never reads the private follow_counts (following / stores)', (tester) async {
      await w.counts('t', followers: 50, following: 7, stores: 3);
      await tester.pumpWidget(wrapForTest(const PublicFollowerCountLine(userId: 't')));
      await tester.pumpAndSettle();
      // No public doc yet -> nothing, even though the private doc has 50.
      expect(find.byKey(line), findsNothing);
      expect(find.textContaining('following'), findsNothing);
    });

    testWidgets('not tappable: the follower list stays private', (tester) async {
      await publicCount('t', 9);
      await tester.pumpWidget(wrapForTest(const PublicFollowerCountLine(userId: 't')));
      await tester.pumpAndSettle();
      expect(find.descendant(of: find.byKey(line), matching: find.byType(InkWell)), findsNothing);
      expect(find.ancestor(of: find.byKey(line), matching: find.byType(InkWell)), findsNothing);
      await tester.tap(find.byKey(line), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(find.byType(FollowListScreen), findsNothing);
    });

    testWidgets('the page Follow button moves the number at once (follow and unfollow)', (tester) async {
      await publicCount('t', 128);
      final c = FollowToggleController(follow: () async {}, unfollow: () async {});
      addTearDown(c.dispose);
      await tester.pumpWidget(wrapForTest(PublicFollowerCountLine(userId: 't', controller: c)));
      await tester.pumpAndSettle();
      expect(find.text('128 followers'), findsOneWidget);

      await c.toggle(); // follow
      await tester.pump();
      expect(find.text('129 followers'), findsOneWidget);

      await c.toggle(); // unfollow
      await tester.pump();
      expect(find.text('128 followers'), findsOneWidget);

      // Unfollowing an already-counted follow goes DOWN (seeded baseline).
      final c2 = FollowToggleController(
          follow: () async {}, unfollow: () async {}, initiallyFollowing: true);
      addTearDown(c2.dispose);
      await tester.pumpWidget(wrapForTest(PublicFollowerCountLine(userId: 't', controller: c2)));
      await tester.pumpAndSettle();
      expect(find.text('128 followers'), findsOneWidget);
      await c2.toggle();
      await tester.pump();
      expect(find.text('127 followers'), findsOneWidget);
    });
  });

  group('FollowService.publicFollowerCount', () {
    test('one get, cached; own follow / unfollow moves the cached value', () async {
      final svc = GetIt.instance<FollowService>();
      await publicCount('t', 5);
      expect(await svc.publicFollowerCount('t'), 5);
      // Cached: a server change is not re-read within the TTL ...
      await publicCount('t', 6);
      expect(await svc.publicFollowerCount('t'), 5);
      // ... unless refreshed.
      expect(await svc.publicFollowerCount('t', refresh: true), 6);

      await svc.followUser(followeeId: 't', followerId: 'me');
      expect(await svc.publicFollowerCount('t'), 7);
      await svc.unfollowUser(followeeId: 't', followerId: 'me');
      expect(await svc.publicFollowerCount('t'), 6);
      expect(await svc.publicFollowerCount('nobody'), 0);
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

    testWidgets('visitors see the public followers line under the category', (tester) async {
      await publicCount('business_fixture_1', 2500);
      await tester.pumpWidget(storefront('visitor'));
      await tester.pumpAndSettle();
      expect(find.byKey(line), findsOneWidget);
      expect(find.text('2.5k followers'), findsOneWidget);
    });

    testWidgets('visitors: hidden at 0', (tester) async {
      await publicCount('business_fixture_1', 0);
      await tester.pumpWidget(storefront('visitor'));
      await tester.pumpAndSettle();
      expect(find.byKey(line), findsNothing);
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
