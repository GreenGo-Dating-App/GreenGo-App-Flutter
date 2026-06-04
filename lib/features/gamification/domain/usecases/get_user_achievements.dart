/// Get User Achievements Use Case
/// Points 176-185: Retrieve user's achievement progress
library;

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/achievement.dart';
import '../repositories/gamification_repository.dart';

class GetUserAchievements implements UseCase<UserAchievementsData, String> {

  GetUserAchievements(this.repository);
  final GamificationRepository repository;

  @override
  Future<Either<Failure, UserAchievementsData>> call(String userId) async {
    // Get all achievements
    final allAchievementsResult = await repository.getAllAchievements();
    if (allAchievementsResult.isLeft()) {
      return Left(allAchievementsResult.fold((l) => l, (r) => throw Exception()));
    }

    // Get user's progress
    final progressResult = await repository.getUserAchievementProgress(userId);
    if (progressResult.isLeft()) {
      return Left(progressResult.fold((l) => l, (r) => throw Exception()));
    }

    final allAchievements = allAchievementsResult.fold(
      (l) => throw Exception(),
      (r) => r,
    );
    final userProgress = progressResult.fold(
      (l) => throw Exception(),
      (r) => r,
    );

    // Map progress to achievements
    final progressMap = {
      for (final p in userProgress) p.achievementId: p,
    };

    final achievementsWithProgress = allAchievements.map((achievement) {
      final progress = progressMap[achievement.achievementId];
      return AchievementWithProgress(
        achievement: achievement,
        progress: progress,
      );
    }).toList();

    // Group by category
    final byCategory = <AchievementCategory, List<AchievementWithProgress>>{};
    for (final category in AchievementCategory.values) {
      byCategory[category] = achievementsWithProgress
          .where((a) => a.achievement.category == category)
          .toList();
    }

    // Calculate statistics
    final totalAchievements = allAchievements.length;
    final unlockedCount = userProgress.where((p) => p.isUnlocked).length;
    final progressPercentage = (unlockedCount / totalAchievements * 100).round();

    return Right(UserAchievementsData(
      allAchievements: achievementsWithProgress,
      byCategory: byCategory,
      totalAchievements: totalAchievements,
      unlockedCount: unlockedCount,
      progressPercentage: progressPercentage,
    ));
  }
}

/// Achievement with user progress
class AchievementWithProgress {

  AchievementWithProgress({
    required this.achievement,
    this.progress,
  });
  final Achievement achievement;
  final UserAchievementProgress? progress;

  bool get isUnlocked => progress?.isUnlocked ?? false;
  double get progressPercentage => progress?.progressPercentage ?? 0.0;
  int get currentProgress => progress?.progress ?? 0;
}

/// User achievements data
class UserAchievementsData {

  UserAchievementsData({
    required this.allAchievements,
    required this.byCategory,
    required this.totalAchievements,
    required this.unlockedCount,
    required this.progressPercentage,
  });
  final List<AchievementWithProgress> allAchievements;
  final Map<AchievementCategory, List<AchievementWithProgress>> byCategory;
  final int totalAchievements;
  final int unlockedCount;
  final int progressPercentage;
}
