import 'dart:io';

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
import 'package:greengo_chat/features/business/domain/business_name.dart';
import 'package:greengo_chat/features/discovery/presentation/widgets/network_grid_card.dart';
import 'package:greengo_chat/features/explore/presentation/screens/network_discovery_screen.dart';
import 'package:greengo_chat/features/matching/domain/entities/match_candidate.dart';
import 'package:greengo_chat/features/matching/domain/entities/match_score.dart';
import 'package:greengo_chat/features/business/domain/business_distance.dart';
import 'package:greengo_chat/features/profile/domain/entities/business_address.dart';
import 'package:greengo_chat/features/profile/domain/entities/location.dart';
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

MatchCandidate _candidate(Profile p, {double distance = 3}) => MatchCandidate(
      profile: p,
      matchScore: MatchScore(
        userId1: 'me',
        userId2: p.userId,
        overallScore: 0,
        breakdown: const ScoreBreakdown(
            locationScore: 0, ageCompatibilityScore: 0, interestOverlapScore: 0),
        calculatedAt: DateTime(2026, 10, 19),
      ),
      distance: distance,
      suggestedAt: DateTime(2026, 10, 19),
    );

Future<String?> _tileImage(WidgetTester t, Profile p, {required bool isBusiness, bool isSelf = false}) async {
  await t.pumpWidget(_app(Scaffold(
    body: SizedBox(
      width: 200,
      height: 300,
      child: NetworkGridCard(
        candidate: _candidate(p),
        isSelf: isSelf,
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
    const logo = 'https://example.com/elena_logo.jpg';

    test('business profile picture first, then cover, gallery, personal photo', () {
      final withLogo = business.copyWith(businessLogoUrl: logo);
      expect(NetworkGridCard.mainPhotoUrl(withLogo, isBusiness: true), logo);
      expect(NetworkGridCard.tilePhotoUrls(withLogo, isBusiness: true), [
        logo,
        'https://example.com/elena_cover.jpg',
        'https://example.com/g1.jpg',
        'https://example.com/g2.jpg',
      ]);
      // '' logo = none -> the previous order (cover first).
      expect(NetworkGridCard.mainPhotoUrl(business.copyWith(businessLogoUrl: ''), isBusiness: true),
          'https://example.com/elena_cover.jpg');
      // People tiles never use the business picture.
      expect(NetworkGridCard.mainPhotoUrl(withLogo, isBusiness: false), 'https://example.com/profile.jpg');
    });

    testWidgets('business tile renders the business profile picture', (t) async {
      expect(await _tileImage(t, business.copyWith(businessLogoUrl: logo), isBusiness: true), logo);
    });

    test('storefront avatar: business picture, else the first personal photo', () {
      expect(BusinessStorefrontScreen.avatarImageFor(business.copyWith(businessLogoUrl: logo)), logo);
      expect(BusinessStorefrontScreen.avatarImageFor(business), 'https://example.com/profile.jpg');
    });

    test('featured (cover) image, else first gallery image, else the profile photo', () {
      expect(NetworkGridCard.mainPhotoUrl(business, isBusiness: true), 'https://example.com/elena_cover.jpg');
      final noCover = business.copyWith(coverImageUrl: '');
      expect(NetworkGridCard.mainPhotoUrl(noCover, isBusiness: true), 'https://example.com/g1.jpg');
      expect(NetworkGridCard.mainPhotoUrl(noCover.copyWith(galleryImages: const []), isBusiness: true),
          'https://example.com/profile.jpg');
      // Cover first, then the gallery (no duplicate of the cover).
      expect(
          NetworkGridCard.tilePhotoUrls(
              business.copyWith(galleryImages: const ['https://example.com/elena_cover.jpg', 'https://example.com/g2.jpg']),
              isBusiness: true),
          ['https://example.com/elena_cover.jpg', 'https://example.com/g2.jpg']);
      // People tiles are unchanged.
      expect(NetworkGridCard.mainPhotoUrl(business, isBusiness: false), 'https://example.com/profile.jpg');
    });

    testWidgets('business tile renders the featured (cover) image', (t) async {
      expect(await _tileImage(t, business, isBusiness: true), 'https://example.com/elena_cover.jpg');
    });

    testWidgets('business tile without a cover falls back to the first gallery image', (t) async {
      expect(await _tileImage(t, business.copyWith(coverImageUrl: ''), isBusiness: true),
          'https://example.com/g1.jpg');
    });

    testWidgets('business tile without cover and gallery falls back to the profile photo', (t) async {
      expect(await _tileImage(t, business.copyWith(coverImageUrl: '', galleryImages: const []), isBusiness: true),
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

  group('A. business identity on Discover tiles (incl. own tile)', () {
    test('own business tile renders as a business only in Businesses mode', () {
      expect(discoveryTileIsBusiness(business, isSelf: true, businessMode: true), isTrue);
      expect(discoveryTileIsBusiness(business, isSelf: true, businessMode: false), isFalse);
      expect(discoveryTileIsBusiness(business, isSelf: false, businessMode: true), isTrue);
      final person = buildProfile();
      expect(discoveryTileIsBusiness(person, isSelf: true, businessMode: true), isFalse);
      expect(discoveryTileIsBusiness(person, isSelf: false, businessMode: false), isFalse);
    });

    test('search / tag name is the business name for business tiles', () {
      final c = _candidate(business);
      expect(discoveryTileName(c, asBusiness: true), "Elena's Cafe");
      expect(discoveryTileName(c, asBusiness: false), 'Elena Marco');
      expect(BusinessName.displayFor(business.copyWith(businessName: '  ')), 'Elena Marco');
    });

    testWidgets('own tile in Businesses mode: business name + featured image, no age', (t) async {
      final url = await _tileImage(t, business, isBusiness: true, isSelf: true);
      expect(url, 'https://example.com/elena_cover.jpg');
      final name = t.widget<Text>(find.byKey(const ValueKey('network-grid-card-name'))).data;
      expect(name, "Elena's Cafe");
      expect(find.textContaining('Elena Marco'), findsNothing);
    });

    test('Discover AppBar has no mode title text (owner 2026-10-19)', () {
      final src = File('lib/features/explore/presentation/screens/network_discovery_screen.dart').readAsStringSync();
      expect(src.contains('discover-mode-title'), isFalse);
      // The People | Businesses switch floats at the bottom (owner, 2026-10-19).
      expect(src.contains('floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat'), isTrue);
      expect(src.contains('discover-people-business-switch'), isTrue);
      expect(src.contains('l10n.exploreBusinessAccounts'), isFalse);
    });

    testWidgets('person tile keeps "Name, age"', (t) async {
      await _tileImage(t, business, isBusiness: false);
      final name = t.widget<Text>(find.byKey(const ValueKey('network-grid-card-name'))).data;
      expect(name, startsWith('Elena Marco, '));
    });
  });

  group('2. mandatory BUSINESS PROFILE PICTURE (featured image optional)', () {
    const logo = 'https://example.com/elena_logo.jpg';

    test('checklist: business picture is the REQUIRED item (cover/gallery do not count)', () {
      expect(CompanyItem.storefrontPhoto.required, isTrue);
      final withLogo = business.copyWith(businessLogoUrl: logo);
      expect(companyChecklist(withLogo)[CompanyItem.storefrontPhoto], isTrue);
      // Cover + gallery but no business picture -> missing.
      expect(business.coverImageUrl, isNotEmpty);
      expect(business.galleryImages, isNotEmpty);
      expect(companyChecklist(business)[CompanyItem.storefrontPhoto], isFalse);
      expect(missingRequired(companyChecklist(business)), contains(CompanyItem.storefrontPhoto));
      // No cover is fine once the business picture exists.
      expect(
          missingRequired(companyChecklist(withLogo.copyWith(coverImageUrl: ''))),
          isNot(contains(CompanyItem.storefrontPhoto)));
    });

    test('editor validator', () {
      expect(StorefrontEditorScreen.hasRequiredLogo(null), isFalse);
      expect(StorefrontEditorScreen.hasRequiredLogo(''), isFalse);
      expect(StorefrontEditorScreen.hasRequiredLogo(' '), isFalse);
      expect(StorefrontEditorScreen.hasRequiredLogo('https://x/l.jpg'), isTrue);
    });

    testWidgets('editor: saves without a featured image when the business picture exists', (t) async {
      t.view.physicalSize = const Size(1200, 6000);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      registerFallbackValue(ProfileUpdateRequested(profile: business));
      final bloc = _MockProfileBloc();
      when(() => bloc.state).thenReturn(const ProfileInitial());
      when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
      final p = business.copyWith(coverImageUrl: '', businessLogoUrl: logo);
      await t.pumpWidget(_app(BlocProvider<ProfileBloc>.value(
        value: bloc,
        child: StorefrontEditorScreen(profile: p),
      )));
      await t.pump();
      final l = AppLocalizations.of(t.element(find.byType(StorefrontEditorScreen)))!;
      // The section sits at the top, above the business name.
      expect(find.text('${l.storefrontLogoTitle} *'), findsOneWidget);
      expect(find.text('${l.storefrontFeaturedImage} *'), findsNothing);
      expect(
          t.getTopLeft(find.byKey(const Key('storefront_logo_picker'))).dy,
          lessThan(t.getTopLeft(find.byKey(const ValueKey('storefront-business-name'))).dy));
      final save = find.widgetWithText(ElevatedButton, l.save);
      await t.ensureVisible(save);
      await t.tap(save);
      await t.pump();
      final ev = verify(() => bloc.add(captureAny())).captured.single as ProfileUpdateRequested;
      expect(ev.profile.businessLogoUrl, logo);
      // Saving never touches the personal photos.
      expect(ev.profile.photoUrls, business.photoUrls);
    });

    testWidgets('editor: save without a business picture shows the inline error + snackbar and does not save', (t) async {
      t.view.physicalSize = const Size(1200, 6000);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      registerFallbackValue(ProfileUpdateRequested(profile: business));
      final bloc = _MockProfileBloc();
      when(() => bloc.state).thenReturn(const ProfileInitial());
      when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
      // A cover and a gallery are not enough.
      final p = business.copyWith(photoUrls: const []);
      await t.pumpWidget(_app(BlocProvider<ProfileBloc>.value(
        value: bloc,
        child: StorefrontEditorScreen(profile: p),
      )));
      await t.pump();
      final l = AppLocalizations.of(t.element(find.byType(StorefrontEditorScreen)))!;
      expect(find.byKey(const Key('storefront_logo_required_error')), findsNothing);
      final save = find.widgetWithText(ElevatedButton, l.save);
      await t.ensureVisible(save);
      await t.tap(save);
      await t.pump();
      await t.pump(const Duration(milliseconds: 500));
      expect(find.byKey(const Key('storefront_logo_required_error')), findsOneWidget);
      // Inline error + the "why" sheet (business picture required).
      expect(find.text(l.storefrontLogoRequiredError), findsNWidgets(2));
      expect(find.text(l.xplLockedStorefrontTitle), findsOneWidget);
      verifyNever(() => bloc.add(any()));
    });
  });

  group('B. business profile name in the storefront editor', () {
    late _MockProfileBloc bloc;
    setUp(() {
      registerFallbackValue(ProfileUpdateRequested(profile: business));
      bloc = _MockProfileBloc();
      when(() => bloc.state).thenReturn(const ProfileInitial());
      when(() => bloc.stream).thenAnswer((_) => const Stream.empty());
    });

    Future<AppLocalizations> pumpEditor(WidgetTester t, Profile p) async {
      t.view.physicalSize = const Size(1200, 6000);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.resetPhysicalSize);
      addTearDown(t.view.resetDevicePixelRatio);
      await t.pumpWidget(_app(BlocProvider<ProfileBloc>.value(value: bloc, child: StorefrontEditorScreen(profile: p))));
      await t.pump();
      return AppLocalizations.of(t.element(find.byType(StorefrontEditorScreen)))!;
    }

    test('shared validation (same as Business account)', () {
      expect(BusinessName.isValid(''), isFalse);
      expect(BusinessName.isValid('   '), isFalse);
      expect(BusinessName.isValid(' Cafe '), isTrue);
      expect(BusinessName.normalize('  Cafe Lua '), 'Cafe Lua');
    });

    final bizWithLogo = business.copyWith(businessLogoUrl: 'https://example.com/elena_logo.jpg');

    testWidgets('prefilled; an empty name blocks the save with a localized error', (t) async {
      final l = await pumpEditor(t, bizWithLogo);
      final field = find.byKey(const ValueKey('storefront-business-name'));
      expect(t.widget<TextField>(field).controller!.text, "Elena's Cafe");
      await t.enterText(field, '   ');
      final save = find.widgetWithText(ElevatedButton, l.save);
      await t.ensureVisible(save);
      await t.tap(save);
      await t.pump();
      expect(find.text(l.businessProfileNameRequiredError), findsWidgets);
      verifyNever(() => bloc.add(any()));
    });

    testWidgets('saves the trimmed business name with the rest of the storefront', (t) async {
      final l = await pumpEditor(t, bizWithLogo);
      await t.enterText(find.byKey(const ValueKey('storefront-business-name')), '  Cafe Lua  ');
      final save = find.widgetWithText(ElevatedButton, l.save);
      await t.ensureVisible(save);
      await t.tap(save);
      await t.pump();
      final ev = verify(() => bloc.add(captureAny())).captured.single as ProfileUpdateRequested;
      expect(ev.profile.businessName, 'Cafe Lua');
      expect(ev.profile.galleryImages, business.galleryImages);
      // The storefront never touches the owner's personal avatar.
      expect(ev.profile.photoUrls, business.photoUrls);
      expect(ev.profile.coverImageUrl, business.coverImageUrl);
      expect(ev.profile.businessLogoUrl, bizWithLogo.businessLogoUrl);
    });

    testWidgets('no personal Profile image section; gallery is optional', (t) async {
      final l = await pumpEditor(t, bizWithLogo.copyWith(galleryImages: const []));
      expect(find.text('Profile image'), findsNothing);
      expect(find.text('Add profile image'), findsNothing);
      final save = find.widgetWithText(ElevatedButton, l.save);
      await t.ensureVisible(save);
      await t.tap(save);
      await t.pump();
      final ev = verify(() => bloc.add(captureAny())).captured.single as ProfileUpdateRequested;
      expect(ev.profile.galleryImages, isEmpty);
      expect(ev.profile.photoUrls, business.photoUrls);
    });
  });

  group('3. business distance from the BUSINESS ADDRESS (owner 2026-10-19)', () {
    // Viewer in Sao Paulo (Praca da Se).
    const viewer = Location(latitude: -23.5503, longitude: -46.6339, city: 'Sao Paulo', country: 'Brazil', displayAddress: '');
    Profile bizAt(String id, double lat, double lng, {bool promoted = false}) =>
        buildBusinessProfile(promoted: promoted).copyWith(
          userId: id,
          businessAddress: BusinessAddress(address: 'Rua $id', latitude: lat, longitude: lng),
        );

    test('measured from the address, not the owner location; null without address', () {
      // ~1.11 km north of the viewer (0.01 deg latitude).
      final b = bizAt('b1', -23.5403, -46.6339);
      final km = BusinessDistance.kmToAddress(b, viewer)!;
      expect(km, closeTo(1.11, 0.02));
      expect(BusinessDistance.kmToAddress(buildBusinessProfile(), viewer), isNull);
      expect(BusinessDistance.kmToAddress(b, null), isNull);
      expect(BusinessDistance.kmToAddress(b, const Location(latitude: 0, longitude: 0, city: '', country: '', displayAddress: '')),
          isNull);
      // People are never measured from an address.
      expect(BusinessDistance.kmToAddress(b.copyWith(isBusiness: false), viewer), isNull);
    });

    test('business mode order: nearest-first by address; no address keeps the pool distance', () {
      final far = _candidate(bizAt('far', -23.6503, -46.6339), distance: 0.5); // ~11 km
      final near = _candidate(bizAt('near', -23.5513, -46.6339), distance: 40); // ~110 m
      final noAddr = _candidate(buildBusinessProfile(promoted: false).copyWith(userId: 'noaddr'), distance: 5);
      final unknown = _candidate(buildBusinessProfile(promoted: false).copyWith(userId: 'unknown'), distance: 0);
      final r = orderBusinessTiles([unknown, far, noAddr, near], viewer);
      expect(r.candidates.map((c) => c.profile.userId), ['near', 'noaddr', 'far', 'unknown']);
      expect(r.addressBasedIds, {'near', 'far'});
      expect(r.candidates.first.distance, closeTo(0.111, 0.005));
      expect(r.candidates[1].distance, 5); // fallback: unchanged
    });

    test('promoted (max 5) float to the top, each group nearest-first', () {
      final list = [
        for (var i = 0; i < 7; i++)
          _candidate(bizAt('p$i', -23.5503 - (7 - i) * 0.01, -46.6339, promoted: true)),
        _candidate(bizAt('r0', -23.5513, -46.6339)),
      ];
      final ids = orderBusinessTiles(list, viewer).candidates.map((c) => c.profile.userId).toList();
      // p6 is nearest among the promoted; the 2 farthest promoted fall back
      // into the normal nearest-first order after r0 (the nearest of all).
      expect(ids, ['p6', 'p5', 'p4', 'p3', 'p2', 'r0', 'p1', 'p0']);
    });

    Future<void> pumpTile(WidgetTester t, MatchCandidate c, {required bool fromAddress}) =>
        t.pumpWidget(_app(Scaffold(
          body: SizedBox(
            width: 200,
            height: 300,
            child: NetworkGridCard(
              candidate: c,
              isSelf: false,
              isBusiness: true,
              distanceFromBusinessAddress: fromAddress,
              onOpenProfile: () {},
              onLongPressTag: () {},
            ),
          ),
        )));

    testWidgets('tile shows the address distance with 100 m resolution', (t) async {
      final r = orderBusinessTiles([_candidate(bizAt('b', -23.5530, -46.6339), distance: 3)], viewer); // ~300 m
      await pumpTile(t, r.candidates.single, fromAddress: r.addressBasedIds.contains('b'));
      expect(find.text('300 m'), findsOneWidget);
      final r2 = orderBusinessTiles([_candidate(bizAt('b2', -23.5395, -46.6339), distance: 3)], viewer); // ~1.2 km
      await pumpTile(t, r2.candidates.single, fromAddress: true);
      expect(find.text('1.2 km'), findsOneWidget);
    });

    testWidgets('fallback (no address): the approximate bucket as today', (t) async {
      final r = orderBusinessTiles([_candidate(buildBusinessProfile(), distance: 3)], viewer);
      expect(r.addressBasedIds, isEmpty);
      await pumpTile(t, r.candidates.single, fromAddress: false);
      expect(find.text('< 5 km'), findsOneWidget);
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
