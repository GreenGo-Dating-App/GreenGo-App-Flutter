import 'dart:math' as math;

import 'package:equatable/equatable.dart';

/// User Level Entity
/// Points 186-195: Level & Progression System
class UserLevel extends Equatable {
  final String userId;
  final int level;
  final int currentXP;
  final int totalXP;
  final DateTime lastUpdated;
  final String region;
  final int regionalRank;
  final bool isVIP; // Level 50+

  const UserLevel({
    required this.userId,
    required this.level,
    required this.currentXP,
    required this.totalXP,
    required this.lastUpdated,
    this.region = 'global',
    this.regionalRank = 0,
    this.isVIP = false,
  });

  /// Get XP required for next level
  int get xpForNextLevel {
    return LevelSystem.xpRequiredForLevel(level + 1);
  }

  /// Get XP required for current level
  int get xpForCurrentLevel {
    return LevelSystem.xpRequiredForLevel(level);
  }

  /// Get progress to next level (0.0 - 1.0)
  double get progressToNextLevel {
    final xpIntoLevel = currentXP - xpForCurrentLevel;
    final xpNeeded = xpForNextLevel - xpForCurrentLevel;
    return (xpIntoLevel / xpNeeded).clamp(0.0, 1.0);
  }

  /// Get progress percentage
  double get progressPercentage {
    return progressToNextLevel * 100;
  }

  /// Check if can level up
  bool get canLevelUp {
    return currentXP >= xpForNextLevel;
  }

  @override
  List<Object?> get props => [
        userId,
        level,
        currentXP,
        totalXP,
        lastUpdated,
        region,
        regionalRank,
        isVIP,
      ];
}

/// XP Action
/// Point 187: XP rewards for different actions
class XPAction {
  final String actionType;
  final int xpAmount;
  final String description;

  const XPAction({
    required this.actionType,
    required this.xpAmount,
    required this.description,
  });
}

/// XP Actions (Point 187)
class XPActions {
  // Profile interactions
  static const XPAction profileView = XPAction(
    actionType: 'profile_view',
    xpAmount: 1,
    description: 'Someone viewed your profile',
  );

  // Matching
  static const XPAction match = XPAction(
    actionType: 'match',
    xpAmount: 10,
    description: 'Got a new match',
  );

  static const XPAction superLike = XPAction(
    actionType: 'super_like',
    xpAmount: 5,
    description: 'Sent a super like',
  );

  // Messaging
  static const XPAction messageSent = XPAction(
    actionType: 'message_sent',
    xpAmount: 2,
    description: 'Sent a message',
  );

  static const XPAction firstMessage = XPAction(
    actionType: 'first_message',
    xpAmount: 15,
    description: 'Started a conversation',
  );

  // Video calls
  static const XPAction videoCall = XPAction(
    actionType: 'video_call',
    xpAmount: 25,
    description: 'Completed a video call',
  );

  // Profile completion
  static const XPAction photoAdded = XPAction(
    actionType: 'photo_added',
    xpAmount: 5,
    description: 'Added a photo',
  );

  static const XPAction bioUpdated = XPAction(
    actionType: 'bio_updated',
    xpAmount: 10,
    description: 'Updated bio',
  );

  static const XPAction profileVerified = XPAction(
    actionType: 'profile_verified',
    xpAmount: 50,
    description: 'Verified profile',
  );

  // Daily actions
  static const XPAction dailyLogin = XPAction(
    actionType: 'daily_login',
    xpAmount: 5,
    description: 'Daily login',
  );

  static const XPAction dailyChallengeCompleted = XPAction(
    actionType: 'daily_challenge',
    xpAmount: 20,
    description: 'Completed daily challenge',
  );

  // Premium actions
  static const XPAction subscriptionPurchased = XPAction(
    actionType: 'subscription',
    xpAmount: 100,
    description: 'Purchased subscription',
  );

  static const XPAction coinsPurchased = XPAction(
    actionType: 'coins_purchase',
    xpAmount: 30,
    description: 'Purchased coins',
  );

  // Get all actions
  static List<XPAction> get all => [
        profileView,
        match,
        superLike,
        messageSent,
        firstMessage,
        videoCall,
        photoAdded,
        bioUpdated,
        profileVerified,
        dailyLogin,
        dailyChallengeCompleted,
        subscriptionPurchased,
        coinsPurchased,
      ];

  /// Get XP amount for action type
  static int getXPForAction(String actionType) {
    try {
      final action = all.firstWhere((a) => a.actionType == actionType);
      return action.xpAmount;
    } catch (e) {
      return 0;
    }
  }
}

/// Level System
/// Point 188: Level progression from 1 to 100 with exponential XP
class LevelSystem {
  /// Calculate XP required for a specific level
  /// Uses exponential formula: XP = baseXP * (level ^ 1.5)
  static int xpRequiredForLevel(int level) {
    if (level <= 1) return 0;

    const int baseXP = 100;
    return (baseXP * math.pow(level, 1.5)).round();
  }

  /// Calculate total XP required to reach a level
  static int totalXPForLevel(int level) {
    int total = 0;
    for (int i = 1; i <= level; i++) {
      total += xpRequiredForLevel(i);
    }
    return total;
  }

  /// Calculate level from total XP
  static int levelFromXP(int totalXP) {
    int level = 1;
    while (totalXPForLevel(level + 1) <= totalXP && level < 100) {
      level++;
    }
    return level;
  }

  /// Check if user should level up
  static bool shouldLevelUp(int currentLevel, int currentXP) {
    return currentXP >= xpRequiredForLevel(currentLevel + 1);
  }

  /// Get XP breakdown for levels
  static Map<int, int> getXPBreakdown() {
    final Map<int, int> breakdown = {};
    for (int level = 1; level <= 100; level++) {
      breakdown[level] = xpRequiredForLevel(level);
    }
    return breakdown;
  }
}

/// Level Rewards (Point 190)
class LevelRewards {
  final int level;
  final List<LevelReward> rewards;

  const LevelRewards({
    required this.level,
    required this.rewards,
  });
}

class LevelReward {
  final String type; // frame, badge, coins, feature
  final String itemId;
  final String name;
  final String description;

  const LevelReward({
    required this.type,
    required this.itemId,
    required this.name,
    required this.description,
  });
}

/// Standard Level Rewards
class StandardLevelRewards {
  // Level 5
  static const LevelRewards level5 = LevelRewards(
    level: 5,
    rewards: [
      LevelReward(
        type: 'frame',
        itemId: 'bronze_frame',
        name: 'Bronze Frame',
        description: 'Bronze profile frame',
      ),
      LevelReward(
        type: 'coins',
        itemId: 'bonus_coins',
        name: '50 Bonus Coins',
        description: 'Free coins reward',
      ),
    ],
  );

  // Level 10 - Unlocks custom chat themes
  static const LevelRewards level10 = LevelRewards(
    level: 10,
    rewards: [
      LevelReward(
        type: 'frame',
        itemId: 'silver_frame',
        name: 'Silver Frame',
        description: 'Silver profile frame',
      ),
      LevelReward(
        type: 'feature',
        itemId: 'custom_chat_themes',
        name: 'Custom Chat Themes',
        description: 'Unlock custom chat themes',
      ),
    ],
  );

  // Level 25 - Unlocks profile video
  static const LevelRewards level25 = LevelRewards(
    level: 25,
    rewards: [
      LevelReward(
        type: 'frame',
        itemId: 'gold_frame',
        name: 'Gold Frame',
        description: 'Gold profile frame',
      ),
      LevelReward(
        type: 'feature',
        itemId: 'profile_video',
        name: 'Profile Video',
        description: 'Add video to your profile',
      ),
    ],
  );

  // Level 50 - VIP Status
  static const LevelRewards level50 = LevelRewards(
    level: 50,
    rewards: [
      LevelReward(
        type: 'frame',
        itemId: 'platinum_frame',
        name: 'Platinum Frame',
        description: 'Platinum profile frame',
      ),
      LevelReward(
        type: 'badge',
        itemId: 'vip_crown',
        name: 'VIP Crown',
        description: 'Gold crown indicator',
      ),
      LevelReward(
        type: 'coins',
        itemId: 'vip_bonus',
        name: '500 Bonus Coins',
        description: 'VIP welcome bonus',
      ),
    ],
  );

  // Level 75
  static const LevelRewards level75 = LevelRewards(
    level: 75,
    rewards: [
      LevelReward(
        type: 'frame',
        itemId: 'diamond_frame',
        name: 'Diamond Frame',
        description: 'Diamond profile frame',
      ),
      LevelReward(
        type: 'coins',
        itemId: 'bonus_coins',
        name: '750 Bonus Coins',
        description: 'Achievement reward',
      ),
    ],
  );

  // Level 100 - Max Level
  static const LevelRewards level100 = LevelRewards(
    level: 100,
    rewards: [
      LevelReward(
        type: 'frame',
        itemId: 'legendary_frame',
        name: 'Legendary Frame',
        description: 'Rainbow animated frame',
      ),
      LevelReward(
        type: 'badge',
        itemId: 'max_level_badge',
        name: 'Level 100 Badge',
        description: 'Maximum level achieved',
      ),
      LevelReward(
        type: 'coins',
        itemId: 'legendary_bonus',
        name: '1000 Bonus Coins',
        description: 'Legendary achievement',
      ),
    ],
  );

  /// Get rewards for level
  static LevelRewards? getRewardsForLevel(int level) {
    switch (level) {
      case 5:
        return level5;
      case 10:
        return level10;
      case 25:
        return level25;
      case 50:
        return level50;
      case 75:
        return level75;
      case 100:
        return level100;
      default:
        return null;
    }
  }

  /// Get all milestone levels
  static List<int> get milestoneLevels => [5, 10, 25, 50, 75, 100];
}

/// Leaderboard Entry (Point 191)
class LeaderboardEntry extends Equatable {
  final int rank;
  final String userId;
  final String username;
  final String? photoUrl;
  final int level;
  final int totalXP;
  final String region;
  final bool isVIP;

  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.username,
    this.photoUrl,
    required this.level,
    required this.totalXP,
    this.region = 'global',
    this.isVIP = false,
  });

  @override
  List<Object?> get props => [
        rank,
        userId,
        username,
        photoUrl,
        level,
        totalXP,
        region,
        isVIP,
      ];
}

/// XP Transaction
class XPTransaction extends Equatable {
  final String transactionId;
  final String userId;
  final String actionType;
  final int xpAmount;
  final int levelBefore;
  final int levelAfter;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  const XPTransaction({
    required this.transactionId,
    required this.userId,
    required this.actionType,
    required this.xpAmount,
    required this.levelBefore,
    required this.levelAfter,
    required this.createdAt,
    this.metadata,
  });

  bool get didLevelUp => levelAfter > levelBefore;

  @override
  List<Object?> get props => [
        transactionId,
        userId,
        actionType,
        xpAmount,
        levelBefore,
        levelAfter,
        createdAt,
        metadata,
      ];
}
