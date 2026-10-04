import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/attractions/data/services/attraction_ratings_store.dart';
import 'package:greengo_chat/features/attractions/domain/attraction_rating.dart';

void main() {
  group('AttractionRatingDisplay.of (card rating rule)', () {
    test('GreenGo rating wins when anyone rated', () {
      final d = AttractionRatingDisplay.of(
          const AttractionRatingSummary(sum: 14, count: 3), 4.1)!;
      expect(d.isGreenGo, isTrue);
      expect(d.count, 3);
      expect(d.valueLabel, '4.7');
    });

    test('falls back to Google when nobody rated', () {
      for (final s in [null, AttractionRatingSummary.empty,
          const AttractionRatingSummary(sum: -3, count: -1)]) {
        final d = AttractionRatingDisplay.of(s, 4.5)!;
        expect(d.isGreenGo, isFalse);
        expect(d.count, isNull);
        expect(d.valueLabel, '4.5');
      }
    });

    test('nothing when neither exists', () {
      expect(AttractionRatingDisplay.of(null, null), isNull);
      expect(AttractionRatingDisplay.of(AttractionRatingSummary.empty, 0), isNull);
    });
  });

  group('AttractionRatingSummary', () {
    test('fromStats reads the server aggregate', () {
      final s = AttractionRatingSummary.fromStats(
          {'viewCount': 9, 'ratingSum': 9, 'ratingCount': 2, 'ratingAvg': 4.5});
      expect(s, const AttractionRatingSummary(sum: 9, count: 2));
      expect(s.average, 4.5);
      expect(AttractionRatingSummary.fromStats(null).hasRatings, isFalse);
      expect(AttractionRatingSummary.fromStats({'viewCount': 3}).hasRatings, isFalse);
    });

    test('inconsistent totals are not shown', () {
      expect(const AttractionRatingSummary(sum: 11, count: 2).hasRatings, isFalse);
      expect(const AttractionRatingSummary(sum: 1, count: 2).hasRatings, isFalse);
    });

    test('withUserChange: first rating, change, removal', () {
      const base = AttractionRatingSummary(sum: 8, count: 2);
      expect(base.withUserChange(null, 5), const AttractionRatingSummary(sum: 13, count: 3));
      expect(base.withUserChange(3, 5), const AttractionRatingSummary(sum: 10, count: 2));
      expect(base.withUserChange(3, null), const AttractionRatingSummary(sum: 5, count: 1));
    });

    test('json round-trip', () {
      const s = AttractionRatingSummary(sum: 7, count: 2);
      expect(AttractionRatingSummary.fromJson(s.toJson()), s);
      expect(AttractionRatingSummary.fromJson('bad'), isNull);
    });
  });

  group('AttractionRatingsStore batching', () {
    late List<List<int>> calls;
    late Object? saved;

    AttractionRatingsStore make({
      Map<int, AttractionRatingSummary> server = const {},
      Object? persisted,
      Future<void>? gate,
      bool fail = false,
    }) {
      calls = [];
      saved = null;
      return AttractionRatingsStore(
        persistDelay: Duration.zero,
        fetchChunk: (ids) async {
          calls.add(ids);
          if (gate != null) await gate;
          if (fail) throw StateError('offline');
          return {for (final id in ids) if (server[id] != null) id: server[id]!};
        },
        loadPersisted: () async => persisted,
        savePersisted: (v) async => saved = v,
      );
    }

    test('chunk splits by 30', () {
      final parts = AttractionRatingsStore.chunk(List.generate(65, (i) => i), 30);
      expect(parts.map((p) => p.length), [30, 30, 5]);
    });

    test('reads only the displayed ids, in chunks of <= 30, in parallel', () async {
      final gate = Completer<void>();
      final store = make(gate: gate.future);
      final f = store.ensure(List.generate(70, (i) => i + 1));
      await Future<void>.delayed(Duration.zero);
      // All three chunks were started before any finished (parallel).
      expect(calls.map((c) => c.length), [30, 30, 10]);
      gate.complete();
      await f;
      expect(calls.expand((c) => c).toSet().length, 70);
    });

    test('memoised per session: a second ensure reads nothing', () async {
      final store = make(server: {1: const AttractionRatingSummary(sum: 5, count: 1)});
      await store.ensure([1, 2, 3]);
      await store.ensure([3, 2, 1]);
      expect(calls.length, 1);
      expect(store.peek(1)!.average, 5);
      expect(store.peek(2), AttractionRatingSummary.empty); // fetched, none
      // Only the new id is read.
      await store.ensure([1, 4]);
      expect(calls.last, [4]);
    });

    test('concurrent ensure calls share the in-flight read', () async {
      final gate = Completer<void>();
      final store = make(gate: gate.future);
      final a = store.ensure([1, 2]);
      final b = store.ensure([2, 1]);
      await Future<void>.delayed(Duration.zero);
      gate.complete();
      await Future.wait([a, b]);
      expect(calls.length, 1);
    });

    test('notifies once when values change (cards repaint)', () async {
      final store = make(server: {7: const AttractionRatingSummary(sum: 8, count: 2)});
      var n = 0;
      store.addListener(() => n++);
      await store.ensure([7, 8]);
      expect(n, 1);
    });

    test('persisted values paint before the server read and are persisted after',
        () async {
      final server = Completer<void>();
      final store = make(
        persisted: {'9': [12, 3]},
        server: {9: const AttractionRatingSummary(sum: 16, count: 4)},
        gate: server.future,
      );
      final f = store.ensure([9]);
      await Future<void>.delayed(Duration.zero);
      expect(store.peek(9), const AttractionRatingSummary(sum: 12, count: 3));
      server.complete();
      await f;
      expect(store.peek(9), const AttractionRatingSummary(sum: 16, count: 4));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(saved, {'9': [16, 4]});
    });

    test('a failed chunk is not retried immediately (no read storm)', () async {
      final store = make(fail: true);
      await store.ensure([1]);
      await store.ensure([1]);
      expect(calls.length, 1);
      expect(store.isFresh(1), isFalse);
    });

    test('put() records a first-hand value and notifies', () async {
      final store = make();
      var n = 0;
      store.addListener(() => n++);
      store.put(5, const AttractionRatingSummary(sum: 4, count: 1));
      expect(n, 1);
      await store.ensure([5]);
      expect(calls, isEmpty); // already fresh
    });
  });
}
