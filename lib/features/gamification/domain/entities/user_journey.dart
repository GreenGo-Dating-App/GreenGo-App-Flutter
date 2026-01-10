import 'package:equatable/equatable.dart';
import '../../../membership/domain/entities/membership.dart';

/// User Journey Entity
/// Tracks user progression through app milestones and unlocks
class UserJourney extends Equatable {
  final String userId;
  final List<JourneyMilestone> completedMilestones;
  final JourneyMilestone? currentMilestone;
  final int totalPoints;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserJourney({
    required this.userId,
    required this.completedMilestones,
    this.currentMilestone,
    required this.totalPoints,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Get progress percentage through journey
  double get overallProgress {
    final totalMilestones = JourneyMilestones.all.length;
    return (completedMilestones.length / totalMilestones * 100).clamp(0.0, 100.0);
  }

  /// Get next uncompleted milestone
  JourneyMilestone? get nextMilestone {
    for (final milestone in JourneyMilestones.all) {
      final isCompleted = completedMilestones.any(
        (m) => m.milestoneId == milestone.milestoneId,
      );
      if (!isCompleted) return milestone;
    }
    return null;
  }

  /// Get upcoming milestones (next 3)
  List<JourneyMilestone> get upcomingMilestones {
    final upcoming = <JourneyMilestone>[];
    for (final milestone in JourneyMilestones.all) {
      if (upcoming.length >= 3) break;
      final isCompleted = completedMilestones.any(
        (m) => m.milestoneId == milestone.milestoneId,
      );
      if (!isCompleted) upcoming.add(milestone);
    }
    return upcoming;
  }

  @override
  List<Object?> get props => [
        userId,
        completedMilestones,
        currentMilestone,
        totalPoints,
        createdAt,
        updatedAt,
      ];
}

/// Journey Milestone Entity
/// Represents a progression milestone in the user journey
class JourneyMilestone extends Equatable {
  final String milestoneId;
  final String name;
  final String description;
  final String iconAsset;
  final JourneyCategory category;
  final JourneyMilestoneType type;
  final int requiredCount;
  final List<JourneyReward> rewards;
  final int sortOrder;
  final MembershipTier? requiredTier;
  final String? prerequisiteMilestoneId;

  const JourneyMilestone({
    required this.milestoneId,
    required this.name,
    required this.description,
    required this.iconAsset,
    required this.category,
    required this.type,
    required this.requiredCount,
    required this.rewards,
    this.sortOrder = 0,
    this.requiredTier,
    this.prerequisiteMilestoneId,
  });

  @override
  List<Object?> get props => [
        milestoneId,
        name,
        description,
        iconAsset,
        category,
        type,
        requiredCount,
        rewards,
        sortOrder,
        requiredTier,
        prerequisiteMilestoneId,
      ];
}

/// Journey Categories
enum JourneyCategory {
  gettingStarted,
  socializing,
  premium,
  mastery,
  special,
}

extension JourneyCategoryExtension on JourneyCategory {
  String get displayName {
    switch (this) {
      case JourneyCategory.gettingStarted:
        return 'Getting Started';
      case JourneyCategory.socializing:
        return 'Socializing';
      case JourneyCategory.premium:
        return 'Premium';
      case JourneyCategory.mastery:
        return 'Mastery';
      case JourneyCategory.special:
        return 'Special';
    }
  }

  String get description {
    switch (this) {
      case JourneyCategory.gettingStarted:
        return 'Complete your profile and get familiar with the app';
      case JourneyCategory.socializing:
        return 'Connect with others and build relationships';
      case JourneyCategory.premium:
        return 'Unlock premium features and rewards';
      case JourneyCategory.mastery:
        return 'Become a master of the dating game';
      case JourneyCategory.special:
        return 'Exclusive milestones and achievements';
    }
  }
}

/// Milestone Types
enum JourneyMilestoneType {
  profileCompletion,
  verification,
  matches,
  messages,
  videoCalls,
  streaks,
  coins,
  achievements,
  tierUpgrade,
  special,
}

/// Journey Reward
class JourneyReward extends Equatable {
  final String type; // coins, xp, badge, boost, feature_unlock
  final int amount;
  final String? itemId;
  final String? description;

  const JourneyReward({
    required this.type,
    required this.amount,
    this.itemId,
    this.description,
  });

  @override
  List<Object?> get props => [type, amount, itemId, description];
}

/// User Milestone Progress
class UserMilestoneProgress extends Equatable {
  final String userId;
  final String milestoneId;
  final int progress;
  final int requiredCount;
  final bool isCompleted;
  final DateTime? completedAt;
  final bool rewardsClaimed;
  final DateTime createdAt;

  const UserMilestoneProgress({
    required this.userId,
    required this.milestoneId,
    required this.progress,
    required this.requiredCount,
    this.isCompleted = false,
    this.completedAt,
    this.rewardsClaimed = false,
    required this.createdAt,
  });

  double get progressPercentage {
    if (requiredCount == 0) return 100.0;
    return (progress / requiredCount * 100).clamp(0.0, 100.0);
  }

  bool get canClaim => isCompleted && !rewardsClaimed;

  @override
  List<Object?> get props => [
        userId,
        milestoneId,
        progress,
        requiredCount,
        isCompleted,
        completedAt,
        rewardsClaimed,
        createdAt,
      ];
}

/// Standard Journey Milestones
class JourneyMilestones {
  // Getting Started
  static const JourneyMilestone completeProfile = JourneyMilestone(
    milestoneId: 'complete_profile',
    name: 'Profile Pro',
    description: 'Complete your profile 100%',
    iconAsset: 'assets/journey/profile.png',
    category: JourneyCategory.gettingStarted,
    type: JourneyMilestoneType.profileCompletion,
    requiredCount: 100,
    sortOrder: 1,
    rewards: [
      JourneyReward(type: 'xp', amount: 100),
      JourneyReward(type: 'coins', amount: 50),
    ],
  );

  static const JourneyMilestone addPhotos = JourneyMilestone(
    milestoneId: 'add_photos',
    name: 'Picture Perfect',
    description: 'Add 5 photos to your profile',
    iconAsset: 'assets/journey/photos.png',
    category: JourneyCategory.gettingStarted,
    type: JourneyMilestoneType.profileCompletion,
    requiredCount: 5,
    sortOrder: 2,
    rewards: [
      JourneyReward(type: 'xp', amount: 75),
      JourneyReward(type: 'coins', amount: 25),
    ],
  );

  static const JourneyMilestone getVerified = JourneyMilestone(
    milestoneId: 'get_verified',
    name: 'Verified User',
    description: 'Complete photo verification',
    iconAsset: 'assets/journey/verified.png',
    category: JourneyCategory.gettingStarted,
    type: JourneyMilestoneType.verification,
    requiredCount: 1,
    sortOrder: 3,
    rewards: [
      JourneyReward(type: 'xp', amount: 150),
      JourneyReward(type: 'coins', amount: 100),
      JourneyReward(
        type: 'badge',
        amount: 1,
        itemId: 'verified_badge',
        description: 'Verified Badge',
      ),
    ],
  );

  // Socializing
  static const JourneyMilestone firstMatch = JourneyMilestone(
    milestoneId: 'first_match',
    name: 'First Connection',
    description: 'Get your first match',
    iconAsset: 'assets/journey/match.png',
    category: JourneyCategory.socializing,
    type: JourneyMilestoneType.matches,
    requiredCount: 1,
    sortOrder: 4,
    rewards: [
      JourneyReward(type: 'xp', amount: 50),
      JourneyReward(type: 'coins', amount: 20),
    ],
  );

  static const JourneyMilestone tenMatches = JourneyMilestone(
    milestoneId: 'ten_matches',
    name: 'Rising Star',
    description: 'Get 10 matches',
    iconAsset: 'assets/journey/star.png',
    category: JourneyCategory.socializing,
    type: JourneyMilestoneType.matches,
    requiredCount: 10,
    sortOrder: 5,
    prerequisiteMilestoneId: 'first_match',
    rewards: [
      JourneyReward(type: 'xp', amount: 100),
      JourneyReward(type: 'coins', amount: 50),
    ],
  );

  static const JourneyMilestone fiftyMatches = JourneyMilestone(
    milestoneId: 'fifty_matches',
    name: 'Social Butterfly',
    description: 'Get 50 matches',
    iconAsset: 'assets/journey/butterfly.png',
    category: JourneyCategory.socializing,
    type: JourneyMilestoneType.matches,
    requiredCount: 50,
    sortOrder: 6,
    prerequisiteMilestoneId: 'ten_matches',
    rewards: [
      JourneyReward(type: 'xp', amount: 250),
      JourneyReward(type: 'coins', amount: 150),
      JourneyReward(type: 'boost', amount: 1, description: 'Free Profile Boost'),
    ],
  );

  static const JourneyMilestone firstMessage = JourneyMilestone(
    milestoneId: 'first_message',
    name: 'Ice Breaker',
    description: 'Send your first message',
    iconAsset: 'assets/journey/message.png',
    category: JourneyCategory.socializing,
    type: JourneyMilestoneType.messages,
    requiredCount: 1,
    sortOrder: 7,
    rewards: [
      JourneyReward(type: 'xp', amount: 30),
    ],
  );

  static const JourneyMilestone hundredMessages = JourneyMilestone(
    milestoneId: 'hundred_messages',
    name: 'Conversation King',
    description: 'Send 100 messages',
    iconAsset: 'assets/journey/king.png',
    category: JourneyCategory.socializing,
    type: JourneyMilestoneType.messages,
    requiredCount: 100,
    sortOrder: 8,
    prerequisiteMilestoneId: 'first_message',
    rewards: [
      JourneyReward(type: 'xp', amount: 200),
      JourneyReward(type: 'coins', amount: 100),
    ],
  );

  static const JourneyMilestone firstVideoCall = JourneyMilestone(
    milestoneId: 'first_video_call',
    name: 'Face to Face',
    description: 'Complete your first video call',
    iconAsset: 'assets/journey/video.png',
    category: JourneyCategory.socializing,
    type: JourneyMilestoneType.videoCalls,
    requiredCount: 1,
    sortOrder: 9,
    rewards: [
      JourneyReward(type: 'xp', amount: 100),
      JourneyReward(type: 'coins', amount: 75),
    ],
  );

  static const JourneyMilestone tenVideoCalls = JourneyMilestone(
    milestoneId: 'ten_video_calls',
    name: 'Video Pro',
    description: 'Complete 10 video calls',
    iconAsset: 'assets/journey/video_pro.png',
    category: JourneyCategory.socializing,
    type: JourneyMilestoneType.videoCalls,
    requiredCount: 10,
    sortOrder: 10,
    prerequisiteMilestoneId: 'first_video_call',
    rewards: [
      JourneyReward(type: 'xp', amount: 300),
      JourneyReward(type: 'coins', amount: 200),
      JourneyReward(
        type: 'badge',
        amount: 1,
        itemId: 'video_champion_badge',
        description: 'Video Champion Badge',
      ),
    ],
  );

  // Streaks
  static const JourneyMilestone weekStreak = JourneyMilestone(
    milestoneId: 'week_streak',
    name: 'Dedicated User',
    description: 'Maintain a 7-day login streak',
    iconAsset: 'assets/journey/streak.png',
    category: JourneyCategory.socializing,
    type: JourneyMilestoneType.streaks,
    requiredCount: 7,
    sortOrder: 11,
    rewards: [
      JourneyReward(type: 'xp', amount: 150),
      JourneyReward(type: 'coins', amount: 100),
    ],
  );

  static const JourneyMilestone monthStreak = JourneyMilestone(
    milestoneId: 'month_streak',
    name: 'Super Dedicated',
    description: 'Maintain a 30-day login streak',
    iconAsset: 'assets/journey/fire.png',
    category: JourneyCategory.socializing,
    type: JourneyMilestoneType.streaks,
    requiredCount: 30,
    sortOrder: 12,
    prerequisiteMilestoneId: 'week_streak',
    rewards: [
      JourneyReward(type: 'xp', amount: 500),
      JourneyReward(type: 'coins', amount: 300),
      JourneyReward(
        type: 'badge',
        amount: 1,
        itemId: 'dedication_badge',
        description: 'Dedication Badge',
      ),
    ],
  );

  // Premium
  static const JourneyMilestone upgradeSilver = JourneyMilestone(
    milestoneId: 'upgrade_silver',
    name: 'Silver Member',
    description: 'Upgrade to Silver VIP',
    iconAsset: 'assets/journey/silver.png',
    category: JourneyCategory.premium,
    type: JourneyMilestoneType.tierUpgrade,
    requiredCount: 1,
    sortOrder: 13,
    rewards: [
      JourneyReward(type: 'xp', amount: 200),
      JourneyReward(type: 'coins', amount: 100),
    ],
  );

  static const JourneyMilestone upgradeGold = JourneyMilestone(
    milestoneId: 'upgrade_gold',
    name: 'Gold Member',
    description: 'Upgrade to Gold VIP',
    iconAsset: 'assets/journey/gold.png',
    category: JourneyCategory.premium,
    type: JourneyMilestoneType.tierUpgrade,
    requiredCount: 1,
    sortOrder: 14,
    prerequisiteMilestoneId: 'upgrade_silver',
    rewards: [
      JourneyReward(type: 'xp', amount: 400),
      JourneyReward(type: 'coins', amount: 250),
    ],
  );

  static const JourneyMilestone upgradePlatinum = JourneyMilestone(
    milestoneId: 'upgrade_platinum',
    name: 'Platinum Member',
    description: 'Upgrade to Platinum VIP',
    iconAsset: 'assets/journey/platinum.png',
    category: JourneyCategory.premium,
    type: JourneyMilestoneType.tierUpgrade,
    requiredCount: 1,
    sortOrder: 15,
    prerequisiteMilestoneId: 'upgrade_gold',
    rewards: [
      JourneyReward(type: 'xp', amount: 750),
      JourneyReward(type: 'coins', amount: 500),
      JourneyReward(
        type: 'badge',
        amount: 1,
        itemId: 'platinum_elite_badge',
        description: 'Platinum Elite Badge',
      ),
    ],
  );

  // Mastery
  static const JourneyMilestone tenAchievements = JourneyMilestone(
    milestoneId: 'ten_achievements',
    name: 'Achievement Hunter',
    description: 'Earn 10 achievements',
    iconAsset: 'assets/journey/achievement.png',
    category: JourneyCategory.mastery,
    type: JourneyMilestoneType.achievements,
    requiredCount: 10,
    sortOrder: 16,
    rewards: [
      JourneyReward(type: 'xp', amount: 300),
      JourneyReward(type: 'coins', amount: 200),
    ],
  );

  static const JourneyMilestone fiftyAchievements = JourneyMilestone(
    milestoneId: 'fifty_achievements',
    name: 'Achievement Master',
    description: 'Earn 50 achievements',
    iconAsset: 'assets/journey/master.png',
    category: JourneyCategory.mastery,
    type: JourneyMilestoneType.achievements,
    requiredCount: 50,
    sortOrder: 17,
    prerequisiteMilestoneId: 'ten_achievements',
    rewards: [
      JourneyReward(type: 'xp', amount: 1000),
      JourneyReward(type: 'coins', amount: 500),
      JourneyReward(
        type: 'badge',
        amount: 1,
        itemId: 'master_badge',
        description: 'Mastery Badge',
      ),
    ],
  );

  static const JourneyMilestone hundredMatches = JourneyMilestone(
    milestoneId: 'hundred_matches',
    name: 'Centurion',
    description: 'Get 100 matches',
    iconAsset: 'assets/journey/centurion.png',
    category: JourneyCategory.mastery,
    type: JourneyMilestoneType.matches,
    requiredCount: 100,
    sortOrder: 18,
    prerequisiteMilestoneId: 'fifty_matches',
    rewards: [
      JourneyReward(type: 'xp', amount: 750),
      JourneyReward(type: 'coins', amount: 400),
      JourneyReward(type: 'boost', amount: 3, description: '3 Free Profile Boosts'),
      JourneyReward(
        type: 'badge',
        amount: 1,
        itemId: 'centurion_badge',
        description: 'Centurion Badge',
      ),
    ],
  );

  /// Get all journey milestones
  static List<JourneyMilestone> get all => [
        completeProfile,
        addPhotos,
        getVerified,
        firstMatch,
        tenMatches,
        fiftyMatches,
        firstMessage,
        hundredMessages,
        firstVideoCall,
        tenVideoCalls,
        weekStreak,
        monthStreak,
        upgradeSilver,
        upgradeGold,
        upgradePlatinum,
        tenAchievements,
        fiftyAchievements,
        hundredMatches,
      ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  /// Get milestones by category
  static List<JourneyMilestone> getByCategory(JourneyCategory category) {
    return all.where((m) => m.category == category).toList();
  }

  /// Get milestone by ID
  static JourneyMilestone? getById(String milestoneId) {
    try {
      return all.firstWhere((m) => m.milestoneId == milestoneId);
    } catch (e) {
      return null;
    }
  }
}
