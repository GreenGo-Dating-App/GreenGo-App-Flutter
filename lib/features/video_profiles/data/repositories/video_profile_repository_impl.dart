import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/video_profile.dart';
import '../../domain/repositories/video_profile_repository.dart';
import '../datasources/video_profile_remote_datasource.dart';

/// Implementation of [VideoProfileRepository] using Firebase backend.
class VideoProfileRepositoryImpl implements VideoProfileRepository {
  final VideoProfileRemoteDataSource remoteDataSource;

  /// Optional callback for tracking upload progress (0.0 to 1.0).
  void Function(double progress)? onUploadProgress;

  VideoProfileRepositoryImpl({
    required this.remoteDataSource,
    this.onUploadProgress,
  });

  @override
  Future<Either<Failure, VideoProfile>> uploadVideoProfile(
    String userId,
    String filePath, {
    String? prompt,
  }) async {
    try {
      final result = await remoteDataSource.uploadVideoProfile(
        userId: userId,
        filePath: filePath,
        prompt: prompt,
        onProgress: onUploadProgress,
      );
      return Right(result);
    } on ValidationException catch (e) {
      return Left(ValidationFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      debugPrint('[VideoProfileRepo] Unexpected error uploading: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, VideoProfile?>> getVideoProfile(
      String userId) async {
    try {
      final result = await remoteDataSource.getVideoProfile(userId);
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      debugPrint('[VideoProfileRepo] Unexpected error getting profile: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteVideoProfile(String userId) async {
    try {
      await remoteDataSource.deleteVideoProfile(userId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      debugPrint('[VideoProfileRepo] Unexpected error deleting: $e');
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<VideoProfile>>> getVideoProfilesForDiscovery({
    int limit = 20,
    String? lastId,
  }) async {
    try {
      final result = await remoteDataSource.getVideoProfilesForDiscovery(
        limit: limit,
        lastId: lastId,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      debugPrint('[VideoProfileRepo] Unexpected error loading discovery: $e');
      return Left(ServerFailure(e.toString()));
    }
  }
}
