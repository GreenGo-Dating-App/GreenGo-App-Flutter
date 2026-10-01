/// Pure (Flutter-free) merge of two independently paged feeds into ONE list —
/// e.g. Events → "All" (community events + partner live events) and
/// Experiences → "All" (member-hosted + partner experiences).
///
/// Rules:
///  * Append-only: items already handed out ([items]) never move. New pages only
///    ever extend the tail, so the list never "jumps" under the user's thumb.
///  * Ordered merge ([compare] given): an item is emitted only once it is known
///    to precede every item still to come from BOTH sources — i.e. while both
///    sources have a pending head, the smaller head wins (ties → source A);
///    when one side's buffer is empty but it still has pages, the merge WAITS
///    for that page ([needsA]/[needsB] tell the caller what to fetch). An
///    exhausted side never blocks the other.
///  * Each arriving page is inserted into its side's PENDING buffer in order
///    (stable), so a slightly out-of-order source page is still merged sorted —
///    without ever touching what is already on screen.
///  * Round-robin mode ([compare] null): for feeds with no common ordering key
///    (e.g. "newest" vs "top rated"), items alternate A, B, A, B…; an exhausted
///    side yields its turns to the other.
class InterleavedFeed<T> {
  InterleavedFeed({this.compare});

  /// Ordering of the merged list; null = round-robin alternation.
  final int Function(T a, T b)? compare;

  final List<T> _pendingA = [];
  final List<T> _pendingB = [];
  final List<T> _out = [];
  bool _aDone = false;
  bool _bDone = false;
  bool _turnA = true; // round-robin: whose turn is next

  /// The merged list so far (append-only).
  List<T> get items => List.unmodifiable(_out);
  int get length => _out.length;

  bool get aDone => _aDone;
  bool get bDone => _bDone;

  /// Source A must deliver its next page before the merge can continue.
  bool get needsA => _pendingA.isEmpty && !_aDone;

  /// Source B must deliver its next page before the merge can continue.
  bool get needsB => _pendingB.isEmpty && !_bDone;

  /// Nothing left anywhere: both sources exhausted and fully emitted.
  bool get isComplete =>
      _aDone && _bDone && _pendingA.isEmpty && _pendingB.isEmpty;

  /// Items received but not yet emitted (waiting on the other source).
  int get pendingCount => _pendingA.length + _pendingB.length;

  /// Feeds a page of source A. [hasMore] = false marks A exhausted.
  /// Returns the items newly appended to [items].
  List<T> addA(Iterable<T> page, {required bool hasMore}) {
    _insertAll(_pendingA, page);
    if (!hasMore) _aDone = true;
    return _drain();
  }

  /// Feeds a page of source B. [hasMore] = false marks B exhausted.
  List<T> addB(Iterable<T> page, {required bool hasMore}) {
    _insertAll(_pendingB, page);
    if (!hasMore) _bDone = true;
    return _drain();
  }

  /// Marks A exhausted (e.g. its query failed) so B is no longer held back.
  List<T> finishA() {
    _aDone = true;
    return _drain();
  }

  /// Marks B exhausted.
  List<T> finishB() {
    _bDone = true;
    return _drain();
  }

  void _insertAll(List<T> pending, Iterable<T> page) {
    final cmp = compare;
    if (cmp == null) {
      pending.addAll(page);
      return;
    }
    for (final x in page) {
      // Upper-bound binary search: insert AFTER equal keys (stable).
      var lo = 0, hi = pending.length;
      while (lo < hi) {
        final mid = (lo + hi) >> 1;
        if (cmp(pending[mid], x) <= 0) {
          lo = mid + 1;
        } else {
          hi = mid;
        }
      }
      pending.insert(lo, x);
    }
  }

  List<T> _drain() {
    final start = _out.length;
    final cmp = compare;
    while (true) {
      final hasA = _pendingA.isNotEmpty, hasB = _pendingB.isNotEmpty;
      if (cmp != null) {
        if (hasA && hasB) {
          _out.add(cmp(_pendingA.first, _pendingB.first) <= 0
              ? _pendingA.removeAt(0)
              : _pendingB.removeAt(0));
        } else if (hasA && _bDone) {
          _out.add(_pendingA.removeAt(0));
        } else if (hasB && _aDone) {
          _out.add(_pendingB.removeAt(0));
        } else {
          break;
        }
      } else {
        if (_turnA) {
          if (hasA) {
            _out.add(_pendingA.removeAt(0));
            _turnA = false;
          } else if (_aDone && hasB) {
            _out.add(_pendingB.removeAt(0)); // A exhausted: B takes its turn
          } else {
            break; // wait for A's page (or nothing left)
          }
        } else {
          if (hasB) {
            _out.add(_pendingB.removeAt(0));
            _turnA = true;
          } else if (_bDone && hasA) {
            _out.add(_pendingA.removeAt(0));
          } else {
            break;
          }
        }
      }
    }
    return _out.sublist(start);
  }
}

/// Ordering key of one merged-feed item.
class FeedSortKey {
  const FeedSortKey({this.date, this.distanceKm});

  /// Start date (events) — null sorts last.
  final DateTime? date;

  /// Distance from the viewer in km — null (unknown) sorts last.
  final double? distanceKm;
}

int _cmpNullableNum(num? a, num? b) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return a.compareTo(b);
}

int _cmpDay(DateTime? a, DateTime? b) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  final da = DateTime(a.year, a.month, a.day);
  final db = DateTime(b.year, b.month, b.day);
  return da.compareTo(db);
}

/// Soonest first; on the SAME calendar day the nearest wins (partner feeds
/// often carry a date without a time), then the earlier exact time.
int compareSoonestThenNearest(FeedSortKey a, FeedSortKey b) {
  final byDay = _cmpDay(a.date, b.date);
  if (byDay != 0) return byDay;
  final byDist = _cmpNullableNum(a.distanceKm, b.distanceKm);
  if (byDist != 0) return byDist;
  return _cmpNullableNum(
      a.date?.millisecondsSinceEpoch, b.date?.millisecondsSinceEpoch);
}

/// Nearest first; equal distances → soonest.
int compareNearestThenSoonest(FeedSortKey a, FeedSortKey b) {
  final byDist = _cmpNullableNum(a.distanceKm, b.distanceKm);
  if (byDist != 0) return byDist;
  return _cmpNullableNum(
      a.date?.millisecondsSinceEpoch, b.date?.millisecondsSinceEpoch);
}

/// Parses a partner ISO date (`2026-07-15` or `2026-07-15T20:00:00Z`); null
/// when missing/malformed.
DateTime? parseFeedDate(String? iso) {
  if (iso == null || iso.length < 10) return null;
  return DateTime.tryParse(iso) ?? DateTime.tryParse(iso.substring(0, 10));
}
