import 'package:flutter_test/flutter_test.dart';
import 'package:greengo_chat/features/events/domain/feed_interleave.dart';

int _num(int a, int b) => a.compareTo(b);

void main() {
  group('InterleavedFeed (ordered)', () {
    test('merges two sorted sources in order once both heads are known', () {
      final f = InterleavedFeed<int>(compare: _num);
      expect(f.addA([1, 4, 7], hasMore: false), isEmpty,
          reason: 'B unknown yet: nothing can be emitted');
      expect(f.needsB, isTrue);
      f.addB([2, 3, 9], hasMore: false);
      expect(f.items, [1, 2, 3, 4, 7, 9]);
      expect(f.isComplete, isTrue);
    });

    test('waits for the side that still has pages; never reorders output', () {
      final f = InterleavedFeed<int>(compare: _num);
      f.addA([1, 5, 10], hasMore: false);
      f.addB([2, 3], hasMore: true);
      // 1,2,3 emitted; 5 must wait — B's next page could hold a 4.
      expect(f.items, [1, 2, 3]);
      expect(f.needsB, isTrue);
      final before = List.of(f.items);
      final appended = f.addB([4, 6], hasMore: true);
      expect(appended, [4, 5, 6]);
      expect(f.items.take(before.length), before, reason: 'append-only');
      f.addB([12], hasMore: false);
      expect(f.items, [1, 2, 3, 4, 5, 6, 10, 12]);
      expect(f.isComplete, isTrue);
    });

    test('exhausted side never blocks the other', () {
      final f = InterleavedFeed<int>(compare: _num);
      f.addA(const [], hasMore: false);
      expect(f.addB([3, 1, 2], hasMore: true), [1, 2, 3]);
      expect(f.needsB, isTrue);
      expect(f.needsA, isFalse);
    });

    test('ties go to source A and keep arrival order (stable)', () {
      final f = InterleavedFeed<(int, String)>(
          compare: (a, b) => a.$1.compareTo(b.$1));
      f.addA([(1, 'a1'), (1, 'a2')], hasMore: false);
      f.addB([(1, 'b1'), (0, 'b0')], hasMore: false);
      expect(f.items.map((e) => e.$2), ['b0', 'a1', 'a2', 'b1']);
    });

    test('an out-of-order page is sorted within the pending buffer only', () {
      final f = InterleavedFeed<int>(compare: _num);
      f.addA([5, 1], hasMore: true);
      f.addB([2], hasMore: true);
      expect(f.items, [1, 2]);
      // A late, smaller item can't be placed before what's shown: appended.
      f.addB([0, 6], hasMore: false);
      expect(f.items, [1, 2, 0, 5]);
      f.addA(const [], hasMore: false);
      expect(f.items, [1, 2, 0, 5, 6]);
      expect(f.isComplete, isTrue);
    });

    test('finishA (failed source) releases the other side', () {
      final f = InterleavedFeed<int>(compare: _num);
      f.addB([1, 2], hasMore: false);
      expect(f.items, isEmpty);
      f.finishA();
      expect(f.items, [1, 2]);
    });
  });

  group('InterleavedFeed (round-robin)', () {
    test('alternates A, B, A, B and lets a finished side yield', () {
      final f = InterleavedFeed<String>();
      f.addA(['a1', 'a2', 'a3'], hasMore: false);
      expect(f.items, ['a1'], reason: "B's turn: wait for its page");
      f.addB(['b1'], hasMore: true);
      expect(f.items, ['a1', 'b1', 'a2']);
      f.addB(['b2'], hasMore: false);
      expect(f.items, ['a1', 'b1', 'a2', 'b2', 'a3']);
      expect(f.isComplete, isTrue);
    });

    test('A exhausted early: B fills the rest', () {
      final f = InterleavedFeed<String>();
      f.addA(['a1'], hasMore: false);
      f.addB(['b1', 'b2', 'b3'], hasMore: false);
      expect(f.items, ['a1', 'b1', 'b2', 'b3']);
    });
  });

  group('sort keys', () {
    final d = DateTime(2026, 10, 2, 18);
    test('soonest first, same day nearest first', () {
      final keys = [
        FeedSortKey(date: d.add(const Duration(days: 1)), distanceKm: 1),
        FeedSortKey(date: DateTime(2026, 10, 2), distanceKm: 30),
        FeedSortKey(date: d, distanceKm: 2),
        const FeedSortKey(distanceKm: 0),
      ]..sort(compareSoonestThenNearest);
      expect(keys.map((k) => k.distanceKm), [2, 30, 1, 0]);
    });

    test('nearest first, unknown distance last, ties soonest', () {
      final keys = [
        FeedSortKey(date: d),
        FeedSortKey(date: d.add(const Duration(days: 3)), distanceKm: 5),
        FeedSortKey(date: d, distanceKm: 5),
        FeedSortKey(date: d, distanceKm: 1),
      ]..sort(compareNearestThenSoonest);
      expect(keys.map((k) => k.distanceKm), [1, 5, 5, null]);
      expect(keys[1].date, d);
    });

    test('parseFeedDate handles date-only, datetime and junk', () {
      expect(parseFeedDate('2026-07-15'), DateTime(2026, 7, 15));
      expect(parseFeedDate('2026-07-15T20:00:00Z')?.toUtc().hour, 20);
      expect(parseFeedDate('1'), isNull);
      expect(parseFeedDate(null), isNull);
    });
  });
}
