import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/globe_explore/data/country_centroids.dart';
import 'package:greengo_chat/features/globe_explore/data/datasources/globe_remote_datasource.dart';
import 'package:greengo_chat/features/globe_explore/data/network_pin_assembler.dart';
import 'package:greengo_chat/features/globe_explore/domain/entities/globe_user.dart';
import 'package:greengo_chat/features/profile/data/private_profile.dart';

/// The network ("world") map's data assembly: who is pinned, once, with
/// which badges, where, and within which caps.

Map<String, dynamic> _person({
  String name = 'P',
  String? discoverability,
  String status = 'active',
}) =>
    {
      'displayName': name,
      'accountStatus': status,
      if (discoverability != null) 'globeDiscoverability': discoverability,
      'photoUrls': ['https://x/$name.jpg'],
      'location': {
        'latitude': 41.9,
        'longitude': 12.5,
        'city': 'Rome',
        'country': 'Italy',
      },
      kApproxLocationField: {'lat': 41.9, 'lng': 12.5},
    };

Map<String, dynamic> _business({
  String? logo = 'https://x/logo.png',
  String? cover = 'https://x/cover.png',
  List<String> gallery = const ['https://x/g1.png'],
  bool withAddress = true,
  String? discoverability,
}) =>
    {
      ..._person(name: 'Owner', discoverability: discoverability),
      'isBusiness': true,
      'businessName': 'Cafe Roma',
      if (logo != null) 'businessLogoUrl': logo,
      if (cover != null) 'coverImageUrl': cover,
      'galleryImages': gallery,
      if (withAddress)
        'businessAddress': {
          'address': 'Via Roma 1',
          'latitude': 45.4642,
          'longitude': 9.19,
          'city': 'Milan',
          'country': 'Italy',
        },
    };

List<GlobeUser> _assemble({
  List<GlobeFollowEdge> following = const [],
  List<String> followers = const [],
  List<String> chats = const [],
  required Map<String, Map<String, dynamic>> profiles,
  Set<String> blocked = const {},
}) =>
    assembleNetworkPins(
      userId: 'me',
      following: following,
      followers: followers,
      chats: chats,
      profiles: profiles,
      blocked: blocked,
      random: Random(1),
    );

GlobeUser _pin(List<GlobeUser> pins, String id) =>
    pins.singleWhere((p) => p.userId == id);

void main() {
  group('groups and dedupe', () {
    test('each group is pinned with its relation', () {
      final pins = _assemble(
        following: [(id: 'a', isStore: false)],
        followers: ['b'],
        chats: ['c'],
        profiles: {'a': _person(), 'b': _person(), 'c': _person()},
      );
      expect(_pin(pins, 'a').relations, {GlobeRelation.following});
      expect(_pin(pins, 'b').relations, {GlobeRelation.follower});
      expect(_pin(pins, 'c').relations, {GlobeRelation.chatted});
    });

    test('a person in several groups is ONE pin carrying every badge', () {
      final pins = _assemble(
        following: [(id: 'a', isStore: false)],
        followers: ['a'],
        chats: ['a', 'a'],
        profiles: {'a': _person()},
      );
      expect(pins, hasLength(1));
      expect(pins.single.relations, {
        GlobeRelation.following,
        GlobeRelation.follower,
        GlobeRelation.chatted,
      });
    });

    test('the user, blocked accounts and missing profiles are skipped', () {
      final pins = _assemble(
        following: [(id: 'me', isStore: false), (id: 'blk', isStore: false)],
        followers: ['gone'],
        chats: ['ok'],
        profiles: {'me': _person(), 'blk': _person(), 'ok': _person()},
        blocked: {'blk'},
      );
      expect(pins.map((p) => p.userId), ['ok']);
    });

    test('each group is capped (newest first)', () {
      final ids = [for (var i = 0; i < kGlobeFollowersCap + 50; i++) 'f$i'];
      final pins = _assemble(
        followers: ids,
        profiles: {for (final id in ids) id: _person()},
      );
      expect(pins, hasLength(kGlobeFollowersCap));
      expect(pins.any((p) => p.userId == 'f${kGlobeFollowersCap + 1}'),
          isFalse);
      expect(pins.any((p) => p.userId == 'f0'), isTrue);
    });
  });

  group('privacy of people', () {
    test('"Hidden" and inactive people are not shown', () {
      final pins = _assemble(
        followers: ['h', 's', 'ok'],
        profiles: {
          'h': _person(discoverability: 'hidden'),
          's': _person(status: 'suspended'),
          'ok': _person(),
        },
      );
      expect(pins.map((p) => p.userId), ['ok']);
    });

    test('people keep the discoverability positioning (country centroid)',
        () {
      final pins = _assemble(
        chats: ['c'],
        profiles: {'c': _person(discoverability: 'country')},
      );
      final p = pins.single;
      expect(p.pinType, GlobePinType.matched);
      expect(p.discoverability, GlobeDiscoverability.country);
      final c = countryCentroids['Italy']!;
      expect((p.pinLatitude - c[0]).abs(), lessThanOrEqualTo(1.5));
      expect((p.pinLongitude - c[1]).abs(), lessThanOrEqualTo(1.5));
    });
  });

  group('businesses', () {
    test('pinned at the business address with the business name and logo',
        () {
      final pins = _assemble(
        following: [(id: 'biz', isStore: true)],
        chats: ['biz'],
        profiles: {'biz': _business()},
      );
      final b = pins.single;
      expect(b.isBusiness, isTrue);
      expect(b.pinType, GlobePinType.business);
      expect(b.pinLatitude, 45.4642);
      expect(b.pinLongitude, 9.19);
      expect(b.displayName, 'Cafe Roma');
      expect(b.photoUrl, 'https://x/logo.png');
      expect(b.city, 'Milan');
      expect(b.relations, {GlobeRelation.following, GlobeRelation.chatted});
    });

    test('picture falls back: logo -> cover -> gallery -> photo', () {
      GlobeUser one(Map<String, dynamic> p) =>
          _assemble(chats: ['b'], profiles: {'b': p}).single;
      expect(one(_business(logo: null)).photoUrl, 'https://x/cover.png');
      expect(one(_business(logo: null, cover: null)).photoUrl,
          'https://x/g1.png');
      expect(
          one(_business(logo: null, cover: null, gallery: const []))
              .photoUrl,
          'https://x/Owner.jpg');
    });

    test('the business address is public: shown even if the owner is Hidden',
        () {
      final pins = _assemble(
        chats: ['b'],
        profiles: {'b': _business(discoverability: 'hidden')},
      );
      expect(pins.single.pinLatitude, 45.4642);
    });

    test('isStore mirror flag alone marks a business', () {
      final p = _business()..remove('isBusiness');
      final pins = _assemble(
          following: [(id: 'b', isStore: true)], profiles: {'b': p});
      expect(pins.single.isBusiness, isTrue);
    });

    test('without an address it falls back to the people rules', () {
      final pins = _assemble(
        chats: ['b', 'h'],
        profiles: {
          'b': _business(withAddress: false),
          'h': _business(withAddress: false, discoverability: 'hidden'),
        },
      );
      expect(pins.map((p) => p.userId), ['b']);
      expect(pins.single.isBusiness, isFalse);
    });
  });

  group('filters', () {
    final pins = _assemble(
      following: [(id: 'fo', isStore: false), (id: 'biz', isStore: true)],
      followers: ['fr', 'multi'],
      chats: ['ch', 'multi'],
      profiles: {
        'fo': _person(),
        'fr': _person(),
        'ch': _person(),
        'multi': _person(),
        'biz': _business(),
      },
    );
    Set<String> visible(Set<GlobeNetworkFilter> f) => {
          for (final p in pins)
            if (p.visibleWith(f)) p.userId,
        };

    test('all chips on: everyone', () {
      expect(visible(kAllGlobeFilters), {'fo', 'fr', 'ch', 'multi', 'biz'});
    });

    test('one chip: only its group (a multi-group person stays visible)', () {
      expect(visible({GlobeNetworkFilter.following}), {'fo'});
      expect(visible({GlobeNetworkFilter.followers}), {'fr', 'multi'});
      expect(visible({GlobeNetworkFilter.chats}), {'ch', 'multi'});
      expect(visible({GlobeNetworkFilter.businesses}), {'biz'});
      expect(visible({}), isEmpty);
    });

    test('GlobeData.filteredBy keeps the user and filters the network', () {
      final me = pins.first.copyWith(
          userId: 'me', pinType: GlobePinType.currentUser);
      final d = GlobeData(
              currentUser: me, matchedUsers: pins, discoveryUsers: const [])
          .filteredBy({GlobeNetworkFilter.businesses});
      expect(d.currentUser.userId, 'me');
      expect(d.matchedUsers.map((u) => u.userId), ['biz']);
    });
  });

  group('chatPartnerOf', () {
    Map<String, dynamic> conv([Map<String, dynamic> extra = const {}]) => {
          'userId1': 'me',
          'userId2': 'x',
          'lastMessage': {'content': 'hi'},
          ...extra,
        };

    test('a 1:1 chat with a message counts, from either side', () {
      expect(chatPartnerOf(conv(), 'me'), 'x');
      expect(chatPartnerOf(conv({'userId1': 'x', 'userId2': 'me'}), 'me'),
          'x');
    });

    test('no message, support, group, deleted or not visible: not a chat',
        () {
      expect(chatPartnerOf(conv()..remove('lastMessage'), 'me'), isNull);
      expect(chatPartnerOf(conv({'conversationType': 'support'}), 'me'),
          isNull);
      expect(chatPartnerOf(conv({'conversationType': 'group'}), 'me'), isNull);
      expect(chatPartnerOf(conv({'isDeleted': true}), 'me'), isNull);
      expect(
          chatPartnerOf(
              conv({
                'deletedFor': {'me': true}
              }),
              'me'),
          isNull);
      expect(
          chatPartnerOf(
              conv({
                'visibleTo': ['x']
              }),
              'me'),
          isNull);
    });
  });

  group('GlobeRemoteDataSourceImpl (fake Firestore)', () {
    tearDown(() => PrivateProfileCache.instance.reset());

    test('reads follows, followers, chats and businesses into one map',
        () async {
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
      for (final e in {
        'fo': _person(name: 'fo'),
        'fr': _person(name: 'fr'),
        'ch': _person(name: 'ch'),
        'hid': _person(name: 'hid', discoverability: 'hidden'),
        'biz': _business(),
      }.entries) {
        await fs.collection('profiles').doc(e.key).set(e.value);
      }
      final now = Timestamp.now();
      Future<void> edge(String col, String sub, String owner, String id,
              [Map<String, dynamic> extra = const {}]) =>
          fs
              .collection(col)
              .doc(owner)
              .collection(sub)
              .doc(id)
              .set({'createdAt': now, ...extra});
      await edge('user_business_following', 'businesses', 'me', 'fo');
      await edge('user_business_following', 'businesses', 'me', 'biz',
          {'isStore': true});
      await edge('business_followers', 'followers', 'me', 'fr');
      await edge('business_followers', 'followers', 'me', 'hid');
      await fs.collection('conversations').doc('c1').set({
        'userId1': 'ch',
        'userId2': 'me',
        'lastMessage': {'content': 'hi'},
        'lastMessageAt': now,
      });
      await fs.collection('conversations').doc('c2').set({
        'userId1': 'me',
        'userId2': 'fo',
        'lastMessageAt': now, // no message yet: not a chat
      });

      final d = await GlobeRemoteDataSourceImpl(firestore: fs)
          .getGlobeData(userId: 'me');
      final byId = {for (final u in d.matchedUsers) u.userId: u};
      expect(byId.keys.toSet(), {'fo', 'fr', 'ch', 'biz'});
      expect(byId['fo']!.relations, {GlobeRelation.following});
      expect(byId['fr']!.relations, {GlobeRelation.follower});
      expect(byId['ch']!.relations, {GlobeRelation.chatted});
      expect(byId['biz']!.isBusiness, isTrue);
      expect(byId['biz']!.pinLatitude, 45.4642);
      expect(d.currentUser.userId, 'me');
    });
  });
}
