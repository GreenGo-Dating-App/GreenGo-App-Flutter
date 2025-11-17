/**
 * Gamification Repository Interface
 * Points 176-200: Achievement, Level, and Challenge operations
 */

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/achievement.dart';
import '../entities/user_level.dart';
import '../entities/daily_challenge.dart';

abstract class GamificationRepository {
  // Achievement Operations (Points 176-185)

  /// Get all available achievements
  Future<Either<Failure, List<Achievement>>> getAllAchievements();

  /// Get user's achievement progress
  Future<Either<Failure, List<UserAchievementProgress>>> getUserAchievementProgress(
    String userId,
  );

  /// Get specific achievement progress
  Future<Either<Failure, UserAchievementProgress>> getAchievementProgress(
    String userId,
    String achievementId,
  );

  /// Unlock an achievement for a user
  Future<Either<Failure, UserAchievementProgress>> unlockAchievement(
    String userId,
    String achievementId,
  );

  /// Track achievement progress
  Future<Either<Failure, UserAchievementProgress>> trackAchievementProgress(
    String userId,
    String achievementId,
    int incrementBy,
  );

  /// Get user's unlocked achievements
  Future<Either<Failure, List<Achievement>>> getUnlockedAchievements(
    String userId,
  );

  // Level & XP Operations (Points 186-195)

  /// Get user's level data
  Future<Either<Failure, UserLevel>> getUserLevel(String userId);

  /// Grant XP to user (Point 187)
  Future<Either<Failure, UserLevel>> grantXP(
    String userId,
    int xpAmount,
    String reason,
  );

  /// Get XP transaction history
  Future<Either<Failure, List<XPTransaction>>> getXPHistory(
    String userId, {
    int limit = 50,
  });

  /// Get leaderboard (Point 191)
  Future<Either<Failure, List<LeaderboardEntry>>> getLeaderboard({
    LeaderboardType type = LeaderboardType.global,
    String? region,
    int limit = 100,
  });

  /// Get user's rank
  Future<Either<Failure, int>> getUserRank(
    String userId, {
    LeaderboardType type = LeaderboardType.global,
  });

  /// Get level rewards
  Future<Either<Failure, List<LevelReward>>> getLevelRewards(int level);

  /// Claim level rewards (Point 190)
  Future<Either<Failure, bool>> claimLevelRewards(
    String userId,
    int level,
  );

  /// Check VIP status (Point 193)
  Future<Either<Failure, bool>> checkVIPStatus(String userId);

  /// Check if feature is unlocked (Point 195)
  Future<Either<Failure, bool>> isFeatureUnlocked(
    String userId,
    String featureId,
  );

  // Daily Challenge Operations (Points 196-200)

  /// Get today's daily challenges (Point 196)
  Future<Either<Failure, List<DailyChallenge>>> getDailyChallenges(
    String userId,
  );

  /// Get user's challenge progress (Point 197)
  Future<Either<Failure, List<UserChallengeProgress>>> getChallengeProgress(
    String userId,
  );

  /// Track challenge progress
  Future<Either<Failure, UserChallengeProgress>> trackChallengeProgress(
    String userId,
    String challengeId,
    int incrementBy,
  );

  /// Claim challenge reward (Point 198)
  Future<Either<Failure, List<ChallengeReward>>> claimChallengeReward(
    String userId,
    String challengeId,
  );

  /// Get weekly mega-challenges (Point 199)
  Future<Either<Failure, List<DailyChallenge>>> getWeeklyChallenges(
    String userId,
  );

  /// Get active seasonal event (Point 200)
  Future<Either<Failure, SeasonalEvent?>> getActiveSeasonalEvent();

  /// Get seasonal event challenges
  Future<Either<Failure, List<DailyChallenge>>> getSeasonalChallenges(
    String userId,
    String eventId,
  );

  /// Apply seasonal theme (Point 200)
  Future<Either<Failure, Map<String, dynamic>>> getSeasonalThemeConfig();
}

/// Leaderboard types
enum LeaderboardType {
  global,
  regional,
  friends,
}
