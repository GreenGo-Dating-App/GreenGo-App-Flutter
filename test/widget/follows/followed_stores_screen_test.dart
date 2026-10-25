import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/services/user_directory_service.dart';
import 'package:greengo_chat/features/follows/presentation/screens/followed_stores_screen.dart';
import 'package:greengo_chat/features/profile/data/models/profile_model.dart';
import 'package:greengo_chat/features/profile/domain/entities/business_address.dart';
import 'package:greengo_chat/features/profile/domain/entities/profile.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

import '../../support/profile_fixtures.dart';
import 'follow_test_support.dart';

const me = 'me';

/// A business profile as the app parses it from Firestore (incl. the
/// read-only `ratingSum` / `ratingCount`).
Profile shop(String id, String name,
    {String? category, String? city, String? country, int ratingSum = 0, int ratingCount = 0}) {
  final base = buildProfile(
    userId: id,
    displayName: 'Owner $id',
    isBusiness: true,
    businessName: name,
    photoUrls: const [],
  ) as ProfileModel;
  return ProfileModel.fromJson({
    ...base.toJson(),
    'userId': id,
    'businessCategory': category,
    if (country != null)
      'businessAddress': BusinessAddress(
        address: '1 Main St',
        latitude: 41.9,
        longitude: 12.5,
        city: city ?? '',
        country: country,
      ).toMap(),
    'ratingSum': ratingSum,
    'ratingCount': ratingCount,
  });
}

void main() {
  late FollowWorld w;
  final l10n = lookupAppLocalizations(const Locale('en'));

  /// Follow [p] as [me] with the store fields the server stamps.
  Future<void> followStore(Profile p) async {
    final a = p.businessAddress;
    await w.fs
        .collection('user_business_following')
        .doc(me)
        .collection('businesses')
        .doc(p.userId)
        .set({
      'createdAt': 1,
      'isStore': true,
      'storeNameLower': p.businessName!.toLowerCase().replaceAll('é', 'e'),
      'storeCategory': p.businessCategory ?? '',
      'storeCountry': a?.country ?? '',
      'storeCityLower': (a?.city ?? '').toLowerCase(),
    });
  }

  Future<void> facet(String sub, Map<String, Object> data) => w.fs
      .collection('user_store_places')
      .doc(me)
      .collection(sub)
      .add(data);

  setUp(() async {
    w = FollowWorld();
    final stores = [
      shop('s1', 'Café Roma', category: 'Cafe', city: 'Rome', country: 'Italy', ratingSum: 13, ratingCount: 3),
      shop('s2', 'Caffè Milano', category: 'Cafe', city: 'Milan', country: 'Italy'),
      shop('s3', 'Casa Porto', category: 'Bar', city: 'Porto', country: 'Portugal', ratingSum: 5, ratingCount: 1),
      shop('s4', 'Roma Bar', category: 'Bar', city: 'Rome', country: 'Italy', ratingSum: 40, ratingCount: 10),
    ];
    for (final s in stores) {
      await followStore(s);
    }
    UserDirectoryService.instance.debugSeedProfiles({for (final s in stores) s.userId: s});
    await facet('countries', {'country': 'Italy', 'n': 3});
    await facet('countries', {'country': 'Portugal', 'n': 1});
    await facet('cities', {'country': 'Italy', 'city': 'Rome', 'cityLower': 'rome', 'n': 2});
    await facet('cities', {'country': 'Italy', 'city': 'Milan', 'cityLower': 'milan', 'n': 1});
  });

  tearDown(() => w.dispose());

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale('en'),
      home: FollowedStoresScreen(userId: me),
    ));
    await tester.pumpAndSettle();
  }

  List<String> rowIds(WidgetTester tester) => tester
      .widgetList<FollowedStoreRow>(find.byType(FollowedStoreRow))
      .map((r) => r.store.userId)
      .toList();

  testWidgets('rows show name, category, place and stars (hidden without ratings)', (tester) async {
    await pumpScreen(tester);
    expect(rowIds(tester), ['s1', 's2', 's3', 's4']);

    final s1 = find.byKey(const ValueKey('followed_store_s1'));
    expect(find.descendant(of: s1, matching: find.text('Café Roma')), findsOneWidget);
    expect(
      find.descendant(
          of: s1, matching: find.text('${l10n.bizCatCafe} · 🇮🇹 Rome, ${l10n.countryNameIT}')),
      findsOneWidget,
    );
    expect(find.descendant(of: s1, matching: find.text(l10n.followedStoresRating('4.3', '3'))),
        findsOneWidget);
    // Screen readers hear a sentence, not "star 4.3 (3)".
    expect(
      find.descendant(
          of: s1,
          matching: find.byWidgetPredicate((w) =>
              w is Semantics &&
              w.properties.label == l10n.followedStoresRatingSemantics('4.3', 3))),
      findsOneWidget,
    );

    final s2 = find.byKey(const ValueKey('followed_store_s2'));
    expect(find.descendant(of: s2, matching: find.byKey(const Key('followed_store_rating'))), findsNothing);
    final s4 = find.byKey(const ValueKey('followed_store_s4'));
    expect(find.descendant(of: s4, matching: find.text(l10n.followedStoresRating('4.0', '10'))),
        findsOneWidget);
  });

  testWidgets('search is debounced and server-side over all followed stores', (tester) async {
    await pumpScreen(tester);
    await tester.enterText(find.byKey(const Key('followed_stores_search')), 'CAF');
    await tester.pump(const Duration(milliseconds: 100));
    expect(rowIds(tester), ['s1', 's2', 's3', 's4']); // not yet: debounced
    await tester.pump(FollowedStoresScreen.debounce);
    await tester.pumpAndSettle();
    expect(rowIds(tester), ['s1', 's2']);

    await tester.enterText(find.byKey(const Key('followed_stores_search')), 'zzz');
    await tester.pump(FollowedStoresScreen.debounce);
    await tester.pumpAndSettle();
    expect(rowIds(tester), isEmpty);
    expect(find.text(l10n.followedStoresNoResults), findsOneWidget);

    // Clearing returns to the plain list.
    await tester.tap(find.byTooltip(l10n.userFollowSearchClear));
    await tester.pumpAndSettle();
    expect(rowIds(tester), ['s1', 's2', 's3', 's4']);
  });

  testWidgets('category filter from the full category list', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.byKey(const Key('followed_stores_filter_category')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.followedStoresAllCategories), findsOneWidget);
    await tester.scrollUntilVisible(find.byKey(const Key('followed_stores_category_Bar')), 200,
        scrollable: find.descendant(of: find.byType(BottomSheet), matching: find.byType(Scrollable)));
    await tester.tap(find.byKey(const Key('followed_stores_category_Bar')));
    await tester.pumpAndSettle();
    expect(rowIds(tester), ['s3', 's4']);
    expect(find.descendant(
        of: find.byKey(const Key('followed_stores_filter_category')),
        matching: find.text(l10n.bizCatBar)), findsOneWidget);

    await tester.tap(find.byKey(const Key('followed_stores_clear_filters')));
    await tester.pumpAndSettle();
    expect(rowIds(tester), ['s1', 's2', 's3', 's4']);
  });

  testWidgets('place filter: the user\'s own countries, then a city; combines with search', (tester) async {
    await pumpScreen(tester);
    await tester.tap(find.byKey(const Key('followed_stores_filter_place')));
    await tester.pumpAndSettle();
    // Only the countries of the followed stores, most stores first.
    expect(find.text('🇮🇹 ${l10n.countryNameIT}'), findsOneWidget);
    expect(find.text('🇵🇹 ${l10n.countryNamePT}'), findsOneWidget);
    expect(find.text('🇫🇷 ${l10n.countryNameFR}'), findsNothing);

    await tester.tap(find.byKey(const Key('followed_stores_place_Italy')));
    await tester.pumpAndSettle();
    expect(find.text(l10n.followedStoresAllOfCountry(l10n.countryNameIT)), findsOneWidget);
    await tester.tap(find.byKey(const Key('followed_stores_city_rome')));
    await tester.pumpAndSettle();
    expect(rowIds(tester), ['s1', 's4']);
    expect(find.descendant(
        of: find.byKey(const Key('followed_stores_filter_place')),
        matching: find.text('Rome, ${l10n.countryNameIT}')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('followed_stores_search')), 'roma');
    await tester.pump(FollowedStoresScreen.debounce);
    await tester.pumpAndSettle();
    expect(rowIds(tester), ['s4']);

    // Whole country.
    await tester.enterText(find.byKey(const Key('followed_stores_search')), '');
    await tester.pump(FollowedStoresScreen.debounce);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('followed_stores_filter_place')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('followed_stores_place_Italy')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('followed_stores_city_all')));
    await tester.pumpAndSettle();
    expect(rowIds(tester), ['s1', 's2', 's4']);
  });

  testWidgets('empty list: the plain empty state, no search box', (tester) async {
    await w.dispose();
    w = FollowWorld();
    await pumpScreen(tester);
    expect(find.text(l10n.userFollowEmptyStores), findsOneWidget);
    expect(find.byKey(const Key('followed_stores_search')), findsNothing);
  });
}
