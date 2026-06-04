/// Claim Level Rewards Use Case
/// Point 190: Claim rewards when reaching new levels
library;

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_level.dart';
import '../repositories/gamification_repository.dart';

class ClaimLevelRewards implements UseCase<LevelRewardsClaimResult, ClaimLevelRewardsParams> {

  ClaimLevelRewards(this.repository);
  final GamificationRepository repository;

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
        'User has not reached level ${params.level} yet. Current level: ${userLevel.level}',
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
      return Left(CacheFailure('No rewards available for level ${params.level}'));
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
      return const Left(CacheFailure('Failed to claim rewards'));
    }

    // Categorize rewards - count coin rewards
    final coinRewards = rewards.where((r) => r.type == 'coins').toList();
    // Parse coin amounts from the name (e.g., "50 Bonus Coins" -> 50)
    var coins = 0;
    for (final reward in coinRewards) {
      final match = RegExp(r'(\d+)').firstMatch(reward.name);
      if (match != null) {
        coins += int.tryParse(match.group(1) ?? '0') ?? 0;
      }
    }

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

  ClaimLevelRewardsParams({
    required this.userId,
    required this.level,
  });
  final String userId;
  final int level;
}

class LevelRewardsClaimResult {

  LevelRewardsClaimResult({
    required this.level,
    required this.rewards,
    required this.totalCoins,
    required this.itemsUnlocked,
    required this.featuresUnlocked,
  });
  final int level;
  final List<LevelReward> rewards;
  final int totalCoins;
  final List<LevelReward> itemsUnlocked;
  final List<LevelReward> featuresUnlocked;
}
