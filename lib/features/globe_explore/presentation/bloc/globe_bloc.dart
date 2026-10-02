import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/country_centroids.dart';
import '../../domain/entities/globe_user.dart';
import '../../domain/repositories/globe_repository.dart';
import '../../domain/usecases/get_globe_data.dart';
import 'globe_event.dart';
import 'globe_state.dart';

class GlobeBloc extends Bloc<GlobeEvent, GlobeState> {

  GlobeBloc({
    required this.getGlobeData,
    required this.repository,
  }) : super(GlobeInitial()) {
    on<GlobeLoadRequested>(_onLoad);
    on<GlobeRefreshRequested>(_onRefresh);
    on<GlobePinTapped>(_onPinTapped);
    on<GlobeFilterToggled>(_onFilterToggled);
    on<GlobeFlyToCountry>(_onFlyToCountry);
    on<GlobeCountryTapped>(_onCountryTapped);
    on<GlobeMatchesUpdated>(_onMatchesUpdated);
    on<GlobeOnlineStatusUpdated>(_onOnlineStatusUpdated);
  }
  final GetGlobeData getGlobeData;
  final GlobeRepository repository;

  StreamSubscription? _matchSub;
  StreamSubscription? _onlineSub;
  bool _showMatched = true;
  bool _showDiscovery = true;
  GlobeData? _currentData;

  Future<void> _onLoad(
    GlobeLoadRequested event,
    Emitter<GlobeState> emit,
  ) async {
    emit(GlobeLoading());
    final resultFuture = getGlobeData(event.userId);

    // Show the map as soon as the user's own pin is known (one doc read,
    // shared with the load above); matched pins are added when they arrive.
    final me = await repository.getCurrentUserPin(userId: event.userId);
    if (me != null && state is GlobeLoading && _currentData == null) {
      emit(GlobeLoaded(
        data: GlobeData(
          currentUser: me,
          matchedUsers: const [],
          discoveryUsers: const [],
        ),
        showMatched: _showMatched,
        showDiscovery: _showDiscovery,
      ));
    }

    final result = await resultFuture;
    result.fold(
      (failure) => emit(GlobeError(message: failure.message)),
      (data) {
        _currentData = data;
        emit(GlobeLoaded(
          data: data,
          showMatched: _showMatched,
          showDiscovery: _showDiscovery,
        ));
        _startMatchStream(event.userId);
        _startOnlineStream(data);
      },
    );
  }

  Future<void> _onRefresh(
    GlobeRefreshRequested event,
    Emitter<GlobeState> emit,
  ) async {
    emit(GlobeLoading());
    final result = await getGlobeData(event.userId);
    result.fold(
      (failure) => emit(GlobeError(message: failure.message)),
      (data) {
        _currentData = data;
        emit(GlobeLoaded(
          data: data,
          showMatched: _showMatched,
          showDiscovery: _showDiscovery,
        ));
        _startMatchStream(event.userId);
        _startOnlineStream(data);
      },
    );
  }

  void _startMatchStream(String userId) {
    _matchSub?.cancel();
    _matchSub = repository.watchMatchUpdates(userId: userId).listen(
      (updatedMatches) =>
          add(GlobeMatchesUpdated(updatedMatches: updatedMatches)),
      onError: (Object _) {}, // keep the pins we have
    );
  }

  /// Same pins (by user + match) as already shown.
  bool _sameMatches(List<GlobeUser> next) {
    final cur = _currentData?.matchedUsers;
    if (cur == null || cur.length != next.length) return false;
    for (var i = 0; i < cur.length; i++) {
      if (cur[i].userId != next[i].userId || cur[i].matchId != next[i].matchId) {
        return false;
      }
    }
    return true;
  }

  void _startOnlineStream(GlobeData data) {
    _onlineSub?.cancel();
    final allUserIds = [
      ...data.matchedUsers.map((u) => u.userId),
      ...data.discoveryUsers.map((u) => u.userId),
    ];
    if (allUserIds.isEmpty) return;
    _onlineSub = repository.watchOnlineStatus(userIds: allUserIds).listen(
      (statusMap) =>
          add(GlobeOnlineStatusUpdated(onlineStatusMap: statusMap)),
    );
  }

  void _onPinTapped(GlobePinTapped event, Emitter<GlobeState> emit) {
    if (_currentData == null) return;
    final allUsers = [
      _currentData!.currentUser,
      ..._currentData!.matchedUsers,
      ..._currentData!.discoveryUsers,
    ];
    final user = allUsers.firstWhere(
      (u) => u.userId == event.tappedUserId,
      orElse: () => _currentData!.currentUser,
    );
    emit(GlobePinSelected(
      selectedUser: user,
      data: _currentData!,
      showMatched: _showMatched,
      showDiscovery: _showDiscovery,
    ));
  }

  void _onFilterToggled(
    GlobeFilterToggled event,
    Emitter<GlobeState> emit,
  ) {
    if (event.showMatched != null) _showMatched = event.showMatched!;
    if (event.showDiscovery != null) _showDiscovery = event.showDiscovery!;
    if (_currentData != null) {
      emit(GlobeLoaded(
        data: _currentData!,
        showMatched: _showMatched,
        showDiscovery: _showDiscovery,
      ));
    }
  }

  void _onFlyToCountry(GlobeFlyToCountry event, Emitter<GlobeState> emit) {
    if (_currentData != null) {
      emit(GlobeLoaded(
        data: _currentData!,
        showMatched: _showMatched,
        showDiscovery: _showDiscovery,
        flyToCountry: event.country,
      ));
    }
  }

  void _onCountryTapped(
    GlobeCountryTapped event,
    Emitter<GlobeState> emit,
  ) {
    if (_currentData == null) return;
    final normalized = normalizeCountryName(event.countryName);
    final matchesInCountry = _currentData!.matchedUsers
        .where(
            (u) => u.country.toLowerCase() == normalized.toLowerCase())
        .toList();
    emit(GlobeCountrySelected(
      countryName: normalized,
      matchesInCountry: matchesInCountry,
      data: _currentData!,
      showMatched: _showMatched,
      showDiscovery: _showDiscovery,
    ));
  }

  void _onMatchesUpdated(
    GlobeMatchesUpdated event,
    Emitter<GlobeState> emit,
  ) {
    if (_currentData == null) return;
    // The listeners' first snapshots (and unrelated match-doc edits) repeat
    // the pins already on screen; re-emitting reset the selection and
    // restarted the online-status listeners for nothing.
    if (_sameMatches(event.updatedMatches)) return;
    _currentData = GlobeData(
      currentUser: _currentData!.currentUser,
      matchedUsers: event.updatedMatches,
      discoveryUsers: _currentData!.discoveryUsers,
    );
    emit(GlobeLoaded(
      data: _currentData!,
      showMatched: _showMatched,
      showDiscovery: _showDiscovery,
    ));
    _startOnlineStream(_currentData!);
  }

  void _onOnlineStatusUpdated(
    GlobeOnlineStatusUpdated event,
    Emitter<GlobeState> emit,
  ) {
    if (_currentData == null) return;
    _currentData =
        _currentData!.copyWithOnlineStatus(event.onlineStatusMap);
    emit(GlobeLoaded(
      data: _currentData!,
      showMatched: _showMatched,
      showDiscovery: _showDiscovery,
    ));
  }

  @override
  Future<void> close() {
    _matchSub?.cancel();
    _onlineSub?.cancel();
    return super.close();
  }
}
