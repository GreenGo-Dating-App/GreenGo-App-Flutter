import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/core/error/failures.dart';
import 'package:greengo_chat/features/globe_explore/domain/entities/globe_user.dart';
import 'package:greengo_chat/features/globe_explore/domain/repositories/globe_repository.dart';
import 'package:greengo_chat/features/globe_explore/domain/usecases/get_globe_data.dart';
import 'package:greengo_chat/features/globe_explore/presentation/bloc/globe_bloc.dart';
import 'package:greengo_chat/features/globe_explore/presentation/bloc/globe_event.dart';
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
  matchId: 'm1',
);

class _Repo implements GlobeRepository {
  @override
  Future<GlobeUser?> getCurrentUserPin({required String userId}) async => _me;

  @override
  Future<Either<Failure, GlobeData>> getGlobeData(
          {required String userId}) async =>
      const Right(GlobeData(
          currentUser: _me, matchedUsers: [_ana], discoveryUsers: []));

  @override
  Stream<List<GlobeUser>> watchMatchUpdates({required String userId}) =>
      const Stream.empty();

  @override
  Stream<Map<String, bool>> watchOnlineStatus(
          {required List<String> userIds}) =>
      const Stream.empty();
}

void main() {
  late GlobeBloc bloc;
  setUp(() {
    final repo = _Repo();
    bloc = GlobeBloc(getGlobeData: GetGlobeData(repo), repository: repo);
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
}
