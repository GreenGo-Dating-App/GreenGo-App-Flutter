import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/error/failures.dart';
import 'package:greengo_chat/core/widgets/map_basemap_layer.dart';
import 'package:greengo_chat/features/globe_explore/domain/entities/globe_user.dart';
import 'package:greengo_chat/features/globe_explore/domain/repositories/globe_repository.dart';
import 'package:greengo_chat/features/globe_explore/domain/usecases/get_globe_data.dart';
import 'package:greengo_chat/features/globe_explore/presentation/bloc/globe_bloc.dart';
import 'package:greengo_chat/features/globe_explore/presentation/bloc/globe_filter_store.dart';
import 'package:greengo_chat/features/globe_explore/presentation/screens/globe_screen.dart';
import 'package:greengo_chat/generated/app_localizations.dart';

const _me = GlobeUser(
  userId: 'me',
  displayName: 'Me',
  pinLatitude: 41.9,
  pinLongitude: 12.5,
  country: 'Italy',
  city: 'Rome',
  pinType: GlobePinType.currentUser,
);

GlobeUser _person(String id, double lat, Set<GlobeRelation> rels) =>
    GlobeUser(
      userId: id,
      displayName: id,
      pinLatitude: lat,
      pinLongitude: 12.45,
      country: 'Italy',
      city: 'Rome',
      pinType: GlobePinType.matched,
      relations: rels,
    );

const _biz = GlobeUser(
  userId: 'biz',
  displayName: 'Cafe Roma',
  pinLatitude: 41.88,
  pinLongitude: 12.55,
  country: 'Italy',
  city: 'Rome',
  pinType: GlobePinType.business,
  isBusiness: true,
  relations: {GlobeRelation.following},
);

class _Repo implements GlobeRepository {
  @override
  Future<GlobeUser?> getCurrentUserPin({required String userId}) async => _me;

  @override
  Future<Either<Failure, GlobeData>> getGlobeData(
          {required String userId}) async =>
      Right(GlobeData(
        currentUser: _me,
        matchedUsers: [
          _person('fol', 41.95, {GlobeRelation.following}),
          _person('fan', 41.85, {GlobeRelation.follower}),
          _person('both', 41.92, {
            GlobeRelation.follower,
            GlobeRelation.chatted,
          }),
          _biz,
        ],
        discoveryUsers: const [],
      ));
}

class _MemStore implements GlobeFilterStore {
  Set<GlobeNetworkFilter>? saved;
  @override
  Future<Set<GlobeNetworkFilter>> load() async => saved ?? kAllGlobeFilters;
  @override
  Future<void> save(Set<GlobeNetworkFilter> filters) async => saved = filters;
}

void main() {
  setUpAll(() => MapBasemapLayer.debugDisableTiles = true);
  tearDownAll(() => MapBasemapLayer.debugDisableTiles = false);

  Finder pin(String id) => find.byKey(ValueKey('globe-pin-$id'));
  Finder chip(GlobeNetworkFilter f) =>
      find.byKey(ValueKey('globe-filter-${f.name}'));

  Future<void> toggle(WidgetTester tester, GlobeNetworkFilter f) async {
    // The chip row scrolls horizontally on narrow screens.
    await tester.ensureVisible(chip(f));
    await tester.pump();
    await tester.tap(chip(f));
    await tester.pump();
  }

  Future<_MemStore> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    final repo = _Repo();
    final store = _MemStore();
    await tester.pumpWidget(MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider(
        create: (_) => GlobeBloc(
          getGlobeData: GetGlobeData(repo),
          repository: repo,
          filterStore: store,
        ),
        child: const GlobeScreen(userId: 'me'),
      ),
    ));
    await tester.pump();
    await tester.pump();
    await tester.pump();
    return store;
  }

  testWidgets('chips show every group by default; toggling hides / shows pins',
      (tester) async {
    final store = await pumpScreen(tester);
    for (final f in GlobeNetworkFilter.values) {
      expect(chip(f), findsOneWidget);
    }
    expect(pin('fol'), findsOneWidget);
    expect(pin('fan'), findsOneWidget);
    expect(pin('both'), findsOneWidget);
    expect(pin('biz'), findsOneWidget);
    expect(pin('self'), findsOneWidget);

    // Following off: only the followed person disappears.
    await toggle(tester, GlobeNetworkFilter.following);
    expect(pin('fol'), findsNothing);
    expect(pin('fan'), findsOneWidget);
    expect(pin('biz'), findsOneWidget);
    expect(store.saved, isNot(contains(GlobeNetworkFilter.following)));

    // Followers off too: 'both' stays (still a chat), 'fan' goes.
    await toggle(tester, GlobeNetworkFilter.followers);
    expect(pin('fan'), findsNothing);
    expect(pin('both'), findsOneWidget);

    // Businesses off: the business pin goes, the own pin always stays.
    await toggle(tester, GlobeNetworkFilter.businesses);
    expect(pin('biz'), findsNothing);
    expect(pin('self'), findsOneWidget);

    // Following back on.
    await toggle(tester, GlobeNetworkFilter.following);
    expect(pin('fol'), findsOneWidget);
  });

  testWidgets('a pin in several groups shows its relation badges',
      (tester) async {
    await pumpScreen(tester);
    final badges = find.descendant(
        of: pin('both'), matching: find.byKey(const ValueKey('globe-pin-badges')));
    expect(badges, findsOneWidget);
    expect(
        find.descendant(of: badges, matching: find.byType(Icon)),
        findsNWidgets(2));
    // The business pin shows its name.
    expect(find.descendant(of: pin('biz'), matching: find.text('Cafe Roma')),
        findsOneWidget);
  });
}
