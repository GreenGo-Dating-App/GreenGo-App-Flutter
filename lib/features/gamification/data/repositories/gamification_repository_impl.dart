/**
 * Gamification Repository Implementation
 * Points 176-200: Repository implementation with error handling
 */

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/achievement.dart';
import '../../domain/entities/user_level.dart';
import '../../domain/entities/daily_challenge.dart';
import '../../domain/repositories/gamification_repository.dart';
import '../datasources/gamification_remote_datasource.dart';

class GamificationRepositoryImpl implements GamificationRepository {
  final GamificationRemoteDataSource remoteDataSource;

  GamificationRepositoryImpl({
    required this.remoteDataSource,
  });

  // ===== Achievement Operations =====

  @override
  Future<Either<Failure, List<Achievement>>> getAllAchievements() async {
    try {
      final achievements = await remoteDataSource.getAllAchievements();
      return Right(achievements);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<UserAchievementProgress>>>
      getUserAchievementProgress(String userId) async {
    try {
      final progress = await remoteDataSource.getUserAchievementProgress(userId);
      return Right(progress);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserAchievementProgress>> getAchievementProgress(
    String userId,
    String achievementId,
  ) async {
    try {
      final progress = await remoteDataSource.getAchievementProgress(
        userId,
        achievementId,
      );
      return Right(progress);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserAchievementProgress>> unlockAchievement(
    String userId,
    String achievementId,
  ) async {
    try {
      final progress = await remoteDataSource.unlockAchievement(
        userId,
        achievementId,
      );
      return Right(progress);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserAchievementProgress>> trackAchievementProgress(
    String userId,
    String achievementId,
    int incrementBy,
  ) async {
    try {
      final progress = await remoteDataSource.trackAchievementProgress(
        userId,
        achievementId,
        incrementBy,
      );
      return Right(progress);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Achievement>>> getUnlockedAchievements(
    String userId,
  ) async {
    try {
      final allAchievements = await remoteDataSource.getAllAchievements();
      final progress = await remoteDataSource.getUserAchievementProgress(userId);

      final unlockedIds = progress
          .where((p) => p.isUnlocked)
          .map((p) => p.achievementId)
          .toSet();

      final unlockedAchievements = allAchievements
          .where((a) => unlockedIds.contains(a.achievementId))
          .toList();

      return Right(unlockedAchievements);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ===== Level & XP Operations =====

  @override
  Future<Either<Failure, UserLevel>> getUserLevel(String userId) async {
    try {
      final level = await remoteDataSource.getUserLevel(userId);
      return Right(level);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserLevel>> grantXP(
    String userId,
    int xpAmount,
    String reason,
  ) async {
    try {
      final level = await remoteDataSource.grantXP(userId, xpAmount, reason);
      return Right(level);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<XPTransaction>>> getXPHistory(
    String userId, {
    int limit = 50,
  }) async {
    try {
      final history = await remoteDataSource.getXPHistory(userId, limit);
      return Right(history);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<LeaderboardEntry>>> getLeaderboard({
    LeaderboardType type = LeaderboardType.global,
    String? region,
    int limit = 100,
  }) async {
    try {
      final leaderboard = await remoteDataSource.getLeaderboard(
        type: type,
        region: region,
        limit: limit,
      );
      return Right(leaderboard);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> getUserRank(
    String userId, {
    LeaderboardType type = LeaderboardType.global,
  }) async {
    try {
      final rank = await remoteDataSource.getUserRank(userId, type);
      return Right(rank);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<LevelReward>>> getLevelRewards(int level) async {
    try {
      final rewards = await remoteDataSource.getLevelRewards(level);
      return Right(rewards);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> claimLevelRewards(
    String userId,
    int level,
  ) async {
    try {
      final claimed = await remoteDataSource.claimLevelRewards(userId, level);
      return Right(claimed);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> checkVIPStatus(String userId) async {
    try {
      final isVIP = await remoteDataSource.checkVIPStatus(userId);
      return Right(isVIP);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isFeatureUnlocked(
    String userId,
    String featureId,
  ) async {
    try {
      final isUnlocked = await remoteDataSource.isFeatureUnlocked(
        userId,
        featureId,
      );
      return Right(isUnlocked);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  // ===== Challenge Operations =====

  @override
  Future<Either<Failure, List<DailyChallenge>>> getDailyChallenges(
    String userId,
  ) async {
    try {
      final challenges = await remoteDataSource.getDailyChallenges(userId);
      return Right(challenges);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<UserChallengeProgress>>> getChallengeProgress(
    String userId,
  ) async {
    try {
      final progress = await remoteDataSource.getChallengeProgress(userId);
      return Right(progress);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserChallengeProgress>> trackChallengeProgress(
    String userId,
    String challengeId,
    int incrementBy,
  ) async {
    try {
      final progress = await remoteDataSource.trackChallengeProgress(
        userId,
        challengeId,
        incrementBy,
      );
      return Right(progress);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ChallengeReward>>> claimChallengeReward(
    String userId,
    String challengeId,
  ) async {
    try {
      final rewards = await remoteDataSource.claimChallengeReward(
        userId,
        challengeId,
      );
      return Right(rewards);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DailyChallenge>>> getWeeklyChallenges(
    String userId,
  ) async {
    try {
      final challenges = await remoteDataSource.getWeeklyChallenges(userId);
      return Right(challenges);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SeasonalEvent?>> getActiveSeasonalEvent() async {
    try {
      final event = await remoteDataSource.getActiveSeasonalEvent();
      return Right(event);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<DailyChallenge>>> getSeasonalChallenges(
    String userId,
    String eventId,
  ) async {
    try {
      final challenges = await remoteDataSource.getSeasonalChallenges(
        userId,
        eventId,
      );
      return Right(challenges);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getSeasonalThemeConfig() async {
    try {
      final themeConfig = await remoteDataSource.getSeasonalThemeConfig();
      return Right(themeConfig);
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
