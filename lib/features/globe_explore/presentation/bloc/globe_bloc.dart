import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/country_centroids.dart';
import '../../domain/entities/globe_user.dart';
import '../../domain/repositories/globe_repository.dart';
import '../../domain/usecases/get_globe_data.dart';
import 'globe_event.dart';
import 'globe_filter_store.dart';
import 'globe_state.dart';

/// The network map's state. Holds the user's whole (bounded) network and
/// emits it filtered by the chips that are on ([GlobeNetworkFilter]); the
/// filtered list is computed once per data / filter change, so the map's
/// per-zoom marker cache survives unrelated state changes.
class GlobeBloc extends Bloc<GlobeEvent, GlobeState> {

  GlobeBloc({
    required this.getGlobeData,
    required this.repository,
    GlobeFilterStore? filterStore,
  })  : _filterStore = filterStore ?? const GlobeFilterStore(),
        super(GlobeInitial()) {
    on<GlobeLoadRequested>(_onLoad);
    on<GlobeRefreshRequested>(_onRefresh);
    on<GlobePinTapped>(_onPinTapped);
    on<GlobeFilterToggled>(_onFilterToggled);
    on<GlobeFlyToCountry>(_onFlyToCountry);
    on<GlobeCountryTapped>(_onCountryTapped);
  }
  final GetGlobeData getGlobeData;
  final GlobeRepository repository;
  final GlobeFilterStore _filterStore;

  Set<GlobeNetworkFilter> _filters = kAllGlobeFilters;
  bool _filtersLoaded = false;

  /// Everything loaded (unfiltered).
  GlobeData? _allData;

  /// [_allData] filtered by [_filters] (memo).
  GlobeData? _visible;

  /// Source of the request ids on one-shot states (pin / country / fly).
  int _requestSeq = 0;

  GlobeData? get _currentData => _visible;

  void _setData(GlobeData data) {
    _allData = data;
    _visible = data.filteredBy(_filters);
  }

  Future<void> _ensureFilters() async {
    if (_filtersLoaded) return;
    _filtersLoaded = true;
    _filters = await _filterStore.load();
  }

  Future<void> _onLoad(
    GlobeLoadRequested event,
    Emitter<GlobeState> emit,
  ) async {
    emit(GlobeLoading());
    final resultFuture = getGlobeData(event.userId);
    await _ensureFilters();

    // Show the map as soon as the user's own pin is known (one doc read,
    // shared with the load above); network pins are added when they arrive.
    final me = await repository.getCurrentUserPin(userId: event.userId);
    if (me != null && state is GlobeLoading && _allData == null) {
      emit(GlobeLoaded(
        data: GlobeData(
          currentUser: me,
          matchedUsers: const [],
          discoveryUsers: const [],
        ),
        filters: _filters,
      ));
    }

    final result = await resultFuture;
    result.fold(
      (failure) => emit(GlobeError(message: failure.message)),
      (data) {
        _setData(data);
        emit(GlobeLoaded(data: _visible!, filters: _filters));
      },
    );
  }

  Future<void> _onRefresh(
    GlobeRefreshRequested event,
    Emitter<GlobeState> emit,
  ) async {
    emit(GlobeLoading());
    await _ensureFilters();
    final result = await getGlobeData(event.userId);
    result.fold(
      (failure) => emit(GlobeError(message: failure.message)),
      (data) {
        _setData(data);
        emit(GlobeLoaded(data: _visible!, filters: _filters));
      },
    );
  }

  void _onPinTapped(GlobePinTapped event, Emitter<GlobeState> emit) {
    final data = _currentData;
    if (data == null) return;
    final allUsers = [
      data.currentUser,
      ...data.matchedUsers,
      ...data.discoveryUsers,
    ];
    final user = allUsers.firstWhere(
      (u) => u.userId == event.tappedUserId,
      orElse: () => data.currentUser,
    );
    emit(GlobePinSelected(
      selectedUser: user,
      data: data,
      filters: _filters,
      requestId: ++_requestSeq,
    ));
  }

  void _onFilterToggled(
    GlobeFilterToggled event,
    Emitter<GlobeState> emit,
  ) {
    final next = {..._filters};
    if (!next.remove(event.filter)) next.add(event.filter);
    _filters = Set.unmodifiable(next);
    _filtersLoaded = true;
    unawaited(_filterStore.save(_filters));
    final all = _allData;
    if (all != null) {
      _setData(all);
      emit(GlobeLoaded(data: _visible!, filters: _filters));
    } else if (state is GlobeLoaded) {
      emit(GlobeLoaded(
          data: (state as GlobeLoaded).data, filters: _filters));
    }
  }

  void _onFlyToCountry(GlobeFlyToCountry event, Emitter<GlobeState> emit) {
    final data = _currentData;
    if (data != null) {
      emit(GlobeLoaded(
        data: data,
        filters: _filters,
        flyToCountry: event.country,
        flyRequestId: ++_requestSeq,
      ));
    }
  }

  void _onCountryTapped(
    GlobeCountryTapped event,
    Emitter<GlobeState> emit,
  ) {
    final data = _currentData;
    if (data == null) return;
    final normalized = normalizeCountryName(event.countryName);
    final matchesInCountry = data.matchedUsers
        .where(
            (u) => u.country.toLowerCase() == normalized.toLowerCase())
        .toList();
    emit(GlobeCountrySelected(
      countryName: normalized,
      matchesInCountry: matchesInCountry,
      data: data,
      filters: _filters,
      requestId: ++_requestSeq,
    ));
  }
}
