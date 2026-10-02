import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/feed_interleave.dart';
import 'external_event_tiles.dart';

/// One paged source of a merged feed (a Firestore pager, or a fixed list).
abstract class FeedSource<T> {
  bool get hasMore;
  Future<List<T>> next();
}

/// A source whose items are already in memory: one page, then exhausted.
class ListFeedSource<T> implements FeedSource<T> {
  ListFeedSource(this._items);
  final List<T> _items;
  bool _taken = false;

  @override
  bool get hasMore => !_taken;

  @override
  Future<List<T>> next() async {
    _taken = true;
    return _items;
  }
}

/// Adapts any `hasMore` / `next()` pager to a [FeedSource] (mapping items).
class PagerFeedSource<P, T> implements FeedSource<T> {
  PagerFeedSource({
    required bool Function() hasMore,
    required Future<List<P>> Function() next,
    required T Function(P) map,
  })  : _hasMore = hasMore,
        _next = next,
        _map = map;

  final bool Function() _hasMore;
  final Future<List<P>> Function() _next;
  final T Function(P) _map;

  @override
  bool get hasMore => _hasMore();

  @override
  Future<List<T>> next() async => (await _next()).map(_map).toList();
}

/// A pager source that paints its LAST-SHOWN first page instantly.
///
/// The first [next] returns [cached] (last session's first page, read from
/// the local cache) when it is non-empty, while [first] (the real first
/// server page) is already running; the following [next] returns that server
/// page minus anything already handed out, then the pager continues with
/// [next]. With an empty cache it behaves exactly like a plain pager.
class CachedFirstPageFeedSource<P, T> implements FeedSource<T> {
  CachedFirstPageFeedSource({
    required Future<List<P>> Function() cached,
    required Future<List<P>> Function() first,
    required Future<List<P>> Function() next,
    required bool Function() hasMore,
    required String Function(P) id,
    required T Function(P) map,
  })  : _cached = cached,
        _first = first,
        _next = next,
        _hasMore = hasMore,
        _id = id,
        _map = map;

  final Future<List<P>> Function() _cached;
  final Future<List<P>> Function() _first;
  final Future<List<P>> Function() _next;
  final bool Function() _hasMore;
  final String Function(P) _id;
  final T Function(P) _map;

  bool _started = false;
  Future<List<P>>? _server;
  final Set<String> _given = {};

  @override
  bool get hasMore => !_started || _server != null || _hasMore();

  List<T> _hand(List<P> page) => page
      .where((p) => _given.add(_id(p)))
      .map(_map)
      .toList();

  @override
  Future<List<T>> next() async {
    if (!_started) {
      _started = true;
      final server = _first();
      // Errors surface when awaited below, never as "unhandled".
      server.then((_) {}, onError: (Object _) {});
      _server = server;
      List<P> cached;
      try {
        cached = await _cached();
      } catch (_) {
        cached = const [];
      }
      if (cached.isNotEmpty) return _hand(cached);
    }
    final server = _server;
    if (server != null) {
      _server = null;
      return _hand(await server);
    }
    return _hand(await _next());
  }
}

/// Infinite-scroll list/grid of TWO paged sources merged by [InterleavedFeed]
/// (ordered by [compare], or round-robin when it's null).
///
/// * Bounded reads: a source is only asked for its next page when the merge
///   is waiting on it AND fewer than the window ([pageSize] more than what's
///   shown, grown on scroll) are visible.
/// * [sourceKeyA]/[sourceKeyB] change → that source is recreated (new query)
///   and the window resets to the top.
/// * [filterKey] change → the already-downloaded items are re-merged through
///   [filter] (no re-download) and the window resets to the top.
class InterleavedFeedView<T> extends StatefulWidget {
  const InterleavedFeedView({
    super.key,
    required this.createA,
    required this.createB,
    required this.sourceKeyA,
    required this.sourceKeyB,
    required this.itemBuilder,
    required this.gridView,
    required this.emptyBuilder,
    this.filterKey,
    this.filter,
    this.compare,
    this.gridAspectRatio = 0.62,
    this.onRefresh,
    this.pageSize = 20,
  });

  /// Source A (the community side). Returning null means "not ready yet"
  /// (e.g. location still resolving): the merge waits for it.
  final FeedSource<T>? Function() createA;

  /// Source B (the partner side).
  final FeedSource<T>? Function() createB;
  final Object? sourceKeyA;
  final Object? sourceKeyB;
  final Object? filterKey;
  final bool Function(T item)? filter;
  final int Function(T a, T b)? compare;
  final Widget Function(BuildContext context, T item, bool grid) itemBuilder;
  final bool gridView;
  final double gridAspectRatio;
  final WidgetBuilder emptyBuilder;

  /// Extra work on pull-to-refresh (e.g. re-query the community list); both
  /// sources are recreated afterwards.
  final Future<void> Function()? onRefresh;
  final int pageSize;

  @override
  State<InterleavedFeedView<T>> createState() => _InterleavedFeedViewState<T>();
}

class _InterleavedFeedViewState<T> extends State<InterleavedFeedView<T>> {
  final _gridScroll = ScrollController();
  final _listScroll = ScrollController();

  FeedSource<T>? _a, _b;
  final List<T> _rawA = [], _rawB = [];
  bool _aExhausted = false, _bExhausted = false;
  bool _loadingA = false, _loadingB = false;
  int _genA = 0, _genB = 0;

  late InterleavedFeed<T> _feed;
  int _target = 0;

  /// Consecutive fetches that added nothing visible (e.g. a filter hides a
  /// whole page). Capped so a strict filter can't page a whole collection;
  /// reset by the user scrolling.
  int _stall = 0;
  static const int _maxStall = 4;

  @override
  void initState() {
    super.initState();
    _gridScroll.addListener(_onScroll);
    _listScroll.addListener(_onScroll);
    _target = widget.pageSize;
    _resetA();
    _resetB();
    _rebuild();
    _pump();
  }

  @override
  void didUpdateWidget(InterleavedFeedView<T> old) {
    super.didUpdateWidget(old);
    final resetA = old.sourceKeyA != widget.sourceKeyA;
    final resetB = old.sourceKeyB != widget.sourceKeyB;
    if (resetA) _resetA();
    if (resetB) _resetB();
    if (resetA || resetB || old.filterKey != widget.filterKey) {
      _target = widget.pageSize;
      _stall = 0;
      _rebuild();
      _jumpToTop();
      _pump();
    }
  }

  @override
  void dispose() {
    _gridScroll.dispose();
    _listScroll.dispose();
    super.dispose();
  }

  void _resetA() {
    _genA++;
    _rawA.clear();
    _aExhausted = false;
    _loadingA = false;
    _a = widget.createA();
  }

  void _resetB() {
    _genB++;
    _rawB.clear();
    _bExhausted = false;
    _loadingB = false;
    _b = widget.createB();
  }

  bool _keep(T x) => widget.filter?.call(x) ?? true;

  /// Re-merge everything downloaded so far from scratch (a reset).
  void _rebuild() {
    _feed = InterleavedFeed<T>(compare: widget.compare);
    if (_rawA.isNotEmpty || _aExhausted) {
      _feed.addA(_rawA.where(_keep), hasMore: !_aExhausted);
    }
    if (_rawB.isNotEmpty || _bExhausted) {
      _feed.addB(_rawB.where(_keep), hasMore: !_bExhausted);
    }
  }

  void _jumpToTop() {
    for (final c in [_gridScroll, _listScroll]) {
      if (c.hasClients) c.jumpTo(0);
    }
  }

  /// Fetch whichever side the merge is waiting on, while the window isn't full.
  void _pump() {
    if (!mounted || _feed.length >= _target || _stall >= _maxStall) return;
    if (_feed.needsA && !_loadingA && _a != null) unawaited(_fetchA());
    if (_feed.needsB && !_loadingB && _b != null) unawaited(_fetchB());
  }

  Future<void> _fetchA() async {
    final gen = _genA, src = _a!;
    _loadingA = true;
    try {
      final page = await src.next();
      if (!mounted || gen != _genA) return;
      _rawA.addAll(page);
      final more = src.hasMore;
      if (!more) _aExhausted = true;
      final before = _feed.length;
      setState(() => _feed.addA(page.where(_keep), hasMore: more));
      _stall = _feed.length == before ? _stall + 1 : 0;
    } catch (_) {
      if (!mounted || gen != _genA) return;
      _aExhausted = true; // a failed side never holds the other back
      setState(_feed.finishA);
    } finally {
      if (gen == _genA) _loadingA = false;
    }
    _pump();
  }

  Future<void> _fetchB() async {
    final gen = _genB, src = _b!;
    _loadingB = true;
    try {
      final page = await src.next();
      if (!mounted || gen != _genB) return;
      _rawB.addAll(page);
      final more = src.hasMore;
      if (!more) _bExhausted = true;
      final before = _feed.length;
      setState(() => _feed.addB(page.where(_keep), hasMore: more));
      _stall = _feed.length == before ? _stall + 1 : 0;
    } catch (_) {
      if (!mounted || gen != _genB) return;
      _bExhausted = true;
      setState(_feed.finishB);
    } finally {
      if (gen == _genB) _loadingB = false;
    }
    _pump();
  }

  void _loadMore() {
    if (_feed.isComplete) return;
    if (_target <= _feed.length) _target = _feed.length + widget.pageSize;
    _stall = 0;
    _pump();
  }

  void _onScroll() {
    final c = _gridScroll.hasClients
        ? _gridScroll
        : (_listScroll.hasClients ? _listScroll : null);
    if (c == null) return;
    if (c.position.maxScrollExtent - c.position.pixels < 400) _loadMore();
  }

  Future<void> _refresh() async {
    await widget.onRefresh?.call();
    if (!mounted) return;
    setState(() {
      _resetA();
      _resetB();
      _target = widget.pageSize;
      _stall = 0;
      _rebuild();
    });
    _pump();
  }

  bool get _busy =>
      _loadingA ||
      _loadingB ||
      (!_feed.isComplete &&
          ((_feed.needsA && _a == null) || (_feed.needsB && _b == null)));

  @override
  Widget build(BuildContext context) {
    final items = _feed.items;
    if (items.isEmpty) {
      if (!_feed.isComplete && (_busy || _stall < _maxStall)) {
        return const Center(
            child: CircularProgressIndicator(color: AppColors.richGold));
      }
      return RefreshIndicator(
        color: AppColors.richGold,
        onRefresh: _refresh,
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight),
              child: Center(child: widget.emptyBuilder(context)),
            ),
          ),
        ),
      );
    }

    // A short first window that doesn't fill the viewport can't be scrolled
    // to trigger more: ask for the next window once laid out.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _busy || _feed.isComplete) return;
      final c = widget.gridView ? _gridScroll : _listScroll;
      if (c.hasClients && c.position.maxScrollExtent <= 0) _loadMore();
    });

    final showLoader = !_feed.isComplete && _busy;
    final Widget child;
    if (widget.gridView) {
      child = GridView.builder(
        key: const ValueKey('mergedGrid'),
        controller: _gridScroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: eventsGridColumns(context),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: widget.gridAspectRatio,
        ),
        itemCount: items.length,
        itemBuilder: (context, i) =>
            widget.itemBuilder(context, items[i], true),
      );
    } else {
      child = ListView.builder(
        key: const ValueKey('mergedList'),
        controller: _listScroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        itemCount: items.length + (showLoader ? 1 : 0),
        itemBuilder: (context, i) {
          if (i >= items.length) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                  child: CircularProgressIndicator(color: AppColors.richGold)),
            );
          }
          return widget.itemBuilder(context, items[i], false);
        },
      );
    }
    return RefreshIndicator(
      color: AppColors.richGold,
      onRefresh: _refresh,
      child: child,
    );
  }
}
