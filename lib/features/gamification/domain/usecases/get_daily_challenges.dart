/**
 * Get Daily Challenges Use Case
 * Point 196: Get today's rotating daily challenges
 * Point 199: Get weekly mega-challenges
 */

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/daily_challenge.dart';
import '../repositories/gamification_repository.dart';

class GetDailyChallenges implements UseCase<DailyChallengesData, String> {
  final GamificationRepository repository;

  GetDailyChallenges(this.repository);

  @override
  Future<Either<Failure, DailyChallengesData>> call(String userId) async {
    // Get daily challenges
    final dailyChallengesResult = await repository.getDailyChallenges(userId);

    if (dailyChallengesResult.isLeft()) {
      return Left(dailyChallengesResult.fold((l) => l, (r) => throw Exception()));
    }

    // Get weekly challenges (Point 199)
    final weeklyChallengesResult = await repository.getWeeklyChallenges(userId);

    if (weeklyChallengesResult.isLeft()) {
      return Left(weeklyChallengesResult.fold((l) => l, (r) => throw Exception()));
    }

    // Get user's progress for all challenges (Point 197)
    final progressResult = await repository.getChallengeProgress(userId);

    if (progressResult.isLeft()) {
      return Left(progressResult.fold((l) => l, (r) => throw Exception()));
    }

    final dailyChallenges = dailyChallengesResult.fold(
      (l) => throw Exception(),
      (r) => r,
    );

    final weeklyChallenges = weeklyChallengesResult.fold(
      (l) => throw Exception(),
      (r) => r,
    );

    final progress = progressResult.fold(
      (l) => throw Exception(),
      (r) => r,
    );

    // Map progress to challenges
    final progressMap = {
      for (var p in progress) p.challengeId: p,
    };

    final dailyWithProgress = dailyChallenges.map((challenge) {
      final challengeProgress = progressMap[challenge.challengeId];
      return ChallengeWithProgress(
        challenge: challenge,
        progress: challengeProgress,
      );
    }).toList();

    final weeklyWithProgress = weeklyChallenges.map((challenge) {
      final challengeProgress = progressMap[challenge.challengeId];
      return ChallengeWithProgress(
        challenge: challenge,
        progress: challengeProgress,
      );
    }).toList();

    // Calculate statistics
    final totalDaily = dailyWithProgress.length;
    final completedDaily = dailyWithProgress.where((c) => c.isCompleted).length;
    final canClaimDaily = dailyWithProgress.where((c) => c.canClaim).length;

    final totalWeekly = weeklyWithProgress.length;
    final completedWeekly = weeklyWithProgress.where((c) => c.isCompleted).length;
    final canClaimWeekly = weeklyWithProgress.where((c) => c.canClaim).length;

    // Calculate potential rewards
    int totalXPAvailable = 0;
    int totalCoinsAvailable = 0;

    for (var c in [...dailyWithProgress, ...weeklyWithProgress]) {
      if (!c.isCompleted) {
        for (var reward in c.challenge.rewards) {
          if (reward.type == 'xp') totalXPAvailable += reward.amount;
          if (reward.type == 'coins') totalCoinsAvailable += reward.amount;
        }
      }
    }

    return Right(DailyChallengesData(
      dailyChallenges: dailyWithProgress,
      weeklyChallenges: weeklyWithProgress,
      totalDaily: totalDaily,
      completedDaily: completedDaily,
      canClaimDaily: canClaimDaily,
      totalWeekly: totalWeekly,
      completedWeekly: completedWeekly,
      canClaimWeekly: canClaimWeekly,
      totalXPAvailable: totalXPAvailable,
      totalCoinsAvailable: totalCoinsAvailable,
    ));
  }
}

class ChallengeWithProgress {
  final DailyChallenge challenge;
  final UserChallengeProgress? progress;

  ChallengeWithProgress({
    required this.challenge,
    this.progress,
  });

  bool get isCompleted => progress?.isCompleted ?? false;
  bool get canClaim => progress?.canClaim ?? false;
  int get currentProgress => progress?.progress ?? 0;
  double get progressPercentage => progress?.progressPercentage ?? 0.0;
}

class DailyChallengesData {
  final List<ChallengeWithProgress> dailyChallenges;
  final List<ChallengeWithProgress> weeklyChallenges;
  final int totalDaily;
  final int completedDaily;
  final int canClaimDaily;
  final int totalWeekly;
  final int completedWeekly;
  final int canClaimWeekly;
  final int totalXPAvailable;
  final int totalCoinsAvailable;

  DailyChallengesData({
    required this.dailyChallenges,
    required this.weeklyChallenges,
    required this.totalDaily,
    required this.completedDaily,
    required this.canClaimDaily,
    required this.totalWeekly,
    required this.completedWeekly,
    required this.canClaimWeekly,
    required this.totalXPAvailable,
    required this.totalCoinsAvailable,
  });
}
