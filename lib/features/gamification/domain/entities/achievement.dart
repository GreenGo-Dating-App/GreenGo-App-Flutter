import 'package:equatable/equatable.dart';

/// Achievement Entity
/// Points 176-185: Comprehensive badge system
class Achievement extends Equatable {
  final String achievementId;
  final String name;
  final String description;
  final AchievementCategory category;
  final AchievementRarity rarity;
  final String iconUrl;
  final int requiredCount;
  final String rewardType; // xp, coins, badge
  final int rewardAmount;
  final bool isSecret;

  const Achievement({
    required this.achievementId,
    required this.name,
    required this.description,
    required this.category,
    required this.rarity,
    required this.iconUrl,
    required this.requiredCount,
    this.rewardType = 'xp',
    this.rewardAmount = 0,
    this.isSecret = false,
  });

  @override
  List<Object?> get props => [
        achievementId,
        name,
        description,
        category,
        rarity,
        iconUrl,
        requiredCount,
        rewardType,
        rewardAmount,
        isSecret,
      ];
}

/// Achievement Categories
enum AchievementCategory {
  social,      // Conversations, matches
  engagement,  // Daily logins, activity
  premium,     // Coins, subscriptions
  milestones,  // First match, profile completion
  special,     // Seasonal, events
}

/// Achievement Rarity
enum AchievementRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
}

/// User Achievement (Earned)
class UserAchievement extends Equatable {
  final String userId;
  final String achievementId;
  final int progress;
  final int requiredCount;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime createdAt;

  const UserAchievement({
    required this.userId,
    required this.achievementId,
    required this.progress,
    required this.requiredCount,
    this.isCompleted = false,
    this.completedAt,
    required this.createdAt,
  });

  /// Get progress percentage
  double get progressPercentage {
    if (requiredCount == 0) return 100.0;
    return (progress / requiredCount * 100).clamp(0.0, 100.0);
  }

  @override
  List<Object?> get props => [
        userId,
        achievementId,
        progress,
        requiredCount,
        isCompleted,
        completedAt,
        createdAt,
      ];
}

/// Standard Achievements (Points 177-185)
class Achievements {
  // Point 177: First Match
  static const Achievement firstMatch = Achievement(
    achievementId: 'first_match',
    name: 'First Match',
    description: 'Get your first mutual like',
    category: AchievementCategory.milestones,
    rarity: AchievementRarity.common,
    iconUrl: 'assets/achievements/first_match.png',
    requiredCount: 1,
    rewardType: 'xp',
    rewardAmount: 50,
  );

  // Point 178: Conversation Starter
  static const Achievement conversationStarter = Achievement(
    achievementId: 'conversation_starter',
    name: 'Conversation Starter',
    description: 'Initiate 10 conversations',
    category: AchievementCategory.social,
    rarity: AchievementRarity.uncommon,
    iconUrl: 'assets/achievements/conversation_starter.png',
    requiredCount: 10,
    rewardType: 'xp',
    rewardAmount: 100,
  );

  // Point 179: Video Champion
  static const Achievement videoChampion = Achievement(
    achievementId: 'video_champion',
    name: 'Video Champion',
    description: 'Complete 5 video calls',
    category: AchievementCategory.engagement,
    rarity: AchievementRarity.rare,
    iconUrl: 'assets/achievements/video_champion.png',
    requiredCount: 5,
    rewardType: 'coins',
    rewardAmount: 100,
  );

  // Point 180: Profile Master
  static const Achievement profileMaster = Achievement(
    achievementId: 'profile_master',
    name: 'Profile Master',
    description: 'Complete all profile sections 100%',
    category: AchievementCategory.milestones,
    rarity: AchievementRarity.uncommon,
    iconUrl: 'assets/achievements/profile_master.png',
    requiredCount: 1,
    rewardType: 'xp',
    rewardAmount: 75,
  );

  // Point 181: Globe Trotter
  static const Achievement globeTrotter = Achievement(
    achievementId: 'globe_trotter',
    name: 'Globe Trotter',
    description: 'Match with users from 10+ countries',
    category: AchievementCategory.social,
    rarity: AchievementRarity.epic,
    iconUrl: 'assets/achievements/globe_trotter.png',
    requiredCount: 10,
    rewardType: 'xp',
    rewardAmount: 200,
  );

  // Point 182: Generous Heart
  static const Achievement generousHeart = Achievement(
    achievementId: 'generous_heart',
    name: 'Generous Heart',
    description: 'Gift coins to matches',
    category: AchievementCategory.premium,
    rarity: AchievementRarity.rare,
    iconUrl: 'assets/achievements/generous_heart.png',
    requiredCount: 5,
    rewardType: 'coins',
    rewardAmount: 50,
  );

  // Point 183: Daily Dedication
  static const Achievement dailyDedication = Achievement(
    achievementId: 'daily_dedication',
    name: 'Daily Dedication',
    description: '7-day consecutive login streak',
    category: AchievementCategory.engagement,
    rarity: AchievementRarity.uncommon,
    iconUrl: 'assets/achievements/daily_dedication.png',
    requiredCount: 7,
    rewardType: 'xp',
    rewardAmount: 150,
  );

  // Point 184: Super Star
  static const Achievement superStar = Achievement(
    achievementId: 'super_star',
    name: 'Super Star',
    description: 'Receive 50+ super likes',
    category: AchievementCategory.social,
    rarity: AchievementRarity.legendary,
    iconUrl: 'assets/achievements/super_star.png',
    requiredCount: 50,
    rewardType: 'xp',
    rewardAmount: 500,
  );

  // Point 185: Social Butterfly
  static const Achievement socialButterfly = Achievement(
    achievementId: 'social_butterfly',
    name: 'Social Butterfly',
    description: 'Maintain 20+ active conversations',
    category: AchievementCategory.social,
    rarity: AchievementRarity.epic,
    iconUrl: 'assets/achievements/social_butterfly.png',
    requiredCount: 20,
    rewardType: 'xp',
    rewardAmount: 300,
  );

  // Additional Achievements (to reach 50+)
  static const Achievement perfectWeek = Achievement(
    achievementId: 'perfect_week',
    name: 'Perfect Week',
    description: 'Complete all daily challenges for 7 days',
    category: AchievementCategory.engagement,
    rarity: AchievementRarity.epic,
    iconUrl: 'assets/achievements/perfect_week.png',
    requiredCount: 7,
    rewardType: 'coins',
    rewardAmount: 200,
  );

  static const Achievement earlyBird = Achievement(
    achievementId: 'early_bird',
    name: 'Early Bird',
    description: 'Send messages before 9 AM on 10 days',
    category: AchievementCategory.engagement,
    rarity: AchievementRarity.uncommon,
    iconUrl: 'assets/achievements/early_bird.png',
    requiredCount: 10,
    rewardType: 'xp',
    rewardAmount: 75,
  );

  static const Achievement nightOwl = Achievement(
    achievementId: 'night_owl',
    name: 'Night Owl',
    description: 'Send messages after 10 PM on 10 days',
    category: AchievementCategory.engagement,
    rarity: AchievementRarity.uncommon,
    iconUrl: 'assets/achievements/night_owl.png',
    requiredCount: 10,
    rewardType: 'xp',
    rewardAmount: 75,
  );

  static const Achievement centurion = Achievement(
    achievementId: 'centurion',
    name: 'Centurion',
    description: 'Reach 100 total matches',
    category: AchievementCategory.milestones,
    rarity: AchievementRarity.epic,
    iconUrl: 'assets/achievements/centurion.png',
    requiredCount: 100,
    rewardType: 'xp',
    rewardAmount: 400,
  );

  static const Achievement speedDater = Achievement(
    achievementId: 'speed_dater',
    name: 'Speed Dater',
    description: 'Match with 10 people in one day',
    category: AchievementCategory.social,
    rarity: AchievementRarity.rare,
    iconUrl: 'assets/achievements/speed_dater.png',
    requiredCount: 10,
    rewardType: 'xp',
    rewardAmount: 150,
  );

  static const Achievement photoCollector = Achievement(
    achievementId: 'photo_collector',
    name: 'Photo Collector',
    description: 'Add 6 photos to your profile',
    category: AchievementCategory.milestones,
    rarity: AchievementRarity.common,
    iconUrl: 'assets/achievements/photo_collector.png',
    requiredCount: 6,
    rewardType: 'xp',
    rewardAmount: 50,
  );

  static const Achievement trendSetter = Achievement(
    achievementId: 'trend_setter',
    name: 'Trend Setter',
    description: 'Be among the first 1000 users',
    category: AchievementCategory.special,
    rarity: AchievementRarity.legendary,
    iconUrl: 'assets/achievements/trend_setter.png',
    requiredCount: 1,
    rewardType: 'coins',
    rewardAmount: 500,
    isSecret: true,
  );

  static const Achievement verified = Achievement(
    achievementId: 'verified',
    name: 'Verified',
    description: 'Complete photo verification',
    category: AchievementCategory.milestones,
    rarity: AchievementRarity.uncommon,
    iconUrl: 'assets/achievements/verified.png',
    requiredCount: 1,
    rewardType: 'xp',
    rewardAmount: 100,
  );

  static const Achievement premiumMember = Achievement(
    achievementId: 'premium_member',
    name: 'Premium Member',
    description: 'Subscribe to Silver or Gold tier',
    category: AchievementCategory.premium,
    rarity: AchievementRarity.rare,
    iconUrl: 'assets/achievements/premium_member.png',
    requiredCount: 1,
    rewardType: 'coins',
    rewardAmount: 100,
  );

  static const Achievement coinCollector = Achievement(
    achievementId: 'coin_collector',
    name: 'Coin Collector',
    description: 'Accumulate 1000 coins',
    category: AchievementCategory.premium,
    rarity: AchievementRarity.epic,
    iconUrl: 'assets/achievements/coin_collector.png',
    requiredCount: 1000,
    rewardType: 'xp',
    rewardAmount: 250,
  );

  static const Achievement monthlyStreak = Achievement(
    achievementId: 'monthly_streak',
    name: 'Monthly Dedication',
    description: '30-day consecutive login streak',
    category: AchievementCategory.engagement,
    rarity: AchievementRarity.legendary,
    iconUrl: 'assets/achievements/monthly_streak.png',
    requiredCount: 30,
    rewardType: 'coins',
    rewardAmount: 500,
  );

  // Get all standard achievements
  static List<Achievement> get all => [
        firstMatch,
        conversationStarter,
        videoChampion,
        profileMaster,
        globeTrotter,
        generousHeart,
        dailyDedication,
        superStar,
        socialButterfly,
        perfectWeek,
        earlyBird,
        nightOwl,
        centurion,
        speedDater,
        photoCollector,
        trendSetter,
        verified,
        premiumMember,
        coinCollector,
        monthlyStreak,
        // Add 30+ more to reach 50+
      ];

  /// Get achievement by ID
  static Achievement? getById(String achievementId) {
    try {
      return all.firstWhere((a) => a.achievementId == achievementId);
    } catch (e) {
      return null;
    }
  }

  /// Get achievements by category
  static List<Achievement> getByCategory(AchievementCategory category) {
    return all.where((a) => a.category == category).toList();
  }

  /// Get achievements by rarity
  static List<Achievement> getByRarity(AchievementRarity rarity) {
    return all.where((a) => a.rarity == rarity).toList();
  }
}

extension AchievementCategoryExtension on AchievementCategory {
  String get displayName {
    switch (this) {
      case AchievementCategory.social:
        return 'Social';
      case AchievementCategory.engagement:
        return 'Engagement';
      case AchievementCategory.premium:
        return 'Premium';
      case AchievementCategory.milestones:
        return 'Milestones';
      case AchievementCategory.special:
        return 'Special';
    }
  }
}

extension AchievementRarityExtension on AchievementRarity {
  String get displayName {
    switch (this) {
      case AchievementRarity.common:
        return 'Common';
      case AchievementRarity.uncommon:
        return 'Uncommon';
      case AchievementRarity.rare:
        return 'Rare';
      case AchievementRarity.epic:
        return 'Epic';
      case AchievementRarity.legendary:
        return 'Legendary';
    }
  }

  int get colorValue {
    switch (this) {
      case AchievementRarity.common:
        return 0xFF9E9E9E; // Gray
      case AchievementRarity.uncommon:
        return 0xFF4CAF50; // Green
      case AchievementRarity.rare:
        return 0xFF2196F3; // Blue
      case AchievementRarity.epic:
        return 0xFF9C27B0; // Purple
      case AchievementRarity.legendary:
        return 0xFFFFD700; // Gold
    }
  }
}
