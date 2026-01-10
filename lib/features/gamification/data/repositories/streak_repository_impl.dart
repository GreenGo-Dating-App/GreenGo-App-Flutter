import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/login_streak.dart';
import '../../domain/repositories/streak_repository.dart';
import '../datasources/streak_datasource.dart';

/// Implementation of StreakRepository
class StreakRepositoryImpl implements StreakRepository {
  final StreakRemoteDataSource remoteDataSource;

  StreakRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, LoginStreak?>> getStreak(String userId) async {
    try {
      final streak = await remoteDataSource.getStreak(userId);
      return Right(streak?.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, LoginStreak>> recordLogin(String userId) async {
    try {
      final streak = await remoteDataSource.recordLogin(userId);
      return Right(streak.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> claimMilestone(
    String userId,
    String milestoneId,
  ) async {
    try {
      await remoteDataSource.claimMilestone(userId, milestoneId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<LoginStreak?> watchStreak(String userId) {
    return remoteDataSource
        .watchStreak(userId)
        .map((model) => model?.toEntity());
  }
}
