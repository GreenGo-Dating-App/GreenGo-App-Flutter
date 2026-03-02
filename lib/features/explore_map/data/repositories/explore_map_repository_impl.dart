import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/map_user.dart';
import '../../domain/repositories/explore_map_repository.dart';
import '../datasources/explore_map_remote_datasource.dart';

/// Implementation of [ExploreMapRepository] that delegates to the remote
/// data source and wraps results in [Either] for error handling.
class ExploreMapRepositoryImpl implements ExploreMapRepository {
  final ExploreMapRemoteDataSource remoteDataSource;

  ExploreMapRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<MapUser>>> getNearbyUsers({
    required double latitude,
    required double longitude,
    required double radiusKm,
    required String currentUserId,
  }) async {
    try {
      final users = await remoteDataSource.getNearbyUsers(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
        currentUserId: currentUserId,
      );
      return Right(users);
    } on ServerException catch (e) {
      debugPrint('[ExploreMapRepo] ServerException: ${e.message}');
      return Left(ServerFailure(e.message));
    } catch (e) {
      debugPrint('[ExploreMapRepo] Error: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> getUserMapSettings(String userId) async {
    try {
      final showOnMap = await remoteDataSource.getUserMapSettings(userId);
      return Right(showOnMap);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateShowOnMap({
    required String userId,
    required bool showOnMap,
  }) async {
    try {
      await remoteDataSource.updateShowOnMap(
        userId: userId,
        showOnMap: showOnMap,
      );
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
