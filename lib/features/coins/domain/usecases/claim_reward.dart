import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/coin_reward.dart';
import '../entities/coin_transaction.dart';
import '../repositories/coin_repository.dart';

/// Claim Reward Use Case
/// Point 160: Claim coin rewards for achievements
class ClaimReward {
  final CoinRepository repository;

  ClaimReward(this.repository);

  Future<Either<Failure, CoinTransaction>> call({
    required String userId,
    required CoinReward reward,
    Map<String, dynamic>? metadata,
  }) async {
    return await repository.claimReward(
      userId: userId,
      reward: reward,
      metadata: metadata,
    );
  }
}

/// Check if Reward Can Be Claimed Use Case
class CanClaimReward {
  final CoinRepository repository;

  CanClaimReward(this.repository);

  Future<Either<Failure, bool>> call({
    required String userId,
    required String rewardId,
  }) async {
    return await repository.canClaimReward(
      userId: userId,
      rewardId: rewardId,
    );
  }
}

/// Get Claimed Rewards Use Case
class GetClaimedRewards {
  final CoinRepository repository;

  GetClaimedRewards(this.repository);

  Future<Either<Failure, List<ClaimedReward>>> call(String userId) async {
    return await repository.getClaimedRewards(userId);
  }
}
