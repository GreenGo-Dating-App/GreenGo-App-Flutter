import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../experience_bookings/domain/entities/booking.dart';
import '../../data/my_space_repository.dart';
import '../../domain/my_space_calendar.dart';

class MySpaceCalendarState extends Equatable {
  const MySpaceCalendarState({
    this.eventFilter = MsCalendarFilter.all,
    this.experienceFilter = MsCalendarFilter.all,
    this.bookings = const <String, Booking>{},
    this.photos = const <String, String>{},
    this.loading = false,
    this.failed = false,
  });

  final MsCalendarFilter eventFilter;
  final MsCalendarFilter experienceFilter;

  /// Bookings of every range loaded so far, by id (hosting + going).
  final Map<String, Booking> bookings;

  /// experienceId -> first photo (memoised; absent = icon fallback).
  final Map<String, String> photos;
  final bool loading;
  final bool failed;

  MySpaceCalendarState copyWith({
    MsCalendarFilter? eventFilter,
    MsCalendarFilter? experienceFilter,
    Map<String, Booking>? bookings,
    Map<String, String>? photos,
    bool? loading,
    bool? failed,
  }) =>
      MySpaceCalendarState(
        eventFilter: eventFilter ?? this.eventFilter,
        experienceFilter: experienceFilter ?? this.experienceFilter,
        bookings: bookings ?? this.bookings,
        photos: photos ?? this.photos,
        loading: loading ?? this.loading,
        failed: failed ?? this.failed,
      );

  @override
  List<Object?> get props =>
      [eventFilter, experienceFilter, bookings, photos, loading, failed];
}

/// The My Space calendars: the chip filters of both, and the experience
/// bookings of the VISIBLE range only.
///
///  * per-user bounded queries: (hostId | guestId, slotStart) in [from, to),
///    `limit` 300 each — never a full-collection read
///  * each range is loaded once (memoised) until [refresh]
///  * range changes are debounced; a stale load never flips the spinner of
///    the newest one
///  * experience photos are batch-read (whereIn, 30 per query) once per id
///  * failures stay here: My Space's lists never depend on this cubit
class MySpaceCalendarCubit extends Cubit<MySpaceCalendarState> {
  MySpaceCalendarCubit({
    required MySpaceRepository repository,
    required this.uid,
    this.debounce = const Duration(milliseconds: 300),
  })  : _repo = repository,
        super(const MySpaceCalendarState());

  final MySpaceRepository _repo;
  final String uid;
  final Duration debounce;

  /// Above this many cached bookings, those outside the newest range go.
  static const int maxCached = 2000;

  final Set<String> _loadedRanges = {};
  final Set<String> _photosAsked = {};
  (DateTime, DateTime)? _range;
  Timer? _timer;
  int _gen = 0;

  static String _key(DateTime from, DateTime to) =>
      '${from.millisecondsSinceEpoch}_${to.millisecondsSinceEpoch}';

  void setEventFilter(MsCalendarFilter f) {
    if (f != state.eventFilter) emit(state.copyWith(eventFilter: f));
  }

  void setExperienceFilter(MsCalendarFilter f) {
    if (f != state.experienceFilter) emit(state.copyWith(experienceFilter: f));
  }

  /// The experiences calendar shows [from, to): load it if new.
  void rangeChanged(DateTime from, DateTime to) {
    final first = _range == null;
    _range = (from, to);
    _timer?.cancel();
    if (_loadedRanges.contains(_key(from, to))) {
      // Already here; cancel the spinner of a load superseded by this.
      _gen++;
      if (state.loading) emit(state.copyWith(loading: false));
      return;
    }
    if (first) {
      unawaited(_load(from, to));
    } else {
      _timer = Timer(debounce, () => _load(from, to));
    }
  }

  /// Reloads the current range (pull-to-refresh, back from a booking).
  Future<void> refresh() async {
    _timer?.cancel();
    _loadedRanges.clear();
    final r = _range;
    if (r != null) await _load(r.$1, r.$2);
  }

  Future<void> retry() => refresh();

  static Future<List<Booking>?> _safe(Future<List<Booking>> f) async {
    try {
      return await f;
    } catch (_) {
      return null;
    }
  }

  Future<void> _load(DateTime from, DateTime to) async {
    if (isClosed) return;
    final gen = ++_gen;
    emit(state.copyWith(loading: true));
    final r = await Future.wait([
      _safe(_repo.hostBookingsInRange(uid, from, to)),
      _safe(_repo.guestBookingsInRange(uid, from, to)),
    ]);
    final host = r[0];
    final guest = r[1];
    if (isClosed) return;
    final ok = host != null && guest != null;
    // Replace what was cached for this range with the fresh answer (a
    // booking cancelled since then shows its new status, i.e. disappears).
    final next = <String, Booking>{};
    final keepOld = state.bookings.length < maxCached;
    for (final b in state.bookings.values) {
      final inRange = !b.slotStart.isBefore(from) && b.slotStart.isBefore(to);
      if (inRange) {
        // Keep the old copy only for the side that failed to answer.
        final side = b.hostId == uid ? host : guest;
        if (side == null) next[b.id] = b;
      } else if (keepOld) {
        next[b.id] = b;
      }
    }
    for (final b in [...?host, ...?guest]) {
      next[b.id] = b;
    }
    if (ok) _loadedRanges.add(_key(from, to));
    final latest = gen == _gen;
    emit(state.copyWith(
      bookings: Map.unmodifiable(next),
      loading: latest ? false : state.loading,
      failed: latest ? !ok : state.failed,
    ));
    await _loadPhotos([...?host, ...?guest]);
  }

  Future<void> _loadPhotos(List<Booking> bookings) async {
    final hosted = <String>{};
    final other = <String>{};
    for (final b in bookings) {
      final id = b.experienceId;
      if (id.isEmpty || _photosAsked.contains(id)) continue;
      (b.hostId == uid ? hosted : other).add(id);
    }
    other.removeAll(hosted);
    if (hosted.isEmpty && other.isEmpty) return;
    _photosAsked
      ..addAll(hosted)
      ..addAll(other);
    final found = <String, String>{};
    Future<void> fetch(Set<String> ids, bool isHosted) async {
      if (ids.isEmpty) return;
      try {
        found.addAll(await _repo.experiencePhotos(uid, ids.toList(),
            hosted: isHosted));
      } catch (_) {
        _photosAsked.removeAll(ids); // try again with the next range
      }
    }

    await Future.wait([fetch(hosted, true), fetch(other, false)]);
    if (isClosed || found.isEmpty) return;
    emit(state.copyWith(photos: Map.unmodifiable({...state.photos, ...found})));
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
