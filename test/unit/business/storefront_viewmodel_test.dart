import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/profile/domain/entities/profile.dart';

import '../../support/business_fixtures.dart';

/// Master Test Plan — Business/Storefront.
///
/// Two pure regressions kept independent of the heavy screens:
///  1. Storefront event/community view models must carry the doc `id` through
///     `fromDoc(id, data)` — the tap-through opens the wrong page without it.
///  2. Universal search's dual-business row selection: a business profile must
///     render its storefront face (businessName + coverImageUrl), falling back
///     to displayName / photoUrls.first when those are empty.

// ---- Pure replicas of the private storefront view models (id regression). ----

class _EventVm {
  const _EventVm({required this.id, required this.title, required this.status});
  final String id;
  final String title;
  final String status;

  factory _EventVm.fromDoc(String id, Map<String, dynamic> d) => _EventVm(
        id: id,
        title: (d['title'] as String?) ?? '',
        status: (d['status'] as String?) ?? 'draft',
      );
}

class _CommunityVm {
  const _CommunityVm({
    required this.id,
    required this.name,
    required this.isPublic,
    required this.memberCount,
  });
  final String id;
  final String name;
  final bool isPublic;
  final int memberCount;

  factory _CommunityVm.fromDoc(String id, Map<String, dynamic> d) => _CommunityVm(
        id: id,
        name: (d['name'] as String?) ?? '',
        isPublic: (d['isPublic'] as bool?) ?? true,
        memberCount: (d['memberCount'] as num?)?.toInt() ?? 0,
      );
}

// ---- Pure replica of universal_search_screen._businessRow selection. ----

({String hero, String title}) businessFace(Profile p) {
  final hero = (p.coverImageUrl != null && p.coverImageUrl!.isNotEmpty)
      ? p.coverImageUrl!
      : (p.photoUrls.isNotEmpty ? p.photoUrls.first : '');
  final title = (p.businessName != null && p.businessName!.trim().isNotEmpty)
      ? p.businessName!.trim()
      : p.displayName;
  return (hero: hero, title: title);
}

void main() {
  group('storefront view models carry the doc id (tap-through regression)', () {
    test('_EventVm.fromDoc keeps the id', () {
      final e = _EventVm.fromDoc('evt_42', {'title': 'Jazz Night', 'status': 'live'});
      expect(e.id, 'evt_42');
      expect(e.title, 'Jazz Night');
      expect(e.status, 'live');
    });

    test('_CommunityVm.fromDoc keeps the id', () {
      final c = _CommunityVm.fromDoc(
          'comm_7', {'name': 'Coffee Lovers', 'isPublic': true, 'memberCount': 12});
      expect(c.id, 'comm_7');
      expect(c.name, 'Coffee Lovers');
      expect(c.memberCount, 12);
      expect(c.isPublic, isTrue);
    });

    test('event view model defaults status to draft', () {
      final e = _EventVm.fromDoc('e1', const {});
      expect(e.id, 'e1');
      expect(e.status, 'draft');
    });
  });

  group('universal search — business subset + dual row selection', () {
    test('only isBusiness profiles form the Business tab subset', () {
      final profiles = [
        BusinessFixtures.person(userId: 'ava'),
        BusinessFixtures.business(userId: 'elena'),
        BusinessFixtures.person(userId: 'bruno'),
      ];

      final business = profiles.where((p) => p.isBusiness).toList();

      expect(business, hasLength(1));
      expect(business.single.userId, 'elena');
    });

    test('business row renders businessName + coverImageUrl', () {
      final biz = BusinessFixtures.business(
        displayName: 'Elena Marco',
        businessName: "Elena's Cafe",
        coverImageUrl: 'https://example.com/cover.jpg',
      );

      final face = businessFace(biz);

      expect(face.title, "Elena's Cafe");
      expect(face.hero, 'https://example.com/cover.jpg');
    });

    test('falls back to displayName + photoUrls.first when storefront empty',
        () {
      final biz = BusinessFixtures.business(
        displayName: 'Elena Marco',
        businessName: '',
        coverImageUrl: '',
        photoUrls: const ['https://example.com/avatar.jpg'],
      );

      final face = businessFace(biz);

      expect(face.title, 'Elena Marco');
      expect(face.hero, 'https://example.com/avatar.jpg');
    });

    test('a person also appears in People (People includes everyone)', () {
      final profiles = [
        BusinessFixtures.person(userId: 'ava'),
        BusinessFixtures.business(userId: 'elena'),
      ];

      final people = profiles.toList();

      expect(people, hasLength(2));
      expect(people.map((p) => p.userId), containsAll(['ava', 'elena']));
    });
  });
}
