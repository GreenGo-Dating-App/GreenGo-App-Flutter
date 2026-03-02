import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/datasources/spots_remote_datasource.dart';
import '../../data/models/spot_model.dart';
import '../../data/models/spot_review_model.dart';
import 'spots_event.dart';
import 'spots_state.dart';

/// BLoC for the Cultural Spots feature.
///
/// Handles loading spots by city/category, loading spot details with
/// reviews, creating new spots, and adding reviews.
class SpotsBloc extends Bloc<SpotsEvent, SpotsState> {
  final SpotsRemoteDataSource remoteDataSource;

  SpotsBloc({required this.remoteDataSource}) : super(const SpotsInitial()) {
    on<LoadSpots>(_onLoadSpots);
    on<LoadSpotById>(_onLoadSpotById);
    on<CreateSpot>(_onCreateSpot);
    on<AddReview>(_onAddReview);
  }

  Future<void> _onLoadSpots(
    LoadSpots event,
    Emitter<SpotsState> emit,
  ) async {
    emit(const SpotsLoading());

    try {
      final spots = await remoteDataSource.getSpots(
        city: event.city,
        category: event.category,
      );

      debugPrint('[SpotsBloc] Loaded ${spots.length} spots in ${event.city}');

      emit(SpotsLoaded(
        spots: spots,
        city: event.city,
        selectedCategory: event.category,
      ));
    } catch (e) {
      debugPrint('[SpotsBloc] Error loading spots: $e');
      emit(SpotsError(e.toString()));
    }
  }

  Future<void> _onLoadSpotById(
    LoadSpotById event,
    Emitter<SpotsState> emit,
  ) async {
    emit(const SpotsLoading());

    try {
      final spot = await remoteDataSource.getSpotById(event.spotId);
      final reviews = await remoteDataSource.getReviews(event.spotId);

      debugPrint(
          '[SpotsBloc] Loaded spot ${spot.name} with ${reviews.length} reviews');

      emit(SpotDetailLoaded(spot: spot, reviews: reviews));
    } catch (e) {
      debugPrint('[SpotsBloc] Error loading spot detail: $e');
      emit(SpotsError(e.toString()));
    }
  }

  Future<void> _onCreateSpot(
    CreateSpot event,
    Emitter<SpotsState> emit,
  ) async {
    try {
      final model = SpotModel.fromEntity(event.spot);
      final created = await remoteDataSource.createSpot(model);

      debugPrint('[SpotsBloc] Created spot: ${created.name}');

      emit(SpotCreated(spot: created));
    } catch (e) {
      debugPrint('[SpotsBloc] Error creating spot: $e');
      emit(SpotsError(e.toString()));
    }
  }

  Future<void> _onAddReview(
    AddReview event,
    Emitter<SpotsState> emit,
  ) async {
    try {
      final model = SpotReviewModel.fromEntity(event.review);
      final created = await remoteDataSource.addReview(model);

      debugPrint('[SpotsBloc] Added review by ${created.userName}');

      emit(ReviewAdded(review: created));

      // Reload the spot detail to show updated rating and new review
      add(LoadSpotById(spotId: event.review.spotId));
    } catch (e) {
      debugPrint('[SpotsBloc] Error adding review: $e');
      emit(SpotsError(e.toString()));
    }
  }
}
