/**
 * Claim Challenge Reward Use Case
 * Point 198: Claim rewards when completing challenges
 */

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/daily_challenge.dart';
import '../repositories/gamification_repository.dart';

class ClaimChallengeReward
    implements UseCase<ChallengeRewardClaimResult, ClaimChallengeRewardParams> {
  final GamificationRepository repository;

  ClaimChallengeReward(this.repository);

  @override
  Future<Either<Failure, ChallengeRewardClaimResult>> call(
    ClaimChallengeRewardParams params,
  ) async {
    // Get challenge progress
    final progressResult = await repository.getChallengeProgress(params.userId);

    if (progressResult.isLeft()) {
      return Left(progressResult.fold((l) => l, (r) => throw Exception()));
    }

    final allProgress = progressResult.fold(
      (l) => throw Exception(),
      (r) => r,
    );

    final progress = allProgress.firstWhere(
      (p) => p.challengeId == params.challengeId,
      orElse: () => UserChallengeProgress(
        userId: params.userId,
        challengeId: params.challengeId,
        progress: 0,
        requiredCount: 1,
        isCompleted: false,
        completedAt: null,
        createdAt: DateTime.now(),
      ),
    );

    // Check if challenge is completed
    if (!progress.canClaim) {
      if (progress.isCompleted) {
        return const Left(CacheFailure('Rewards already claimed'));
      } else if (progress.progress < progress.requiredCount) {
        return Left(CacheFailure(
          'Challenge not completed. Progress: ${progress.progress}/${progress.requiredCount}',
        ));
      }
    }

    // Claim the rewards
    final rewardsResult = await repository.claimChallengeReward(
      params.userId,
      params.challengeId,
    );

    if (rewardsResult.isLeft()) {
      return Left(rewardsResult.fold((l) => l, (r) => throw Exception()));
    }

    final rewards = rewardsResult.fold(
      (l) => throw Exception(),
      (r) => r,
    );

    // Get challenge details
    final allDailyChallenges = DailyChallenges.getRotatingChallenges();
    final allWeeklyChallenges = WeeklyChallenges.getWeeklyChallenges();

    final challenge = [...allDailyChallenges, ...allWeeklyChallenges].firstWhere(
      (c) => c.challengeId == params.challengeId,
      orElse: () => allDailyChallenges.first,
    );

    // Categorize rewards (Point 198)
    int totalXP = 0;
    int totalCoins = 0;
    final badges = <ChallengeReward>[];
    final items = <ChallengeReward>[];

    for (var reward in rewards) {
      switch (reward.type) {
        case 'xp':
          totalXP += reward.amount;
          break;
        case 'coins':
          totalCoins += reward.amount;
          break;
        case 'badge':
          badges.add(reward);
          break;
        case 'boost':
        case 'super_like':
          items.add(reward);
          break;
      }
    }

    return Right(ChallengeRewardClaimResult(
      challengeId: params.challengeId,
      challengeName: challenge.name,
      challengeType: challenge.type,
      rewards: rewards,
      totalXP: totalXP,
      totalCoins: totalCoins,
      badges: badges,
      items: items,
    ));
  }
}

class ClaimChallengeRewardParams {
  final String userId;
  final String challengeId;

  ClaimChallengeRewardParams({
    required this.userId,
    required this.challengeId,
  });
}

class ChallengeRewardClaimResult {
  final String challengeId;
  final String challengeName;
  final ChallengeType challengeType;
  final List<ChallengeReward> rewards;
  final int totalXP;
  final int totalCoins;
  final List<ChallengeReward> badges;
  final List<ChallengeReward> items;

  ChallengeRewardClaimResult({
    required this.challengeId,
    required this.challengeName,
    required this.challengeType,
    required this.rewards,
    required this.totalXP,
    required this.totalCoins,
    required this.badges,
    required this.items,
  });
}
