import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/communities/data/datasources/community_favorites_service.dart';
import 'package:greengo_chat/features/communities/domain/entities/community.dart';
import 'package:greengo_chat/features/communities/presentation/bloc/communities_bloc.dart';
import 'package:greengo_chat/features/communities/presentation/bloc/communities_event.dart';
import 'package:greengo_chat/features/communities/presentation/bloc/communities_state.dart';
import 'package:greengo_chat/features/communities/presentation/screens/communities_screen.dart';
import 'package:greengo_chat/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:greengo_chat/features/profile/presentation/bloc/profile_state.dart';
import 'package:greengo_chat/generated/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockCommunitiesBloc extends Mock implements CommunitiesBloc {}

class _MockProfileBloc extends Mock implements ProfileBloc {}

/// In-memory favorites (same contract as the Firestore service).
class _FakeFavorites extends Fake implements CommunityFavoritesService {
  _FakeFavorites(this.ids, this.docs);
  List<String> ids;
  final Map<String, Community> docs;
  final List<(String, bool)> writes = [];

  @override
  Future<List<String>> getOrdered(String userId) async => List.of(ids);

  @override
  Future<Set<String>> getAll(String userId) async => ids.toSet();

  @override
  Future<Map<String, Community>> loadCommunities(List<String> ids) async => {
        for (final id in ids)
          if (docs[id] != null) id: docs[id]!
      };

  @override
  Future<void> setFavorite(String userId, String id, bool favorite) async {
    writes.add((id, favorite));
    ids = favorite
        ? [...ids, id]
        : [
            for (final x in ids)
              if (x != id) x
          ];
  }
}

Community community(String id, {String? name, DateTime? activity}) => Community(
      id: id,
      name: name ?? 'Community $id',
      description: 'about $id',
      type: CommunityType.languageCircle,
      createdByUserId: 'someone',
      createdByName: 'Someone',
      createdAt: DateTime(2026, 1, 1),
      memberCount: 10,
      languages: const ['en'],
      lastActivityAt: activity ?? DateTime(2026, 5, 1),
    );

void main() {
  setUpAll(() {
    registerFallbackValue(const LoadCommunities());
  });

  late _MockCommunitiesBloc bloc;
  late _MockProfileBloc profile;

  setUp(() {
    // The first-time Communities tour is already done for this user.
    SharedPreferences.setMockInitialValues({'tour_communities_done_me': true});
    bloc = _MockCommunitiesBloc();
    profile = _MockProfileBloc();
    when(() => profile.state).thenReturn(const ProfileInitial());
    when(() => profile.stream).thenAnswer((_) => const Stream.empty());
  });

  Future<_FakeFavorites> pump(
    WidgetTester tester, {
    required List<Community> joined,
    List<String> favorites = const [],
    Map<String, Community> favoriteDocs = const {},
    Stream<CommunitiesState>? stream,
  }) async {
    final state =
        CommunitiesLoaded(userCommunities: joined, managedLoaded: true);
    when(() => bloc.state).thenReturn(state);
    when(() => bloc.stream)
        .thenAnswer((_) => stream ?? const Stream<CommunitiesState>.empty());
    final fav = _FakeFavorites(
        List.of(favorites), {...favoriteDocs, for (final c in joined) c.id: c});
    tester.view.physicalSize = const Size(400, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await mockNetworkImagesFor(() => tester.pumpWidget(MultiBlocProvider(
          providers: [
            BlocProvider<CommunitiesBloc>.value(value: bloc),
            BlocProvider<ProfileBloc>.value(value: profile),
          ],
          child: MaterialApp(
            locale: const Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: CommunitiesScreen(currentUserId: 'me', favoritesService: fav),
          ),
        )));
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    return fav;
  }

  List<String> cardOrder(WidgetTester tester) {
    final keys = <String>[];
    for (final e in find
        .byWidgetPredicate((w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith('joined-'))
        .evaluate()) {
      keys.add((e.widget.key! as ValueKey<String>).value.substring(7));
    }
    return keys;
  }

  testWidgets('tab order: Joined (default), Discover, My communities',
      (tester) async {
    await pump(tester, joined: [community('a')]);
    final tabs = tester.widget<TabBar>(find.byType(TabBar)).tabs;
    String label(Widget t) =>
        ((((t as Tab).child! as FittedBox).child!) as Text).data!;
    expect(tabs.map(label).toList(),
        ['Joined Communities', 'Discover', 'My communities']);
    final controller = tester.widget<TabBar>(find.byType(TabBar)).controller!;
    expect(controller.index, CommunitiesScreen.joinedTab);
    expect(CommunitiesScreen.joinedTab, 0);
    expect(CommunitiesScreen.discoverTab, 1);
    expect(CommunitiesScreen.managedTab, 2);
    // The Joined list is what shows first.
    expect(find.byKey(const ValueKey('joined-a')), findsOneWidget);
  });

  testWidgets('favorites pinned on top, newest starred first, then the rest',
      (tester) async {
    final joined = [
      community('a'),
      community('b'),
      community('c'),
      community('d'),
    ];
    // Starred c first, then a (a is the newest favorite).
    await pump(tester, joined: joined, favorites: ['c', 'a']);
    expect(cardOrder(tester), ['a', 'c', 'b', 'd']);
    expect(find.text('FAVORITES'), findsOneWidget);
    expect(find.text('ALL JOINED'), findsOneWidget);
  });

  testWidgets('a favorite outside the loaded joined page is still pinned',
      (tester) async {
    // 30 joined communities; only the first 20 are revealed at first, the
    // favorite is #30 and still shows on top (loaded separately).
    final joined = [for (var i = 0; i < 30; i++) community('c$i')];
    await pump(tester, joined: joined, favorites: ['c29']);
    final order = cardOrder(tester);
    expect(order.first, 'c29');
    expect(order.where((x) => x == 'c29').length, 1);
  });

  testWidgets('a favorite I am no longer a member of is not shown',
      (tester) async {
    await pump(tester,
        joined: [community('a')],
        favorites: ['gone'],
        favoriteDocs: {'gone': community('gone')});
    expect(cardOrder(tester), ['a']);
    expect(find.text('FAVORITES'), findsNothing);
  });

  testWidgets('star toggle: optimistic pin + server write; unstar unpins',
      (tester) async {
    final fav = await pump(tester,
        joined: [community('a'), community('b')], favorites: const []);
    expect(cardOrder(tester), ['a', 'b']);
    await tester.tap(find.byKey(const ValueKey('fav-b')));
    await tester.pumpAndSettle();
    expect(fav.writes, [('b', true)]);
    expect(cardOrder(tester), ['b', 'a']);
    await tester.tap(find.byKey(const ValueKey('fav-b')));
    await tester.pumpAndSettle();
    expect(fav.writes.last, ('b', false));
    expect(cardOrder(tester), ['a', 'b']);
  });

  testWidgets('the 51st star shows a friendly cap message, no write',
      (tester) async {
    final ids = [for (var i = 0; i < 50; i++) 'f$i'];
    final joined = [
      for (final id in ids) community(id),
      community('extra'),
    ];
    final fav = await pump(tester, joined: joined, favorites: ids);
    await tester.dragUntilVisible(
        find.byKey(const ValueKey('fav-extra')),
        find.byKey(const ValueKey('communities-joined-list')),
        const Offset(0, -600));
    await tester.tap(find.byKey(const ValueKey('fav-extra')));
    await tester.pump();
    expect(fav.writes, isEmpty);
    expect(
        find.text('You can pin up to 50 favorites. Unstar one to add another.'),
        findsOneWidget);
  });

  testWidgets('leaving a community removes its favorite', (tester) async {
    final events = StreamController<CommunitiesState>.broadcast();
    addTearDown(events.close);
    final fav = await pump(tester,
        joined: [community('a'), community('b')],
        favorites: ['a'],
        stream: events.stream);
    expect(cardOrder(tester).first, 'a');
    events.add(const CommunityLeft(communityId: 'a'));
    await tester.pump();
    await tester.pump();
    expect(fav.writes, [('a', false)]);
    expect(find.text('FAVORITES'), findsNothing);
  });
}
