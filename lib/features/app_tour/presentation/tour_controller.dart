import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';

import 'tour_keys.dart';

/// Coordinates the first-launch gesture tour and the one-time contextual
/// mini-tours (chat, swipe mode, profile detail, story).
///
/// All tours are device-scoped per user: a fresh install (or a different
/// account on the same device) sees them again.
class TourController {
  TourController._();

  static final TourController instance = TourController._();

  static const String _mainTourId = 'main';
  static const String chatTourId = 'chat';
  static const String swipeTourId = 'swipe';
  static const String profileDetailTourId = 'profile_detail';
  static const String storyTourId = 'story';

  // Tier-2 per-page first-time tours (Phase 5).
  static const String communitiesTourId = 'communities';
  static const String eventsTourId = 'events';
  static const String profileTourId = 'profile';
  static const String notificationsTourId = 'notifications';

  static String _prefKey(String tourId, String userId) =>
      'tour_${tourId}_done_$userId';

  /// True while the main tour is running. Used to defer the membership
  /// dialog until the tour ends.
  bool isMainTourActive = false;

  void Function(bool completed)? _onMainTourEnded;
  String? _userId;

  /// key -> 1-based step number for the currently running tour.
  final Map<GlobalKey, int> _stepNumbers = {};
  int _stepCount = 0;

  /// Step label for tooltips: (index, total). (0, 0) when key unknown.
  (int, int) stepNumberFor(GlobalKey key) =>
      (_stepNumbers[key] ?? 0, _stepCount);

  /// The Tier-1 tour, in display order. Keys whose widgets are not mounted
  /// (e.g. card steps on an empty grid) are filtered out at start time.
  static List<GlobalKey> get _mainTourKeys => [
        TourKeys.gridBody,
        TourKeys.firstCard,
        TourKeys.cardEdges,
        TourKeys.cardHold,
        TourKeys.pullRefresh,
        TourKeys.modeToggle,
        TourKeys.globe,
        TourKeys.search,
        TourKeys.preferences,
        TourKeys.coins,
        TourKeys.help,
        TourKeys.navMessages,
        TourKeys.navLeaderboard,
        TourKeys.navShop,
        TourKeys.navProfile,
      ];

  // ── Tier 1: main tour ──

  static Future<bool> shouldShowMainTour(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_prefKey(_mainTourId, userId)) ?? false);
  }

  /// Starts the main tour inside [context]'s ShowCaseWidget.
  /// Returns false when nothing could be highlighted.
  bool startMainTour(
    BuildContext context, {
    required String userId,
    void Function(bool completed)? onEnded,
  }) {
    final keys = _mountedKeys(_mainTourKeys);
    if (keys.isEmpty) return false;

    _userId = userId;
    _onMainTourEnded = onEnded;
    _index(keys);
    isMainTourActive = true;
    ShowCaseWidget.of(context).startShowCase(keys);
    return true;
  }

  /// Advances to the next step (wired to Next buttons and interactive
  /// target gestures).
  void advance(BuildContext context) {
    ShowCaseWidget.of(context).next();
  }

  /// Skip from any step: tears the overlay down and finalizes the tour.
  void skipMainTour(BuildContext context) {
    ShowCaseWidget.of(context).dismiss();
    handleMainTourFinish(completed: false);
  }

  /// Called when the last step completes (ShowCaseWidget.onFinish) or the
  /// tour is skipped. Persists completion and releases deferred dialogs.
  void handleMainTourFinish({bool completed = true}) {
    if (!isMainTourActive) return;
    isMainTourActive = false;
    final userId = _userId;
    if (userId != null) {
      _markDone(_mainTourId, userId);
    }
    _stepNumbers.clear();
    _stepCount = 0;
    final callback = _onMainTourEnded;
    _onMainTourEnded = null;
    callback?.call(completed);
  }

  // ── Tier 2: contextual mini-tours ──

  /// Fires a one-time mini-tour identified by [tourId] for the mounted
  /// subset of [keys]. No-op when already completed or nothing is mounted.
  Future<void> maybeStartMiniTour(
    BuildContext context, {
    required String tourId,
    required String userId,
    required List<GlobalKey> keys,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_prefKey(tourId, userId)) ?? false) return;

    final mounted = _mountedKeys(keys);
    if (mounted.isEmpty || !context.mounted) return;

    // Persist immediately: a mini-tour should never nag twice even if the
    // user dismisses it mid-way.
    await prefs.setBool(_prefKey(tourId, userId), true);
    if (!context.mounted) return;

    _index(mounted);
    ShowCaseWidget.of(context).startShowCase(mounted);
  }

  /// Force-starts a mini-tour NOW for the mounted subset of [keys], IGNORING the
  /// done flag. Used by a per-page "replay guide" button.
  void startMiniTourNow(BuildContext context, List<GlobalKey> keys) {
    final mounted = _mountedKeys(keys);
    if (mounted.isEmpty) return;
    _index(mounted);
    ShowCaseWidget.of(context).startShowCase(mounted);
  }

  /// One-time check used by non-showcase hints (swipe-mode overlay).
  static Future<bool> shouldShowOnce(String tourId, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_prefKey(tourId, userId)) ?? false) return false;
    await prefs.setBool(_prefKey(tourId, userId), true);
    return true;
  }

  // ── Replay ──

  /// Clears every tour flag so the user can replay the full tutorial
  /// (main tour + contextual hints) from the app guide.
  static Future<void> resetAllTours(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    for (final id in [
      _mainTourId,
      chatTourId,
      swipeTourId,
      profileDetailTourId,
      storyTourId,
      communitiesTourId,
      eventsTourId,
      profileTourId,
      notificationsTourId,
    ]) {
      await prefs.remove(_prefKey(id, userId));
    }
  }

  // ── Internals ──

  static Future<void> _markDone(String tourId, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey(tourId, userId), true);
  }

  List<GlobalKey> _mountedKeys(List<GlobalKey> keys) =>
      keys.where((k) => k.currentContext != null).toList();

  void _index(List<GlobalKey> keys) {
    _stepNumbers.clear();
    for (var i = 0; i < keys.length; i++) {
      _stepNumbers[keys[i]] = i + 1;
    }
    _stepCount = keys.length;
  }
}
