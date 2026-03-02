import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/explore_map_remote_datasource.dart';
import 'explore_map_event.dart';
import 'explore_map_state.dart';

/// BLoC for the Explore Map (Nearby Users) feature.
///
/// Manages loading nearby users, refreshing the list, and toggling
/// the user's "Show me on map" visibility preference.
class ExploreMapBloc extends Bloc<ExploreMapEvent, ExploreMapState> {
  final ExploreMapRemoteDataSource remoteDataSource;

  ExploreMapBloc({required this.remoteDataSource})
      : super(const ExploreMapInitial()) {
    on<LoadNearbyUsers>(_onLoadNearbyUsers);
    on<RefreshMap>(_onRefreshMap);
    on<ToggleShowOnMap>(_onToggleShowOnMap);
  }

  Future<void> _onLoadNearbyUsers(
    LoadNearbyUsers event,
    Emitter<ExploreMapState> emit,
  ) async {
    emit(const ExploreMapLoading());

    try {
      // Fetch the user's current showOnMap setting
      final showOnMap =
          await remoteDataSource.getUserMapSettings(event.userId);

      final users = await remoteDataSource.getNearbyUsers(
        latitude: event.latitude,
        longitude: event.longitude,
        radiusKm: event.radiusKm,
        currentUserId: event.userId,
        currentUserLanguages: event.currentUserLanguages,
      );

      debugPrint(
          '[ExploreMapBloc] Loaded ${users.length} nearby users (radius: ${event.radiusKm}km)');

      emit(ExploreMapLoaded(
        users: users,
        radiusKm: event.radiusKm,
        showOnMap: showOnMap,
      ));
    } catch (e) {
      debugPrint('[ExploreMapBloc] Error loading nearby users: $e');
      emit(ExploreMapError(e.toString()));
    }
  }

  Future<void> _onRefreshMap(
    RefreshMap event,
    Emitter<ExploreMapState> emit,
  ) async {
    // Keep current state visible while refreshing (no loading spinner)
    try {
      final showOnMap =
          await remoteDataSource.getUserMapSettings(event.userId);

      final users = await remoteDataSource.getNearbyUsers(
        latitude: event.latitude,
        longitude: event.longitude,
        radiusKm: event.radiusKm,
        currentUserId: event.userId,
        currentUserLanguages: event.currentUserLanguages,
      );

      emit(ExploreMapLoaded(
        users: users,
        radiusKm: event.radiusKm,
        showOnMap: showOnMap,
      ));
    } catch (e) {
      debugPrint('[ExploreMapBloc] Error refreshing map: $e');
      emit(ExploreMapError(e.toString()));
    }
  }

  Future<void> _onToggleShowOnMap(
    ToggleShowOnMap event,
    Emitter<ExploreMapState> emit,
  ) async {
    try {
      await remoteDataSource.updateShowOnMap(
        userId: event.userId,
        showOnMap: event.showOnMap,
      );

      // Update current state with new showOnMap value
      if (state is ExploreMapLoaded) {
        final current = state as ExploreMapLoaded;
        emit(ExploreMapLoaded(
          users: current.users,
          radiusKm: current.radiusKm,
          showOnMap: event.showOnMap,
        ));
      }
    } catch (e) {
      debugPrint('[ExploreMapBloc] Error toggling showOnMap: $e');
    }
  }
}
