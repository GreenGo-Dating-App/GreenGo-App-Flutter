import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/blind_date.dart';
import '../../domain/repositories/blind_date_repository.dart';
import '../datasources/blind_date_remote_datasource.dart';
import '../models/blind_date_model.dart';

/// Implementation of BlindDateRepository
class BlindDateRepositoryImpl implements BlindDateRepository {
  final BlindDateRemoteDataSource remoteDataSource;

  BlindDateRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, BlindDateProfile>> createBlindProfile(
    String userId,
  ) async {
    try {
      final profile = await remoteDataSource.createBlindProfile(userId);
      return Right(profile);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, BlindDateProfile?>> getBlindProfile(
    String userId,
  ) async {
    try {
      final profile = await remoteDataSource.getBlindProfile(userId);
      return Right(profile);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deactivateBlindProfile(String userId) async {
    try {
      await remoteDataSource.deactivateBlindProfile(userId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<BlindProfileView>>> getBlindCandidates({
    required String userId,
    int limit = 10,
  }) async {
    try {
      final candidates = await remoteDataSource.getBlindCandidates(
        userId: userId,
        limit: limit,
      );
      return Right(candidates);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, BlindLikeResult>> likeBlindProfile({
    required String userId,
    required String targetUserId,
  }) async {
    try {
      final result = await remoteDataSource.likeBlindProfile(
        userId: userId,
        targetUserId: targetUserId,
      );
      return Right(result);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> passBlindProfile({
    required String userId,
    required String targetUserId,
  }) async {
    try {
      await remoteDataSource.passBlindProfile(
        userId: userId,
        targetUserId: targetUserId,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<BlindMatch>>> getBlindMatches(
    String userId,
  ) async {
    try {
      final matches = await remoteDataSource.getBlindMatches(userId);
      return Right(matches);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<BlindMatch>>> streamBlindMatches(String userId) {
    return remoteDataSource.streamBlindMatches(userId).map(
          (matches) => Right<Failure, List<BlindMatch>>(matches),
        );
  }

  @override
  Future<Either<Failure, BlindMatch>> instantReveal({
    required String userId,
    required String matchId,
  }) async {
    try {
      final match = await remoteDataSource.instantReveal(
        userId: userId,
        matchId: matchId,
      );
      return Right(match);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> checkRevealStatus(String matchId) async {
    try {
      final isRevealed = await remoteDataSource.checkRevealStatus(matchId);
      return Right(isRevealed);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, BlindMatch>> updateMessageCount({
    required String matchId,
    required int newCount,
  }) async {
    try {
      final match = await remoteDataSource.updateMessageCount(
        matchId: matchId,
        newCount: newCount,
      );
      return Right(match);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, BlindProfileView>> getRevealedProfile({
    required String matchId,
    required String userId,
  }) async {
    try {
      final profile = await remoteDataSource.getRevealedProfile(
        matchId: matchId,
        userId: userId,
      );
      return Right(profile);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
