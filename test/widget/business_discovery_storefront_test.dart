import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/business/data/business_upcoming_events.dart';
import 'package:greengo_chat/features/business/presentation/company_checklist.dart';
import 'package:greengo_chat/features/business/presentation/screens/business_storefront_screen.dart';
import 'package:greengo_chat/features/business/presentation/screens/business_upcoming_events_screen.dart';
import 'package:greengo_chat/features/business/presentation/screens/storefront_editor_screen.dart';
import 'package:greengo_chat/features/business/presentation/widgets/storefront_chat_button.dart';
import 'package:greengo_chat/features/discovery/presentation/widgets/network_grid_card.dart';
import 'package:greengo_chat/features/matching/domain/entities/match_candidate.dart';
import 'package:greengo_chat/features/matching/domain/entities/match_score.dart';
import 'package:greengo_chat/features/profile/domain/entities/profile.dart';
import 'package:greengo_chat/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:greengo_chat/features/profile/presentation/bloc/profile_event.dart';
import 'package:greengo_chat/features/profile/presentation/bloc/profile_state.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

import '../support/profile_fixtures.dart';

class _MockProfileBloc extends Mock implements ProfileBloc {}

Widget _app(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    );

MatchCandidate _candidate(Profile p) => MatchCandidate(
      profile: p,
      matchScore: MatchScore(
        userId1: 'me',
        userId2: p.userId,
        overallScore: 0,
        breakdown: const ScoreBreakdown(
            locationScore: 0, ageCompatibilityScore: 0, interestOverlapScore: 0),
        calculatedAt: DateTime(2026, 10, 19),
      ),
      distance: 3,
      suggestedAt: DateTime(2026, 10, 19),
    );

Future<String?> _tileImage(WidgetTester t, Profile p, {required bool isBusiness}) async {
  await t.pumpWidget(_app(Scaffold(
    body: SizedBox(
      width: 200,
      height: 300,
      child: NetworkGridCard(
        candidate: _candidate(p),
        isSelf: false,
        isBusiness: isBusiness,
        onOpenProfile: () {},
        onLongPressTag: () {},
      ),
    ),
  )));
  final images = t.widgetList<CachedNetworkImage>(find.byType(CachedNetworkImage));
  return images.isEmpty ? null : images.first.imageUrl;
}

Map<String, dynamic> _event(String org, DateTime start,
        {DateTime? end,
        String status = 'published',
        bool hidden = false,
        String visibility = 'public',
        String? title}) =>
    {
      'organizerId': org,
      'title': title ?? 'E ${start.toIso8601String()}',
      'status': status,
      'startDate': Timestamp.fromDate(start),
      'endDate': Timestamp.fromDate(end ?? start.add(const Duration(hours: 2))),
      'hiddenByDowngrade': hidden,
      'visibility': visibility,
    };

void main() {
  final business = buildBusinessProfile().copyWith(
    photoUrls: const ['https://example.com/profile.jpg'],
    galleryImages: const ['https://example.com/g1.jpg', 'https://example.com/g2.jpg'],
  );

  group('1. Discover business tile photo', () {
    test('first gallery image, legacy fallback to the profile photo', () {
      expect(NetworkGridCard.mainPhotoUrl(business, isBusiness: true), 'https://example.com/g1.jpg');
      expect(NetworkGridCard.mainPhotoUrl(business.copyWith(galleryImages: const []), isBusiness: true),
          'https://example.com/profile.jpg');
      // People tiles are unchanged.
      expect(NetworkGridCard.mainPhotoUrl(business, isBusiness: false), 'https://example.com/profile.jpg');
    });

    testWidgets('business tile renders the first gallery image', (t) async {
      expect(await _tileImage(t, business, isBusiness: true), 'https://example.com/g1.jpg');
    });

    testWidgets('business tile with an empty gallery falls back to the profile photo', (t) async {
      expect(await _tileImage(t, business.copyWith(galleryImages: const []), isBusiness: true),
          'https://example.com/profile.jpg');
    });

    testWidgets('people tile keeps the profile photo', (t) async {
      expect(await _tileImage(t, business, isBusiness: false), 'https://example.com/profile.jpg');
    });

    test('storefront hero: cover, else first gallery image, else profile photo', () {
      expect(BusinessStorefrontScreen.heroImageFor(business), 'https://example.com/elena_cover.jpg');
      final noCover = business.copyWith(coverImageUrl: '');
      expect(BusinessStorefrontScreen.heroImageFor(noCover), 'https://example.com/g1.jpg');
      expect(BusinessStorefrontScreen.heroImageFor(noCover.copyWith(galleryImages: const [])),
          'https://example.com/profile.jpg');
    });
  });

  group('2. mandatory storefront photo', () {
    test('checklist: storefront photo is a REQUIRED item', () {
      expect(CompanyItem.storefrontPhoto.required, isTrue);
      expect(companyChecklist(business)[CompanyItem.storefrontPhoto], isTrue);
      final empty = business.copyWith(galleryImages: const ['  ']);
      expect(companyChecklist(empty)[CompanyItem.storefrontPhoto], isFalse);
      expect(missingRequired(companyChecklist(empty)), contains(CompanyItem.storefrontPhoto));
      expect(missingRequired(companyChecklist(business)), isNot(contains(CompanyItem.storefrontPhoto)));
    });

    test('editor validator', () {
      expect(StorefrontEditorScreen.hasRequiredGallery(const []), isFalse);
      expect(StorefrontEditorScreen.hasRequiredGallery(const [' ']), isFalse);
      expect(StorefrontEditorScreen.hasRequiredGallery(const ['https://x/1.jpg']), isTrue);
    });

    testWidgets('editor: save with an empty gallery shows the inline error and does not save', (t) async {
      t.view.physicalSize = const Size(1200, 6000);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      registerFallbackValue(ProfileUpdateRequested(profile: business));
      final bloc = _MockProfileBloc();
      when(() => bloc.state).thenReturn(const ProfileInitial());
      when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
      final p = business.copyWith(galleryImages: const [], coverImageUrl: '', photoUrls: const []);
      await t.pumpWidget(_app(BlocProvider<ProfileBloc>.value(
        value: bloc,
        child: StorefrontEditorScreen(profile: p),
      )));
      await t.pump();
      final l = AppLocalizations.of(t.element(find.byType(StorefrontEditorScreen)))!;
      expect(find.byKey(const Key('storefront_gallery_required_error')), findsNothing);
      final save = find.widgetWithText(ElevatedButton, l.save);
      await t.ensureVisible(save);
      await t.tap(save);
      await t.pump();
      expect(find.byKey(const Key('storefront_gallery_required_error')), findsOneWidget);
      verifyNever(() => bloc.add(any()));
    });
  });

  group('4. storefront Chat button', () {
    testWidgets('visible to a signed-in visitor; tap opens the business chat', (t) async {
      var chats = 0;
      await t.pumpWidget(_app(Scaffold(
          body: StorefrontChatButton(business: business, currentUserId: 'visitor', onChat: () => chats++))));
      expect(find.byKey(const ValueKey('storefront-chat-button')), findsOneWidget);
      expect(find.text('Chat'), findsOneWidget);
      expect(find.byIcon(Icons.chat_bubble_outline), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('storefront-chat-button')));
      expect(chats, 1);
    });

    testWidgets('hidden for the owner and for signed-out viewers', (t) async {
      await t.pumpWidget(_app(Scaffold(
          body: StorefrontChatButton(business: business, currentUserId: business.userId))));
      expect(find.byKey(const ValueKey('storefront-chat-button')), findsNothing);
      await t.pumpWidget(_app(Scaffold(body: StorefrontChatButton(business: business, currentUserId: ''))));
      expect(find.byKey(const ValueKey('storefront-chat-button')), findsNothing);
    });
  });

  group('5. upcoming events', () {
    final now = DateTime(2026, 10, 19, 12);
    const org = 'business_fixture_1';

    Future<FakeFirebaseFirestore> seed(List<Map<String, dynamic>> events) async {
      final db = FakeFirebaseFirestore();
      for (var i = 0; i < events.length; i++) {
        await db.collection('events').doc('e$i').set(events[i]);
      }
      return db;
    }

    test('preview: future + ongoing only, published, not hidden/private, soonest first', () async {
      final db = await seed([
        _event(org, DateTime(2026, 11, 5), title: 'Nov 5'),
        _event(org, DateTime(2026, 10, 25), title: 'Oct 25'),
        _event(org, DateTime(2026, 10, 1), title: 'Past'),
        _event(org, DateTime(2026, 10, 15), end: DateTime(2026, 10, 22), title: 'Ongoing'),
        _event(org, DateTime(2026, 10, 20), status: 'cancelled', title: 'Cancelled'),
        _event(org, DateTime(2026, 10, 21), hidden: true, title: 'Hidden'),
        _event(org, DateTime(2026, 10, 22), visibility: 'private', title: 'Private'),
        _event(org, DateTime(2026, 10, 23), status: 'draft', title: 'Draft'),
        _event(org, DateTime(2026, 10, 19, 8), end: DateTime(2026, 10, 19, 10), title: 'Ended today'),
        _event('someone_else', DateTime(2026, 10, 24), title: 'Other org'),
      ]);
      final repo = BusinessUpcomingEventsRepository(firestore: db, clock: () => now);
      final events = await repo.preview(org);
      expect(events.map((e) => e.title), ['Ongoing', 'Oct 25', 'Nov 5']);
    });

    testWidgets('See all: every upcoming event, soonest first, paged with endless scroll', (t) async {
      // 45 events seeded in REVERSE date order.
      final db = await seed([
        for (var i = 44; i >= 0; i--)
          _event(org, DateTime(2026, 10, 20).add(Duration(days: i)), title: 'Event ${i.toString().padLeft(2, '0')}'),
      ]);
      final repo = BusinessUpcomingEventsRepository(firestore: db, clock: () => now);
      final opened = <String>[];
      await t.pumpWidget(_app(BusinessUpcomingEventsScreen(
        businessId: org,
        businessName: "Elena's Cafe",
        currentUserId: 'visitor',
        repository: repo,
        onOpenEvent: (_, id) => opened.add(id),
      )));
      await t.pumpAndSettle();
      expect(find.text('Event 00'), findsOneWidget);
      // Ascending order on screen.
      final y0 = t.getTopLeft(find.text('Event 00')).dy;
      final y1 = t.getTopLeft(find.text('Event 01')).dy;
      expect(y0, lessThan(y1));

      // Scroll to the end: all 45 load (3 pages of 20).
      final list = find.byKey(const ValueKey('storefront-all-events-list'));
      for (var i = 0; i < 20 && find.text('Event 44').evaluate().isEmpty; i++) {
        await t.drag(list, const Offset(0, -1500));
        await t.pumpAndSettle();
      }
      expect(find.text('Event 44'), findsOneWidget);

      await t.tap(find.text('Event 44'));
      expect(opened, ['e0']); // e0 = the latest-dated seeded doc (i = 44)
    });
  });
}
