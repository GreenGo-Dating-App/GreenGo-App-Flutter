import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/spot.dart';
import '../../domain/entities/spot_review.dart';
import '../../domain/repositories/spots_repository.dart';
import '../datasources/spots_remote_datasource.dart';
import '../models/spot_model.dart';
import '../models/spot_review_model.dart';

/// Implementation of [SpotsRepository] that delegates to the remote
/// data source and wraps results in [Either] for error handling.
class SpotsRepositoryImpl implements SpotsRepository {
  final SpotsRemoteDataSource remoteDataSource;

  SpotsRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<Spot>>> getSpots({
    required String city,
    SpotCategory? category,
  }) async {
    try {
      final spots = await remoteDataSource.getSpots(
        city: city,
        category: category,
      );
      return Right(spots);
    } on ServerException catch (e) {
      debugPrint('[SpotsRepo] ServerException: ${e.message}');
      return Left(ServerFailure(e.message));
    } catch (e) {
      debugPrint('[SpotsRepo] Error: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Spot>> getSpotById(String id) async {
    try {
      final spot = await remoteDataSource.getSpotById(id);
      return Right(spot);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Spot>> createSpot(Spot spot) async {
    try {
      final model = SpotModel.fromEntity(spot);
      final created = await remoteDataSource.createSpot(model);
      return Right(created);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<SpotReview>>> getReviews(String spotId) async {
    try {
      final reviews = await remoteDataSource.getReviews(spotId);
      return Right(reviews);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SpotReview>> addReview(SpotReview review) async {
    try {
      final model = SpotReviewModel.fromEntity(review);
      final created = await remoteDataSource.addReview(model);
      return Right(created);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
