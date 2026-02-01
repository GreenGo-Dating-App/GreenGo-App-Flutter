/**
 * Grant XP Use Case
 * Point 187: Grant XP to users for various actions
 */

import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_level.dart';
import '../repositories/gamification_repository.dart';

class GrantXP implements UseCase<XPGrantResult, GrantXPParams> {
  final GamificationRepository repository;

  GrantXP(this.repository);

  @override
  Future<Either<Failure, XPGrantResult>> call(GrantXPParams params) async {
    // Get current level before granting XP
    final currentLevelResult = await repository.getUserLevel(params.userId);

    if (currentLevelResult.isLeft()) {
      return Left(currentLevelResult.fold((l) => l, (r) => throw Exception()));
    }

    final oldLevel = currentLevelResult.fold(
      (l) => throw Exception(),
      (r) => r,
    );

    // Grant XP
    final newLevelResult = await repository.grantXP(
      params.userId,
      params.xpAmount,
      params.reason,
    );

    if (newLevelResult.isLeft()) {
      return Left(newLevelResult.fold((l) => l, (r) => throw Exception()));
    }

    final newLevel = newLevelResult.fold(
      (l) => throw Exception(),
      (r) => r,
    );

    // Check if user leveled up
    final leveledUp = newLevel.level > oldLevel.level;
    final levelsGained = newLevel.level - oldLevel.level;

    // Get rewards if leveled up (Point 190)
    List<LevelReward>? rewards;
    if (leveledUp) {
      // Get rewards for all levels gained
      final rewardsList = <LevelReward>[];
      for (var level = oldLevel.level + 1; level <= newLevel.level; level++) {
        final levelRewardsResult = await repository.getLevelRewards(level);
        if (levelRewardsResult.isRight()) {
          final levelRewards = levelRewardsResult.fold(
            (l) => <LevelReward>[],
            (r) => r,
          );
          rewardsList.addAll(levelRewards);
        }
      }
      rewards = rewardsList;
    }

    // Check if VIP status was achieved (Point 193: Level 50+)
    final becameVIP = !oldLevel.isVIP && newLevel.isVIP;

    return Right(XPGrantResult(
      oldLevel: oldLevel,
      newLevel: newLevel,
      xpGranted: params.xpAmount,
      reason: params.reason,
      leveledUp: leveledUp,
      levelsGained: levelsGained,
      rewards: rewards ?? [],
      becameVIP: becameVIP,
    ));
  }
}

class GrantXPParams {
  final String userId;
  final int xpAmount;
  final String reason;

  GrantXPParams({
    required this.userId,
    required this.xpAmount,
    required this.reason,
  });

  /// Factory methods for common XP grants (Point 187)
  factory GrantXPParams.profileView(String userId) {
    return GrantXPParams(
      userId: userId,
      xpAmount: XPActions.profileView.xpAmount,
      reason: 'profile_view',
    );
  }

  factory GrantXPParams.match(String userId) {
    return GrantXPParams(
      userId: userId,
      xpAmount: XPActions.match.xpAmount,
      reason: 'match',
    );
  }

  factory GrantXPParams.messageSent(String userId) {
    return GrantXPParams(
      userId: userId,
      xpAmount: XPActions.messageSent.xpAmount,
      reason: 'message_sent',
    );
  }

  factory GrantXPParams.videoCall(String userId) {
    return GrantXPParams(
      userId: userId,
      xpAmount: XPActions.videoCall.xpAmount,
      reason: 'video_call',
    );
  }

  factory GrantXPParams.dailyLogin(String userId) {
    return GrantXPParams(
      userId: userId,
      xpAmount: XPActions.dailyLogin.xpAmount,
      reason: 'daily_login',
    );
  }

  factory GrantXPParams.photoUploaded(String userId) {
    return GrantXPParams(
      userId: userId,
      xpAmount: XPActions.photoAdded.xpAmount,
      reason: 'photo_uploaded',
    );
  }

  factory GrantXPParams.profileCompleted(String userId) {
    return GrantXPParams(
      userId: userId,
      xpAmount: XPActions.profileVerified.xpAmount,
      reason: 'profile_completed',
    );
  }

  factory GrantXPParams.superLikeSent(String userId) {
    return GrantXPParams(
      userId: userId,
      xpAmount: XPActions.superLike.xpAmount,
      reason: 'super_like_sent',
    );
  }

  factory GrantXPParams.subscriptionPurchased(String userId) {
    return GrantXPParams(
      userId: userId,
      xpAmount: XPActions.subscriptionPurchased.xpAmount,
      reason: 'subscription_purchased',
    );
  }

  factory GrantXPParams.achievementUnlocked(String userId) {
    return GrantXPParams(
      userId: userId,
      xpAmount: 25, // Fixed XP for achievement unlock
      reason: 'achievement_unlocked',
    );
  }

  factory GrantXPParams.challengeCompleted(String userId) {
    return GrantXPParams(
      userId: userId,
      xpAmount: XPActions.dailyChallengeCompleted.xpAmount,
      reason: 'challenge_completed',
    );
  }

  factory GrantXPParams.referralSuccess(String userId) {
    return GrantXPParams(
      userId: userId,
      xpAmount: 50, // Fixed XP for referral
      reason: 'referral_success',
    );
  }

  factory GrantXPParams.eventParticipation(String userId) {
    return GrantXPParams(
      userId: userId,
      xpAmount: 15, // Fixed XP for event participation
      reason: 'event_participation',
    );
  }
}

class XPGrantResult {
  final UserLevel oldLevel;
  final UserLevel newLevel;
  final int xpGranted;
  final String reason;
  final bool leveledUp;
  final int levelsGained;
  final List<LevelReward> rewards;
  final bool becameVIP;

  XPGrantResult({
    required this.oldLevel,
    required this.newLevel,
    required this.xpGranted,
    required this.reason,
    required this.leveledUp,
    required this.levelsGained,
    required this.rewards,
    required this.becameVIP,
  });
}
