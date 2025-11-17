/**
 * Unlock Achievement Use Case
 * Points 176-185: Unlock achievements and grant rewards
 */

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/achievement.dart';
import '../repositories/gamification_repository.dart';

class UnlockAchievement implements UseCase<AchievementUnlockResult, UnlockAchievementParams> {
  final GamificationRepository repository;

  UnlockAchievement(this.repository);

  @override
  Future<Either<Failure, AchievementUnlockResult>> call(
    UnlockAchievementParams params,
  ) async {
    // Check current progress
    final progressResult = await repository.getAchievementProgress(
      params.userId,
      params.achievementId,
    );

    if (progressResult.isLeft()) {
      return Left(progressResult.fold((l) => l, (r) => throw Exception()));
    }

    final progress = progressResult.fold(
      (l) => throw Exception(),
      (r) => r,
    );

    // Check if already unlocked
    if (progress.isUnlocked) {
      return Left(CacheFailure(message: 'Achievement already unlocked'));
    }

    // Check if progress is sufficient
    if (progress.progress < progress.requiredCount) {
      return Left(CacheFailure(
        message: 'Achievement requirements not met. Progress: ${progress.progress}/${progress.requiredCount}',
      ));
    }

    // Unlock the achievement
    final unlockResult = await repository.unlockAchievement(
      params.userId,
      params.achievementId,
    );

    if (unlockResult.isLeft()) {
      return Left(unlockResult.fold((l) => l, (r) => throw Exception()));
    }

    final unlockedProgress = unlockResult.fold(
      (l) => throw Exception(),
      (r) => r,
    );

    // Get achievement details for rewards
    final allAchievements = Achievements.getAllAchievements();
    final achievement = allAchievements.firstWhere(
      (a) => a.achievementId == params.achievementId,
    );

    return Right(AchievementUnlockResult(
      achievement: achievement,
      progress: unlockedProgress,
      rewardsGranted: [
        AchievementRewardGranted(
          type: achievement.rewardType,
          amount: achievement.rewardAmount,
        ),
      ],
    ));
  }
}

class UnlockAchievementParams {
  final String userId;
  final String achievementId;

  UnlockAchievementParams({
    required this.userId,
    required this.achievementId,
  });
}

class AchievementUnlockResult {
  final Achievement achievement;
  final UserAchievementProgress progress;
  final List<AchievementRewardGranted> rewardsGranted;

  AchievementUnlockResult({
    required this.achievement,
    required this.progress,
    required this.rewardsGranted,
  });
}

class AchievementRewardGranted {
  final String type; // xp, coins, badge
  final int amount;

  AchievementRewardGranted({
    required this.type,
    required this.amount,
  });
}
