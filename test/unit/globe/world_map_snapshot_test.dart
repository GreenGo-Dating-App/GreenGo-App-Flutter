import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/globe_explore/data/datasources/globe_remote_datasource.dart';
import 'package:greengo_chat/features/globe_explore/data/network_pin_assembler.dart';
import 'package:greengo_chat/features/globe_explore/data/world_map_snapshot.dart';
import 'package:greengo_chat/features/globe_explore/domain/entities/globe_user.dart';
import 'package:greengo_chat/features/profile/data/private_profile.dart';

/// World map snapshots (owner decision 2026-10-20): the server builds the
/// network pins hourly; the app reads one doc. The privacy rules are shared
/// with the server through ONE fixture both test suites read
/// (functions/__tests__/fixtures/world_map_pin_cases.json; the server side is
/// functions/__tests__/unit/worldMapSnapshot.test.ts).

final Map<String, dynamic> _fixture = jsonDecode(
        File('functions/__tests__/fixtures/world_map_pin_cases.json')
            .readAsStringSync())
    as Map<String, dynamic>;

/// `{"_ts": ms}` -> Timestamp, recursively.
Object? _withTimestamps(Object? v) {
  if (v is Map) {
    if (v.length == 1 && v['_ts'] is int) {
      return Timestamp.fromMillisecondsSinceEpoch(v['_ts'] as int);
    }
    return <String, dynamic>{
      for (final e in v.entries) e.key as String: _withTimestamps(e.value),
    };
  }
  if (v is List) return [for (final x in v) _withTimestamps(x)];
  return v;
}

const _badgeOf = {
  GlobeRelation.following: 'following',
  GlobeRelation.follower: 'follower',
  GlobeRelation.chatted: 'chat',
};
const _badgeOrder = ['following', 'follower', 'chat'];

List<String> _badges(GlobeUser u) =>
    [for (final b in _badgeOrder) if (u.relations.map((r) => _badgeOf[r]).contains(b)) b];

List<GlobeUser> _assembleFixture(int seed) {
  final profiles = (_withTimestamps(_fixture['profiles'])! as Map<String, dynamic>)
      .map((k, v) => MapEntry(k, v as Map<String, dynamic>));
  return assembleNetworkPins(
    userId: _fixture['userId'] as String,
    following: [
      for (final e in _fixture['following'] as List)
        (id: e['id'] as String, isStore: e['isStore'] == true),
    ],
    followers: List<String>.from(_fixture['followers'] as List),
    chats: List<String>.from(_fixture['chats'] as List),
    profiles: profiles,
    blocked: Set<String>.from(_fixture['blocked'] as List),
    random: Random(seed),
  );
}

Map<String, dynamic> _pin(String id,
        {String kind = 'person',
        List<String> badges = const ['following'],
        double lat = 42.0,
        double lng = 12.0}) =>
    {
      'id': id,
      'kind': kind,
      'lat': lat,
      'lng': lng,
      'name': id,
      'photo': null,
      'badges': badges,
      'country': 'Italy',
      'city': 'Rome',
      'disc': 'approximate',
      'isOnlineAtBuild': false,
    };

void main() {
  group('shared fixture parity (client assembler)', () {
    for (var seed = 1; seed <= 25; seed++) {
      test('seed $seed: every expected pin, nothing else', () {
        final pins = _assembleFixture(seed);
        final byId = {for (final p in pins) p.userId: p};
        final expected = _fixture['expected'] as Map<String, dynamic>;
        expect(byId.keys.toSet(), expected.keys.toSet());
        for (final id in _fixture['excluded'] as List) {
          expect(byId.containsKey(id), isFalse, reason: '$id must be left out');
        }
        expected.forEach((id, raw) {
          final e = raw as Map<String, dynamic>;
          final p = byId[id]!;
          final tol = (e['tol'] as num).toDouble() + 1e-6;
          expect(p.isBusiness ? 'business' : 'person', e['kind'], reason: id);
          expect(_badges(p), e['badges'], reason: id);
          expect((p.pinLatitude - (e['lat'] as num)).abs(),
              lessThanOrEqualTo(tol), reason: '$id lat');
          expect((p.pinLongitude - (e['lng'] as num)).abs(),
              lessThanOrEqualTo(tol), reason: '$id lng');
          expect(p.displayName, e['name'], reason: id);
          expect(p.photoUrl, e['photo'], reason: id);
          expect(p.country, e['country'], reason: id);
          expect(p.city, e['city'], reason: id);
          expect(p.isOnline, e['isOnline'], reason: id);
          if (e['kind'] == 'person') {
            expect(p.discoverability.name, e['disc'], reason: id);
          }
          final t = e['traveler'] as Map<String, dynamic>?;
          expect(p.isTravelerActive, t != null, reason: id);
          if (t != null) {
            expect(p.travelerCountry, t['country'], reason: id);
            expect(p.realCountryLatitude, (t['homeLat'] as num).toDouble());
            expect(p.realCountryLongitude, (t['homeLng'] as num).toDouble());
          }
        });
      });
    }

    test('chatPartnerOf cases', () {
      for (final c in _fixture['chatPartnerCases'] as List) {
        expect(
            chatPartnerOf(
                Map<String, dynamic>.from(c['conv'] as Map), 'me'),
            c['expected'],
            reason: c['name'] as String);
      }
    });
  });

  group('snapshot pin parsing', () {
    test('shared parse cases', () {
      for (final c in _fixture['parseCases'] as List) {
        final e = c['expected'] as Map<String, dynamic>;
        final u = parseWorldMapPin(c['pin']);
        if (e['ok'] != true) {
          expect(u, isNull, reason: '${c['pin']}');
          continue;
        }
        expect(u, isNotNull, reason: '${c['pin']}');
        expect(u!.isBusiness, e['isBusiness']);
        expect(u.pinType,
            u.isBusiness ? GlobePinType.business : GlobePinType.matched);
        expect(_badges(u), e['relations']);
        expect(u.isOnline, e['online']);
        final t = e['traveler'] as Map<String, dynamic>?;
        expect(u.isTravelerActive, t != null);
        if (t != null) {
          expect(u.travelerCountry, t['country']);
          expect(u.realCountryLatitude, t['homeLat']);
          expect(u.realCountryLongitude, t['homeLng']);
        }
      }
    });

    test('one pin per account; junk entries dropped', () {
      final users = parseWorldMapPins([
        _pin('a'),
        _pin('a', badges: ['chat']),
        'junk',
        null,
        _pin('b', kind: 'business'),
      ]);
      expect(users.map((u) => u.userId), ['a', 'b']);
      expect(parseWorldMapPins(null), isEmpty);
    });

    test('chips filter the snapshot pins by their badges (client side)', () {
      final me = parseWorldMapPin(_pin('me'))!
          .copyWith(pinType: GlobePinType.currentUser);
      final data = GlobeData(
        currentUser: me,
        matchedUsers: parseWorldMapPins([
          _pin('fo', badges: ['following']),
          _pin('fr', badges: ['follower']),
          _pin('ch', badges: ['chat']),
          _pin('both', badges: ['following', 'chat']),
          _pin('biz', kind: 'business', badges: ['following']),
        ]),
        discoveryUsers: const [],
      );
      Set<String> ids(Set<GlobeNetworkFilter> f) =>
          data.filteredBy(f).matchedUsers.map((u) => u.userId).toSet();
      expect(ids(kAllGlobeFilters), {'fo', 'fr', 'ch', 'both', 'biz'});
      expect(ids({GlobeNetworkFilter.following}), {'fo', 'both'});
      expect(ids({GlobeNetworkFilter.followers}), {'fr'});
      expect(ids({GlobeNetworkFilter.chats}), {'ch', 'both'});
      expect(ids({GlobeNetworkFilter.businesses}), {'biz'});
      expect(ids({}), isEmpty);
    });
  });

  group('WorldMapSnapshotSource', () {
    final now = DateTime.utc(2026, 10, 20, 12);
    late FakeFirebaseFirestore fs;
    late List<Map<String, dynamic>> calls;
    Map<String, dynamic> serverResult = {};
    Object? serverError;

    WorldMapSnapshotSource source() => WorldMapSnapshotSource(
          firestore: fs,
          now: () => now,
          call: (payload) async {
            calls.add(payload);
            if (serverError != null) throw serverError!;
            return serverResult;
          },
        );

    Future<void> storeDoc(
      Map<String, dynamic> extra, {
      Duration age = const Duration(minutes: 10),
      DateTime? openedAt,
    }) =>
        fs.collection(kWorldMapSnapshots).doc('me').set({
          'schema': kWorldMapSnapshotSchema,
          'builtAt': Timestamp.fromDate(now.subtract(age)),
          'active': true,
          'lastOpenedAt': Timestamp.fromDate(
              openedAt ?? now.subtract(const Duration(hours: 2))),
          'chunkCount': 0,
          'buildId': 'b1',
          'pins': [_pin('stored')],
          ...extra,
        });

    setUp(() {
      fs = FakeFirebaseFirestore();
      calls = [];
      serverResult = {
        'pins': [_pin('fromServer')],
        'builtAt': now.millisecondsSinceEpoch,
      };
      serverError = null;
    });

    test('fresh stored snapshot: one doc read, no callable', () async {
      await storeDoc({});
      final users = await source().load('me');
      expect(users.map((u) => u.userId), ['stored']);
      expect(calls, isEmpty);
    });

    test('fresh snapshot, marker older than a day: background touch only',
        () async {
      await storeDoc({}, openedAt: now.subtract(const Duration(days: 2)));
      final users = await source().load('me');
      expect(users.map((u) => u.userId), ['stored']);
      await Future<void>.delayed(Duration.zero);
      expect(calls, [
        {'touchOnly': true}
      ]);
    });

    test('older than 6 h or missing: the callable builds it', () async {
      final s = source();
      expect((await s.load('me')).map((u) => u.userId), ['fromServer']);
      await storeDoc({}, age: const Duration(hours: 6, minutes: 1));
      expect((await s.load('me')).map((u) => u.userId), ['fromServer']);
      expect(calls, [{}, {}]);
    });

    test('chunks of the same build are concatenated; a foreign chunk = rebuild',
        () async {
      await storeDoc({'pins': [], 'chunkCount': 2});
      final chunks =
          fs.collection(kWorldMapSnapshots).doc('me').collection('chunks');
      await chunks.doc('0').set({
        'buildId': 'b1',
        'pins': [_pin('c0')]
      });
      await chunks.doc('1').set({
        'buildId': 'b1',
        'pins': [_pin('c1')]
      });
      expect((await source().load('me')).map((u) => u.userId), ['c0', 'c1']);
      expect(calls, isEmpty);

      await chunks.doc('1').set({
        'buildId': 'other',
        'pins': [_pin('c1')]
      });
      expect((await source().load('me')).map((u) => u.userId), ['fromServer']);
    });

    test('callable down: an older stored snapshot is still used', () async {
      await storeDoc({}, age: const Duration(hours: 5));
      serverError = Exception('unavailable');
      expect((await source().load('me')).map((u) => u.userId), ['stored']);
    });

    test('callable down and nothing stored: throws (assembler fallback)',
        () async {
      serverError = Exception('unavailable');
      await expectLater(source().load('me'), throwsException);
    });
  });

  group('GlobeRemoteDataSourceImpl with a snapshot source', () {
    tearDown(() => PrivateProfileCache.instance.reset());

    Future<FakeFirebaseFirestore> seeded() async {
      final fs = FakeFirebaseFirestore();
      PrivateProfileCache.instance.reset();
      PrivateProfileCache.instance.seed('me', {
        'location': {'latitude': 38.72, 'longitude': -9.14},
      });
      await fs.collection('profiles').doc('me').set({
        'displayName': 'Me',
        'accountStatus': 'active',
        'location': {'city': 'Lisbon', 'country': 'Portugal'},
      });
      await fs.collection('profiles').doc('fo').set({
        'displayName': 'fo',
        'accountStatus': 'active',
        'location': {
          'latitude': 41.9,
          'longitude': 12.5,
          'city': 'Rome',
          'country': 'Italy'
        },
        kApproxLocationField: {'lat': 41.9, 'lng': 12.5},
      });
      await fs
          .collection('user_business_following')
          .doc('me')
          .collection('businesses')
          .doc('fo')
          .set({'createdAt': Timestamp.now()});
      return fs;
    }

    test('pins come from the snapshot, not from the device assembly',
        () async {
      final fs = await seeded();
      var called = 0;
      final d = await GlobeRemoteDataSourceImpl(
        firestore: fs,
        snapshotSource: WorldMapSnapshotSource(
          firestore: fs,
          call: (_) async {
            called++;
            return {
              'pins': [_pin('snap')]
            };
          },
        ),
      ).getGlobeData(userId: 'me');
      expect(called, 1);
      expect(d.currentUser.userId, 'me');
      expect(d.matchedUsers.map((u) => u.userId), ['snap']);
    });

    test('snapshot fetch fails: the device assembly is the fallback',
        () async {
      final fs = await seeded();
      final d = await GlobeRemoteDataSourceImpl(
        firestore: fs,
        snapshotSource: WorldMapSnapshotSource(
          firestore: fs,
          call: (_) async => throw Exception('functions down'),
        ),
      ).getGlobeData(userId: 'me');
      expect(d.matchedUsers.map((u) => u.userId), ['fo']);
      expect(d.matchedUsers.single.relations, {GlobeRelation.following});
    });
  });
}
