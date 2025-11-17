/**
 * Claim Level Rewards Use Case
 * Point 190: Claim rewards when reaching new levels
 */

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_level.dart';
import '../repositories/gamification_repository.dart';

class ClaimLevelRewards implements UseCase<LevelRewardsClaimResult, ClaimLevelRewardsParams> {
  final GamificationRepository repository;

  ClaimLevelRewards(this.repository);

  @override
  Future<Either<Failure, LevelRewardsClaimResult>> call(
    ClaimLevelRewardsParams params,
  ) async {
    // Get user's level
    final levelResult = await repository.getUserLevel(params.userId);

    if (levelResult.isLeft()) {
      return Left(levelResult.fold((l) => l, (r) => throw Exception()));
    }

    final userLevel = levelResult.fold(
      (l) => throw Exception(),
      (r) => r,
    );

    // Check if user has reached the level
    if (userLevel.level < params.level) {
      return Left(CacheFailure(
        message: 'User has not reached level ${params.level} yet. Current level: ${userLevel.level}',
      ));
    }

    // Get rewards for the level
    final rewardsResult = await repository.getLevelRewards(params.level);

    if (rewardsResult.isLeft()) {
      return Left(rewardsResult.fold((l) => l, (r) => throw Exception()));
    }

    final rewards = rewardsResult.fold(
      (l) => throw Exception(),
      (r) => r,
    );

    if (rewards.isEmpty) {
      return Left(CacheFailure(message: 'No rewards available for level ${params.level}'));
    }

    // Claim the rewards
    final claimResult = await repository.claimLevelRewards(
      params.userId,
      params.level,
    );

    if (claimResult.isLeft()) {
      return Left(claimResult.fold((l) => l, (r) => throw Exception()));
    }

    final claimed = claimResult.fold(
      (l) => throw Exception(),
      (r) => r,
    );

    if (!claimed) {
      return Left(CacheFailure(message: 'Failed to claim rewards'));
    }

    // Categorize rewards
    final coins = rewards
        .where((r) => r.type == 'coins')
        .fold<int>(0, (sum, r) => sum + (r.amount ?? 0));

    final items = rewards
        .where((r) => ['frame', 'badge', 'theme'].contains(r.type))
        .toList();

    final features = rewards
        .where((r) => r.type == 'feature')
        .toList();

    return Right(LevelRewardsClaimResult(
      level: params.level,
      rewards: rewards,
      totalCoins: coins,
      itemsUnlocked: items,
      featuresUnlocked: features,
    ));
  }
}

class ClaimLevelRewardsParams {
  final String userId;
  final int level;

  ClaimLevelRewardsParams({
    required this.userId,
    required this.level,
  });
}

class LevelRewardsClaimResult {
  final int level;
  final List<LevelReward> rewards;
  final int totalCoins;
  final List<LevelReward> itemsUnlocked;
  final List<LevelReward> featuresUnlocked;

  LevelRewardsClaimResult({
    required this.level,
    required this.rewards,
    required this.totalCoins,
    required this.itemsUnlocked,
    required this.featuresUnlocked,
  });
}
