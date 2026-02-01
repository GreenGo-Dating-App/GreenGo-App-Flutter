import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/vibe_tag.dart';
import '../../domain/repositories/vibe_tag_repository.dart';
import '../datasources/vibe_tag_remote_datasource.dart';

/// Vibe Tag Repository Implementation
class VibeTagRepositoryImpl implements VibeTagRepository {
  final VibeTagRemoteDataSource remoteDataSource;

  VibeTagRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, List<VibeTag>>> getVibeTags() async {
    try {
      final tags = await remoteDataSource.getVibeTags();
      return Right(tags);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<VibeTag>>> getVibeTagsByCategory(
      String category) async {
    try {
      final tags = await remoteDataSource.getVibeTagsByCategory(category);
      return Right(tags);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserVibeTags>> getUserVibeTags(String userId) async {
    try {
      final tags = await remoteDataSource.getUserVibeTags(userId);
      return Right(tags);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, UserVibeTags>> streamUserVibeTags(String userId) {
    return remoteDataSource.streamUserVibeTags(userId).map((tags) {
      return Right(tags);
    }).handleError((e) {
      return Left(ServerFailure(e.toString()));
    });
  }

  @override
  Future<Either<Failure, UserVibeTags>> updateUserVibeTags({
    required String userId,
    required List<String> tagIds,
  }) async {
    try {
      final tags = await remoteDataSource.updateUserVibeTags(
        userId: userId,
        tagIds: tagIds,
      );
      return Right(tags);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserVibeTags>> setTemporaryVibeTag({
    required String userId,
    required String tagId,
  }) async {
    try {
      final tags = await remoteDataSource.setTemporaryVibeTag(
        userId: userId,
        tagId: tagId,
      );
      return Right(tags);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserVibeTags>> removeVibeTag({
    required String userId,
    required String tagId,
  }) async {
    try {
      final tags = await remoteDataSource.removeVibeTag(
        userId: userId,
        tagId: tagId,
      );
      return Right(tags);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<String>>> searchUsersByVibeTags({
    required List<String> tagIds,
    int limit = 20,
    String? lastUserId,
  }) async {
    try {
      final userIds = await remoteDataSource.searchUsersByVibeTags(
        tagIds: tagIds,
        limit: limit,
        lastUserId: lastUserId,
      );
      return Right(userIds);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, VibeTag>> getVibeTagById(String tagId) async {
    try {
      final tag = await remoteDataSource.getVibeTagById(tagId);
      return Right(tag);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
