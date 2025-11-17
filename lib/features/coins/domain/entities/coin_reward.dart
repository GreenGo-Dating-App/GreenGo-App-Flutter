import 'package:equatable/equatable.dart';

/// Coin Reward Entity
/// Point 160: Coin rewards for achievements
class CoinReward extends Equatable {
  final String rewardId;
  final String name;
  final String description;
  final int coinAmount;
  final RewardType type;
  final String? achievementId;
  final bool isRecurring;
  final int? maxClaims;
  final Duration? cooldownPeriod;

  const CoinReward({
    required this.rewardId,
    required this.name,
    required this.description,
    required this.coinAmount,
    required this.type,
    this.achievementId,
    this.isRecurring = false,
    this.maxClaims,
    this.cooldownPeriod,
  });

  @override
  List<Object?> get props => [
        rewardId,
        name,
        description,
        coinAmount,
        type,
        achievementId,
        isRecurring,
        maxClaims,
        cooldownPeriod,
      ];
}

/// Type of reward
enum RewardType {
  achievement,
  dailyLogin,
  firstMatch,
  profileCompletion,
  streak,
  referral,
  milestone,
}

/// Standard coin rewards (Point 160)
class CoinRewards {
  /// First match reward: 50 coins
  static const CoinReward firstMatch = CoinReward(
    rewardId: 'first_match',
    name: 'First Match',
    description: 'Get your first match',
    coinAmount: 50,
    type: RewardType.firstMatch,
    isRecurring: false,
    maxClaims: 1,
  );

  /// Complete profile reward: 100 coins
  static const CoinReward completeProfile = CoinReward(
    rewardId: 'complete_profile',
    name: 'Complete Profile',
    description: 'Complete your dating profile',
    coinAmount: 100,
    type: RewardType.profileCompletion,
    isRecurring: false,
    maxClaims: 1,
  );

  /// Daily login streak: 10 coins per day
  static const CoinReward dailyLogin = CoinReward(
    rewardId: 'daily_login',
    name: 'Daily Login',
    description: 'Login daily to earn coins',
    coinAmount: 10,
    type: RewardType.dailyLogin,
    isRecurring: true,
    cooldownPeriod: Duration(days: 1),
  );

  /// 7-day streak bonus: 50 coins
  static const CoinReward weekStreak = CoinReward(
    rewardId: 'week_streak',
    name: '7-Day Streak',
    description: 'Login 7 days in a row',
    coinAmount: 50,
    type: RewardType.streak,
    isRecurring: true,
  );

  /// 30-day streak bonus: 200 coins
  static const CoinReward monthStreak = CoinReward(
    rewardId: 'month_streak',
    name: '30-Day Streak',
    description: 'Login 30 days in a row',
    coinAmount: 200,
    type: RewardType.streak,
    isRecurring: true,
  );

  /// First message sent: 25 coins
  static const CoinReward firstMessage = CoinReward(
    rewardId: 'first_message',
    name: 'First Message',
    description: 'Send your first message',
    coinAmount: 25,
    type: RewardType.achievement,
    isRecurring: false,
    maxClaims: 1,
  );

  /// Photo verification: 75 coins
  static const CoinReward photoVerification = CoinReward(
    rewardId: 'photo_verification',
    name: 'Photo Verified',
    description: 'Verify your profile with a photo',
    coinAmount: 75,
    type: RewardType.achievement,
    isRecurring: false,
    maxClaims: 1,
  );

  /// Refer a friend: 100 coins
  static const CoinReward referFriend = CoinReward(
    rewardId: 'refer_friend',
    name: 'Refer a Friend',
    description: 'Invite a friend to join GreenGo',
    coinAmount: 100,
    type: RewardType.referral,
    isRecurring: true,
  );

  /// Get all standard rewards
  static List<CoinReward> get standardRewards => [
        firstMatch,
        completeProfile,
        dailyLogin,
        weekStreak,
        monthStreak,
        firstMessage,
        photoVerification,
        referFriend,
      ];

  /// Get reward by ID
  static CoinReward? getById(String rewardId) {
    try {
      return standardRewards.firstWhere(
        (reward) => reward.rewardId == rewardId,
      );
    } catch (e) {
      return null;
    }
  }
}

/// Claimed reward entity
class ClaimedReward extends Equatable {
  final String userId;
  final String rewardId;
  final int coinAmount;
  final DateTime claimedAt;
  final int claimCount;

  const ClaimedReward({
    required this.userId,
    required this.rewardId,
    required this.coinAmount,
    required this.claimedAt,
    this.claimCount = 1,
  });

  @override
  List<Object?> get props => [
        userId,
        rewardId,
        coinAmount,
        claimedAt,
        claimCount,
      ];
}
