import 'dart:async';

import 'package:flutter/material.dart';
import 'package:showcaseview/showcaseview.dart';

import '../tour_controller.dart';
import '../tour_environment.dart';
import 'gesture_glyphs.dart';
import 'tour_showcase.dart';
import 'tour_trigger.dart';

/// Hosts a one-time page tour (Tier 2, v2).
///
/// * Arms the tour only while it is still pending for this user on this
///   device: [TourAnchor]s below wrap their child in a [TourShowcase] ONLY
///   while armed. A page whose tour is done never puts the shared
///   [GlobalKey]s in the tree, so the same screen pushed twice (a profile on
///   top of a profile) can never hit a duplicate-GlobalKey error.
/// * Starts the tour once, after the first frame in which the page is visible
///   (see [VisibleTabScope]), [enabled] and [ready] (e.g. data loaded), then
///   waits [startDelay] so the targets have laid out. Unmounted targets are
///   skipped by [TourController.maybeStartMiniTour].
/// * Re-arms when the App Guide resets the tour ([TourController.replayRequests]).
///
/// [ownShowcase] = false reuses the page's existing `ShowCaseWidget` (a page
/// that already runs another tour); the host must then sit inside it.
class PageTourHost extends StatefulWidget {
  const PageTourHost({
    required this.tourId,
    required this.userId,
    required this.keys,
    required this.child,
    this.enabled = true,
    this.ready = true,
    this.alsoMarkDone = const [],
    this.ownShowcase = true,
    this.enableAutoScroll = false,
    this.startDelay = const Duration(milliseconds: 600),
    super.key,
  });

  final String tourId;
  final String? userId;

  /// Steps in display order (evaluated at start time).
  final List<GlobalKey> Function() keys;
  final Widget child;

  /// False skips the tour entirely (e.g. not a business account).
  final bool enabled;

  /// False defers the start (e.g. while the page is still loading).
  final bool ready;

  /// Tours whose steps this one already covers (marked done with it).
  final List<String> alsoMarkDone;
  final bool ownShowcase;
  final bool enableAutoScroll;
  final Duration startDelay;

  @override
  State<PageTourHost> createState() => _PageTourHostState();
}

class _PageTourHostState extends State<PageTourHost> {
  bool _armed = false;
  bool _attempted = false;
  bool _visible = true;
  int _waits = 0;
  BuildContext? _showcaseContext;
  Timer? _timer;

  String? get _uid {
    final u = widget.userId;
    return (u == null || u.isEmpty) ? null : u;
  }

  @override
  void initState() {
    super.initState();
    final uid = _uid;
    if (uid != null && widget.enabled && TourEnvironment.enabled) {
      _armed = TourController.isPendingSync(widget.tourId, uid) ?? false;
    }
    TourController.instance.replayRequests.addListener(_onReplay);
    _refreshArmed();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Off-stage (an inactive tab, a collapsed accordion that keeps its
    // children alive) mutes tickers: wait until the page is really shown.
    _visible = (VisibleTabScope.of(context)?.isVisible ?? true) &&
        TickerMode.of(context);
    _schedule();
  }

  @override
  void didUpdateWidget(PageTourHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    final becameReady = widget.ready && !oldWidget.ready;
    if (widget.enabled != oldWidget.enabled ||
        widget.userId != oldWidget.userId ||
        becameReady) {
      if (becameReady) _attempted = false;
      _refreshArmed();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    TourController.instance.replayRequests.removeListener(_onReplay);
    super.dispose();
  }

  void _onReplay() {
    if (TourController.instance.replayRequests.value != widget.tourId) return;
    _attempted = false;
    _refreshArmed();
  }

  Future<void> _refreshArmed() async {
    final uid = _uid;
    if (uid == null || !widget.enabled || !TourEnvironment.enabled) return;
    bool done;
    try {
      done = await TourController.isTourDone(widget.tourId, uid);
    } catch (_) {
      return; // No prefs (e.g. plugin unavailable): never block the page.
    }
    if (!mounted || done) return;
    if (!_armed) setState(() => _armed = true);
    _schedule();
  }

  void _schedule() {
    if (!_armed || _attempted || !widget.enabled || !widget.ready) return;
    if (_uid == null || !_visible) return;
    _attempted = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _timer?.cancel();
      _timer = Timer(widget.startDelay, _start);
    });
  }

  Future<void> _start() async {
    final uid = _uid;
    final ctx = _showcaseContext;
    if (!mounted || uid == null || ctx == null || !ctx.mounted || !_visible) {
      _attempted = false;
      return;
    }
    // Another tour is running on this page: try again shortly (max ~1 min).
    final running = !ShowCaseWidget.of(ctx).isShowCaseCompleted ||
        TourController.instance.isMainTourActive;
    if (running) {
      if (_waits++ < 60) {
        _timer = Timer(const Duration(seconds: 1), _start);
      }
      return;
    }
    try {
      final started = await TourController.instance.maybeStartMiniTour(
        ctx,
        tourId: widget.tourId,
        userId: uid,
        keys: widget.keys(),
        alsoMarkDone: widget.alsoMarkDone,
      );
      // Nothing mounted yet (the page is still loading its data): look
      // again shortly, for up to ~1 min, while the page stays open.
      if (!started &&
          mounted &&
          !await TourController.isTourDone(widget.tourId, uid) &&
          _waits++ < 60) {
        _timer = Timer(const Duration(seconds: 1), _start);
      }
    } catch (_) {/* a tour must never break its page */}
  }

  @override
  Widget build(BuildContext context) {
    final parent = PageTourScope._maybeOf(context);
    final scope = PageTourScope(
      armedTourIds: {
        ...?parent?.armedTourIds,
        if (_armed) widget.tourId,
      },
      child: widget.child,
    );
    Widget capture(BuildContext inner) {
      _showcaseContext = inner;
      return scope;
    }

    if (!widget.ownShowcase) return Builder(builder: capture);
    return ShowCaseWidget(
      enableAutoScroll: widget.enableAutoScroll,
      builder: (_) => Builder(builder: capture),
    );
  }
}

/// Which page tours are armed for the subtree (see [PageTourHost]).
class PageTourScope extends InheritedWidget {
  const PageTourScope({
    required this.armedTourIds,
    required super.child,
    super.key,
  });

  final Set<String> armedTourIds;

  static PageTourScope? _maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PageTourScope>();

  static bool isArmed(BuildContext context, String tourId) =>
      _maybeOf(context)?.armedTourIds.contains(tourId) ?? false;

  @override
  bool updateShouldNotify(PageTourScope oldWidget) =>
      armedTourIds.length != oldWidget.armedTourIds.length ||
      !armedTourIds.containsAll(oldWidget.armedTourIds);
}

/// A page-tour step target: a [TourShowcase] while [tourId] is armed by an
/// enclosing [PageTourHost], otherwise just [child].
class TourAnchor extends StatelessWidget {
  const TourAnchor({
    required this.tourId,
    required this.showcaseKey,
    required this.title,
    required this.description,
    required this.child,
    this.gesture = TourGesture.tap,
    this.targetShapeBorder,
    this.targetPadding = EdgeInsets.zero,
    this.tooltipPosition,
    super.key,
  });

  final String tourId;
  final GlobalKey showcaseKey;
  final String title;
  final String description;
  final Widget child;
  final TourGesture gesture;
  final ShapeBorder? targetShapeBorder;
  final EdgeInsets targetPadding;
  final TooltipPosition? tooltipPosition;

  @override
  Widget build(BuildContext context) {
    if (!PageTourScope.isArmed(context, tourId)) return child;
    return TourShowcase(
      showcaseKey: showcaseKey,
      title: title,
      description: description,
      gesture: gesture,
      targetShapeBorder: targetShapeBorder,
      targetPadding: targetPadding,
      tooltipPosition: tooltipPosition,
      child: child,
    );
  }
}
