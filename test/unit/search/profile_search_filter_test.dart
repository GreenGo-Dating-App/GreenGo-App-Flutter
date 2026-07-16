import 'package:flutter_test/flutter_test.dart';

import '../../support/search_fixtures.dart';

/// Master Test Plan — Universal Search / People filtering.
/// Pure tests for the exclusion predicate applied to every candidate profile in
/// `UniversalSearchScreen._searchProfiles` (self / ghost / admin / support /
/// non-active / no-name), plus the People-vs-Business split.
void main() {
  const me = 'me_uid';

  group('passesProfileSearchFilter exclusions', () {
    test('a normal, active, named other user PASSES', () {
      final p = buildProfile(userId: 'other', displayName: 'Ava Reyes');
      expect(passesProfileSearchFilter(p, currentUserId: me), isTrue);
    });

    test('excludes the current user (self)', () {
      final p = buildProfile(userId: me, displayName: 'Myself');
      expect(passesProfileSearchFilter(p, currentUserId: me), isFalse);
    });

    test('excludes ghost-mode profiles', () {
      final p = buildProfile(
          userId: 'g', displayName: 'Ghost', isGhostMode: true);
      expect(passesProfileSearchFilter(p, currentUserId: me), isFalse);
    });

    test('excludes admin accounts', () {
      final p =
          buildProfile(userId: 'a', displayName: 'Admin', isAdmin: true);
      expect(passesProfileSearchFilter(p, currentUserId: me), isFalse);
    });

    test('excludes support accounts', () {
      final p = buildProfile(
          userId: 's', displayName: 'Support', isSupport: true);
      expect(passesProfileSearchFilter(p, currentUserId: me), isFalse);
    });

    test('excludes deleted accounts (accountStatus != active)', () {
      final p = buildProfile(
          userId: 'd', displayName: 'Deleted', accountStatus: 'deleted');
      expect(passesProfileSearchFilter(p, currentUserId: me), isFalse);
    });

    test('excludes suspended / banned accountStatus values', () {
      for (final status in ['suspended', 'banned', 'pending']) {
        final p = buildProfile(
            userId: 'x_$status', displayName: 'X', accountStatus: status);
        expect(passesProfileSearchFilter(p, currentUserId: me), isFalse,
            reason: '$status must be excluded');
      }
    });

    test('excludes profiles with a blank/whitespace displayName', () {
      final blank = buildProfile(userId: 'b1', displayName: '');
      final spaces = buildProfile(userId: 'b2', displayName: '   ');
      expect(passesProfileSearchFilter(blank, currentUserId: me), isFalse);
      expect(passesProfileSearchFilter(spaces, currentUserId: me), isFalse);
    });

    test('an active business account PASSES (still a searchable person)', () {
      final p = buildProfile(
        userId: 'biz',
        displayName: 'Elena Marco',
        isBusiness: true,
        businessName: "Elena's Cafe",
      );
      expect(passesProfileSearchFilter(p, currentUserId: me), isTrue);
    });
  });

  group('People pipeline (filter + de-dupe + sort)', () {
    test('sorts survivors by lowercased displayName', () {
      final people = runPeoplePipeline(
        [
          buildProfile(userId: '1', displayName: 'zoe'),
          buildProfile(userId: '2', displayName: 'Ava'),
          buildProfile(userId: '3', displayName: 'mia'),
        ],
        currentUserId: me,
      );
      expect(people.map((p) => p.displayName), ['Ava', 'mia', 'zoe']);
    });

    test('de-dupes repeated userIds, keeping the first occurrence', () {
      final people = runPeoplePipeline(
        [
          buildProfile(userId: 'dup', displayName: 'First'),
          buildProfile(userId: 'dup', displayName: 'Second'),
        ],
        currentUserId: me,
      );
      expect(people.length, 1);
      expect(people.single.displayName, 'First');
    });

    test('drops every excluded candidate in a mixed batch', () {
      final people = runPeoplePipeline(
        [
          buildProfile(userId: me, displayName: 'Me'),
          buildProfile(userId: 'g', displayName: 'Ghost', isGhostMode: true),
          buildProfile(userId: 'a', displayName: 'Admin', isAdmin: true),
          buildProfile(
              userId: 'd', displayName: 'Del', accountStatus: 'deleted'),
          buildProfile(userId: 'ok', displayName: 'Keeper'),
        ],
        currentUserId: me,
      );
      expect(people.map((p) => p.userId), ['ok']);
    });
  });

  group('People vs Business split', () {
    test('a business owner appears in BOTH People and Business', () {
      final biz = buildProfile(
        userId: 'biz',
        displayName: 'Elena Marco',
        isBusiness: true,
        businessName: "Elena's Cafe",
      );
      final person = buildProfile(userId: 'p', displayName: 'Ava');

      final people = runPeoplePipeline([biz, person], currentUserId: me);
      final business = businessSubset(people);

      expect(people.map((p) => p.userId), containsAll(['biz', 'p']));
      expect(business.map((p) => p.userId), ['biz']);
    });

    test('Business subset is empty when no one is a business', () {
      final people = runPeoplePipeline(
        [
          buildProfile(userId: 'p1', displayName: 'Ava'),
          buildProfile(userId: 'p2', displayName: 'Bruno'),
        ],
        currentUserId: me,
      );
      expect(businessSubset(people), isEmpty);
    });
  });
}
