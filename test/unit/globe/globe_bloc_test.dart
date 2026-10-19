import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/error/failures.dart';
import 'package:greengo_chat/features/globe_explore/domain/entities/globe_user.dart';
import 'package:greengo_chat/features/globe_explore/domain/repositories/globe_repository.dart';
import 'package:greengo_chat/features/globe_explore/domain/usecases/get_globe_data.dart';
import 'package:greengo_chat/features/globe_explore/presentation/bloc/globe_bloc.dart';
import 'package:greengo_chat/features/globe_explore/presentation/bloc/globe_event.dart';
import 'package:greengo_chat/features/globe_explore/presentation/bloc/globe_filter_store.dart';
import 'package:greengo_chat/features/globe_explore/presentation/bloc/globe_state.dart';

const _me = GlobeUser(
  userId: 'me',
  displayName: 'Me',
  pinLatitude: 38.7,
  pinLongitude: -9.1,
  country: 'Portugal',
  city: 'Lisbon',
  pinType: GlobePinType.currentUser,
);
const _ana = GlobeUser(
  userId: 'ana',
  displayName: 'Ana',
  pinLatitude: 41.9,
  pinLongitude: 12.5,
  country: 'Italy',
  city: 'Rome',
  pinType: GlobePinType.matched,
  relations: {GlobeRelation.chatted},
);

class _Repo implements GlobeRepository {
  @override
  Future<GlobeUser?> getCurrentUserPin({required String userId}) async => _me;

  @override
  Future<Either<Failure, GlobeData>> getGlobeData(
          {required String userId}) async =>
      const Right(GlobeData(
          currentUser: _me, matchedUsers: [_ana], discoveryUsers: []));
}

class _MemStore implements GlobeFilterStore {
  Set<GlobeNetworkFilter>? saved;
  @override
  Future<Set<GlobeNetworkFilter>> load() async => saved ?? kAllGlobeFilters;
  @override
  Future<void> save(Set<GlobeNetworkFilter> filters) async => saved = filters;
}

void main() {
  late GlobeBloc bloc;
  late _MemStore store;
  setUp(() {
    final repo = _Repo();
    store = _MemStore();
    bloc = GlobeBloc(
        getGlobeData: GetGlobeData(repo),
        repository: repo,
        filterStore: store);
  });
  tearDown(() => bloc.close());

  Future<List<GlobeState>> run(List<GlobeEvent> events) async {
    final seen = <GlobeState>[];
    final sub = bloc.stream.listen(seen.add);
    bloc.add(const GlobeLoadRequested(userId: 'me'));
    await bloc.stream
        .firstWhere((s) => s is GlobeLoaded && s.data.matchedUsers.isNotEmpty);
    events.forEach(bloc.add);
    await Future<void>.delayed(Duration.zero);
    await sub.cancel();
    return seen;
  }

  test('tapping the same pin twice opens its sheet twice', () async {
    final seen = await run(const [
      GlobePinTapped(tappedUserId: 'ana', pinType: GlobePinType.matched),
      GlobePinTapped(tappedUserId: 'ana', pinType: GlobePinType.matched),
    ]);
    final taps = seen.whereType<GlobePinSelected>().toList();
    expect(taps, hasLength(2));
    expect(taps.every((s) => s.selectedUser.userId == 'ana'), isTrue);
  });

  test('tapping the same country twice opens its sheet twice', () async {
    final seen = await run(const [
      GlobeCountryTapped(countryName: 'Italy', latitude: 41, longitude: 12),
      GlobeCountryTapped(countryName: 'Italy', latitude: 41, longitude: 12),
    ]);
    final taps = seen.whereType<GlobeCountrySelected>().toList();
    expect(taps, hasLength(2));
    expect(taps.first.matchesInCountry.single.userId, 'ana');
  });

  test('searching the same country twice flies twice', () async {
    final seen = await run(const [
      GlobeFlyToCountry(country: 'Italy'),
      GlobeFlyToCountry(country: 'Italy'),
    ]);
    final flights = seen
        .whereType<GlobeLoaded>()
        .where((s) => s.flyToCountry == 'Italy')
        .map((s) => s.flyRequestId)
        .toList();
    expect(flights, hasLength(2));
    expect(flights.toSet(), hasLength(2));
  });

  test('a filter chip hides / shows its pins and is remembered', () async {
    final seen = await run(const [
      GlobeFilterToggled(GlobeNetworkFilter.chats),
    ]);
    final off = seen.whereType<GlobeLoaded>().last;
    expect(off.filters.contains(GlobeNetworkFilter.chats), isFalse);
    expect(off.data.matchedUsers, isEmpty);
    expect(store.saved, isNot(contains(GlobeNetworkFilter.chats)));

    bloc.add(const GlobeFilterToggled(GlobeNetworkFilter.chats));
    final on = await bloc.stream.firstWhere((s) => s is GlobeLoaded) as GlobeLoaded;
    expect(on.data.matchedUsers.single.userId, 'ana');
    expect(store.saved, containsAll(kAllGlobeFilters));
  });

  test('the remembered filters apply on load', () async {
    store.saved = {GlobeNetworkFilter.businesses};
    bloc.add(const GlobeLoadRequested(userId: 'me'));
    final loaded = await bloc.stream.firstWhere(
            (s) => s is GlobeLoaded && s.data.currentUser.userId == 'me' &&
                s.filters.length == 1)
        as GlobeLoaded;
    expect(loaded.filters, {GlobeNetworkFilter.businesses});
    // Ana is only a chat: hidden while the Chats chip is off.
    await Future<void>.delayed(Duration.zero);
    final last = bloc.state as GlobeLoaded;
    expect(last.data.matchedUsers, isEmpty);
  });
}
