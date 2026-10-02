import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/events/domain/entities/external_event.dart';
import 'package:greengo_chat/features/explore/domain/top_experiences.dart';
import 'package:greengo_chat/features/user_experiences/domain/entities/user_experience.dart';

final DateTime _now = DateTime(2026, 10, 1, 12);

UserExperience _exp(
  String id, {
  double avg = 0,
  int count = 0,
  bool featured = false,
  DateTime? until,
  ExperienceStatus status = ExperienceStatus.published,
  double? lat,
  double? lng,
}) =>
    UserExperience(
      id: id,
      hostId: 'h_$id',
      title: 'Experience $id',
      description: 'd' * 40,
      category: ExperienceCategory.other,
      mainPhotoUrl: 'https://a/$id.jpg',
      included: const ['x'],
      locationName: 'Somewhere',
      durationMinutes: 60,
      languages: const ['English'],
      maxGroupSize: 4,
      status: status,
      ratingCount: count,
      ratingAvg: avg,
      ratingSum: (avg * count).round(),
      isFeatured: featured,
      featuredUntil: until,
      lat: lat,
      lng: lng,
    );

ExternalEvent _partner(String id, {String? image = 'https://img/p.jpg'}) =>
    ExternalEvent(
      id: id,
      source: 'viator',
      title: 'Partner $id',
      bookingUrl: 'https://viator/$id',
      imageUrl: image,
    );

List<String> _keys(List<TopExperienceItem> items) =>
    [for (final i in items) i.key];

void main() {
  group('weightedRating', () {
    test('Bayesian: (C*m + R*v) / (C + v) with m=3.5, C=5', () {
      expect(weightedRating(_exp('a', avg: 5, count: 1)), closeTo(3.75, 1e-9));
      expect(weightedRating(_exp('b', avg: 4.5, count: 40)),
          closeTo((5 * 3.5 + 4.5 * 40) / 45, 1e-9));
      expect(weightedRating(_exp('c')), kRatingPriorMean);
    });

    test('one 5-star review does not beat forty good ones', () {
      final one = _exp('one', avg: 5, count: 1);
      final many = _exp('many', avg: 4.5, count: 40);
      final r = buildTopExperiences(const [], [one, many], const [], now: _now);
      expect(_keys(r), ['u:many', 'u:one']);
    });
  });

  group('buildTopExperiences', () {
    test('order: featured, then community by weighted rating, then partner',
        () {
      final f = _exp('f', featured: true, until: _now.add(const Duration(days: 3)));
      final c1 = _exp('c1', avg: 4.8, count: 30);
      final c2 = _exp('c2', avg: 4.0, count: 10);
      final r = buildTopExperiences(
          [f], [c2, c1], [_partner('p1'), _partner('p2')],
          now: _now);
      expect(_keys(r), ['u:f', 'u:c1', 'u:c2', 'x:p1', 'x:p2']);
      expect(r.first.featured, isTrue);
      expect(r[1].featured, isFalse);
      expect(r.last.partner, isNotNull);
    });

    test('de-duplicates across featured / community and partner lists', () {
      final f = _exp('f', featured: true, until: _now.add(const Duration(days: 1)));
      final r = buildTopExperiences(
        [f, f],
        [f, _exp('c'), _exp('c')],
        [_partner('p'), _partner('p')],
        now: _now,
      );
      expect(_keys(r), ['u:f', 'u:c', 'x:p']);
    });

    test('caps at the limit (default 20) and fills with partner', () {
      final community = [for (var i = 0; i < 15; i++) _exp('c$i')];
      final partner = [for (var i = 0; i < 10; i++) _partner('p$i')];
      final r = buildTopExperiences(const [], community, partner, now: _now);
      expect(r.length, kTopExperiencesLimit);
      expect(r.where((i) => i.community != null).length, 15);
      expect(_keys(r).sublist(15), ['x:p0', 'x:p1', 'x:p2', 'x:p3', 'x:p4']);
      expect(
          buildTopExperiences(const [], community, partner,
                  limit: 3, now: _now)
              .length,
          3);
      expect(
          buildTopExperiences(const [], community, partner,
              limit: 0, now: _now),
          isEmpty);
    });

    test('featured expiry: a passed featuredUntil ranks as normal community',
        () {
      final expired = _exp('old',
          avg: 3, count: 2, featured: true,
          until: _now.subtract(const Duration(minutes: 1)));
      final noUntil = _exp('nountil', featured: true);
      final live = _exp('live',
          featured: true, until: _now.add(const Duration(hours: 1)));
      final best = _exp('best', avg: 5, count: 50);
      final r = buildTopExperiences(
          [expired, live, noUntil], [best], const [],
          now: _now);
      expect(r.first.key, 'u:live');
      expect(r.first.featured, isTrue);
      expect(r.where((i) => i.featured).length, 1);
      expect(_keys(r), containsAll(['u:old', 'u:nountil', 'u:best']));
      expect(r[1].key, 'u:best');
    });

    test('a featured item found only in the community list is promoted', () {
      final f = _exp('f', featured: true, until: _now.add(const Duration(days: 2)));
      final r = buildTopExperiences(
          const [], [_exp('c', avg: 5, count: 99), f], const [],
          now: _now);
      expect(_keys(r), ['u:f', 'u:c']);
      expect(r.first.featured, isTrue);
    });

    test('featured without location: latest featuredUntil first', () {
      final soon = _exp('soon', avg: 5, count: 100,
          featured: true, until: _now.add(const Duration(days: 1)));
      final later = _exp('later',
          featured: true, until: _now.add(const Duration(days: 9)));
      final r = buildTopExperiences([soon, later], const [], const [], now: _now);
      expect(_keys(r), ['u:later', 'u:soon']);
    });

    test('with location: featured nearest first, community near tier first',
        () {
      final dist = <String, double?>{
        'fFar': 30,
        'fNear': 2,
        'cNear': 10,
        'cFar': 400,
        'cNoLoc': null,
      };
      final fFar = _exp('fFar',
          featured: true, until: _now.add(const Duration(days: 9)));
      final fNear = _exp('fNear',
          featured: true, until: _now.add(const Duration(days: 1)));
      final cNear = _exp('cNear', avg: 4, count: 5);
      final cFar = _exp('cFar', avg: 5, count: 200);
      final cNoLoc = _exp('cNoLoc', avg: 5, count: 300);
      final r = buildTopExperiences(
        [fFar, fNear],
        [cFar, cNoLoc, cNear],
        [_partner('p')],
        now: _now,
        distanceKm: (e) => dist[e.id],
      );
      expect(_keys(r), ['u:fNear', 'u:fFar', 'u:cNear', 'u:cNoLoc', 'u:cFar', 'x:p']);
    });

    test('skips unpublished member and image-less partner experiences', () {
      final r = buildTopExperiences(
        [
          _exp('hidden',
              status: ExperienceStatus.hidden,
              featured: true,
              until: _now.add(const Duration(days: 1)))
        ],
        [_exp('draft', status: ExperienceStatus.draft), _exp('ok')],
        [_partner('noimg', image: null), _partner('blank', image: ' '), _partner('p')],
        now: _now,
      );
      expect(_keys(r), ['u:ok', 'x:p']);
    });

    test('empty inputs give an empty list (the section hides)', () {
      expect(buildTopExperiences(const [], const [], const [], now: _now),
          isEmpty);
    });
  });
}
