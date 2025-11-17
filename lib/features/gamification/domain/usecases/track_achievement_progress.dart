/**
 * Track Achievement Progress Use Case
 * Points 176-185: Update achievement progress and auto-unlock when complete
 */

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/achievement.dart';
import '../repositories/gamification_repository.dart';

class TrackAchievementProgress
    implements UseCase<AchievementProgressResult, TrackAchievementProgressParams> {
  final GamificationRepository repository;

  TrackAchievementProgress(this.repository);

  @override
  Future<Either<Failure, AchievementProgressResult>> call(
    TrackAchievementProgressParams params,
  ) async {
    // Update progress
    final progressResult = await repository.trackAchievementProgress(
      params.userId,
      params.achievementId,
      params.incrementBy,
    );

    if (progressResult.isLeft()) {
      return Left(progressResult.fold((l) => l, (r) => throw Exception()));
    }

    final progress = progressResult.fold(
      (l) => throw Exception(),
      (r) => r,
    );

    // Check if achievement was just completed
    final wasJustCompleted = !progress.isUnlocked &&
        progress.progress >= progress.requiredCount;

    Achievement? achievement;
    if (wasJustCompleted) {
      // Get achievement details
      final allAchievements = Achievements.getAllAchievements();
      achievement = allAchievements.firstWhere(
        (a) => a.achievementId == params.achievementId,
      );
    }

    return Right(AchievementProgressResult(
      progress: progress,
      wasCompleted: wasJustCompleted,
      achievement: achievement,
    ));
  }
}

class TrackAchievementProgressParams {
  final String userId;
  final String achievementId;
  final int incrementBy;

  TrackAchievementProgressParams({
    required this.userId,
    required this.achievementId,
    this.incrementBy = 1,
  });
}

class AchievementProgressResult {
  final UserAchievementProgress progress;
  final bool wasCompleted;
  final Achievement? achievement;

  AchievementProgressResult({
    required this.progress,
    required this.wasCompleted,
    this.achievement,
  });
}
