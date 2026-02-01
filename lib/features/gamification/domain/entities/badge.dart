import 'package:equatable/equatable.dart';

/// Badge Entity - Visual rewards displayed on profile
class Badge extends Equatable {
  final String badgeId;
  final String name;
  final String description;
  final String iconUrl;
  final BadgeCategory category;
  final BadgeRarity rarity;
  final bool isAnimated;
  final String? animationUrl;
  final int displayOrder;

  const Badge({
    required this.badgeId,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.category,
    required this.rarity,
    this.isAnimated = false,
    this.animationUrl,
    this.displayOrder = 0,
  });

  @override
  List<Object?> get props => [
        badgeId,
        name,
        description,
        iconUrl,
        category,
        rarity,
        isAnimated,
        animationUrl,
        displayOrder,
      ];
}

/// Badge Category
enum BadgeCategory {
  achievement,   // Earned from achievements
  level,         // Earned from leveling up
  seasonal,      // Limited time events
  premium,       // Premium members only
  special,       // Special/rare badges
  verified,      // Verification badges
}

/// Badge Rarity
enum BadgeRarity {
  common,
  uncommon,
  rare,
  epic,
  legendary,
  mythic,
}

/// User Badge - Badge earned by user
class UserBadge extends Equatable {
  final String id;
  final String odId;
  final String badgeId;
  final DateTime earnedAt;
  final bool isDisplayed;  // Currently shown on profile
  final int displayPosition; // Position on profile (1-3)
  final String? source; // achievement_id, level, event_id

  const UserBadge({
    required this.id,
    required this.odId,
    required this.badgeId,
    required this.earnedAt,
    this.isDisplayed = false,
    this.displayPosition = 0,
    this.source,
  });

  @override
  List<Object?> get props => [
        id,
        odId,
        badgeId,
        earnedAt,
        isDisplayed,
        displayPosition,
        source,
      ];
}

/// Badge with user data combined
class UserBadgeWithDetails extends Equatable {
  final UserBadge userBadge;
  final Badge badge;

  const UserBadgeWithDetails({
    required this.userBadge,
    required this.badge,
  });

  @override
  List<Object?> get props => [userBadge, badge];
}

/// Standard Badges
class Badges {
  // Level Badges
  static const Badge bronzeFrame = Badge(
    badgeId: 'bronze_frame',
    name: 'Bronze Frame',
    description: 'Reach level 5',
    iconUrl: 'assets/badges/bronze_frame.png',
    category: BadgeCategory.level,
    rarity: BadgeRarity.common,
    displayOrder: 1,
  );

  static const Badge silverFrame = Badge(
    badgeId: 'silver_frame',
    name: 'Silver Frame',
    description: 'Reach level 10',
    iconUrl: 'assets/badges/silver_frame.png',
    category: BadgeCategory.level,
    rarity: BadgeRarity.uncommon,
    displayOrder: 2,
  );

  static const Badge goldFrame = Badge(
    badgeId: 'gold_frame',
    name: 'Gold Frame',
    description: 'Reach level 25',
    iconUrl: 'assets/badges/gold_frame.png',
    category: BadgeCategory.level,
    rarity: BadgeRarity.rare,
    displayOrder: 3,
  );

  static const Badge platinumFrame = Badge(
    badgeId: 'platinum_frame',
    name: 'Platinum Frame',
    description: 'Reach level 50',
    iconUrl: 'assets/badges/platinum_frame.png',
    category: BadgeCategory.level,
    rarity: BadgeRarity.epic,
    displayOrder: 4,
  );

  static const Badge diamondFrame = Badge(
    badgeId: 'diamond_frame',
    name: 'Diamond Frame',
    description: 'Reach level 75',
    iconUrl: 'assets/badges/diamond_frame.png',
    category: BadgeCategory.level,
    rarity: BadgeRarity.legendary,
    displayOrder: 5,
  );

  static const Badge legendaryFrame = Badge(
    badgeId: 'legendary_frame',
    name: 'Legendary Frame',
    description: 'Reach level 100',
    iconUrl: 'assets/badges/legendary_frame.png',
    category: BadgeCategory.level,
    rarity: BadgeRarity.mythic,
    isAnimated: true,
    animationUrl: 'assets/badges/legendary_frame.json',
    displayOrder: 6,
  );

  // Verification Badges
  static const Badge verifiedUser = Badge(
    badgeId: 'verified_user',
    name: 'Verified',
    description: 'Photo verified user',
    iconUrl: 'assets/badges/verified.png',
    category: BadgeCategory.verified,
    rarity: BadgeRarity.uncommon,
    displayOrder: 100,
  );

  static const Badge premiumMember = Badge(
    badgeId: 'premium_member',
    name: 'Premium',
    description: 'Premium subscriber',
    iconUrl: 'assets/badges/premium.png',
    category: BadgeCategory.premium,
    rarity: BadgeRarity.rare,
    displayOrder: 99,
  );

  static const Badge vipCrown = Badge(
    badgeId: 'vip_crown',
    name: 'VIP Crown',
    description: 'Reached VIP status (Level 50+)',
    iconUrl: 'assets/badges/vip_crown.png',
    category: BadgeCategory.special,
    rarity: BadgeRarity.epic,
    isAnimated: true,
    animationUrl: 'assets/badges/vip_crown.json',
    displayOrder: 98,
  );

  // Achievement Badges
  static const Badge socialButterfly = Badge(
    badgeId: 'social_butterfly_badge',
    name: 'Social Butterfly',
    description: 'Maintain 20+ active conversations',
    iconUrl: 'assets/badges/social_butterfly.png',
    category: BadgeCategory.achievement,
    rarity: BadgeRarity.epic,
    displayOrder: 10,
  );

  static const Badge heartbreaker = Badge(
    badgeId: 'heartbreaker_badge',
    name: 'Heartbreaker',
    description: 'Received 100+ likes',
    iconUrl: 'assets/badges/heartbreaker.png',
    category: BadgeCategory.achievement,
    rarity: BadgeRarity.rare,
    displayOrder: 11,
  );

  static const Badge globeTrotter = Badge(
    badgeId: 'globe_trotter_badge',
    name: 'Globe Trotter',
    description: 'Matched with 10+ countries',
    iconUrl: 'assets/badges/globe_trotter.png',
    category: BadgeCategory.achievement,
    rarity: BadgeRarity.epic,
    displayOrder: 12,
  );

  static const Badge videoStar = Badge(
    badgeId: 'video_star_badge',
    name: 'Video Star',
    description: 'Completed 5+ video calls',
    iconUrl: 'assets/badges/video_star.png',
    category: BadgeCategory.achievement,
    rarity: BadgeRarity.rare,
    displayOrder: 13,
  );

  static const Badge superStar = Badge(
    badgeId: 'super_star_badge',
    name: 'Super Star',
    description: 'Received 50+ super likes',
    iconUrl: 'assets/badges/super_star.png',
    category: BadgeCategory.achievement,
    rarity: BadgeRarity.legendary,
    isAnimated: true,
    animationUrl: 'assets/badges/super_star.json',
    displayOrder: 14,
  );

  static const Badge centurion = Badge(
    badgeId: 'centurion_badge',
    name: 'Centurion',
    description: '100+ matches',
    iconUrl: 'assets/badges/centurion.png',
    category: BadgeCategory.achievement,
    rarity: BadgeRarity.epic,
    displayOrder: 15,
  );

  static const Badge millennium = Badge(
    badgeId: 'millennium_badge',
    name: 'Millennium',
    description: '1000+ matches',
    iconUrl: 'assets/badges/millennium.png',
    category: BadgeCategory.achievement,
    rarity: BadgeRarity.mythic,
    isAnimated: true,
    animationUrl: 'assets/badges/millennium.json',
    displayOrder: 16,
  );

  static const Badge perfectWeek = Badge(
    badgeId: 'perfect_week_badge',
    name: 'Perfect Week',
    description: 'Completed all daily challenges for 7 days',
    iconUrl: 'assets/badges/perfect_week.png',
    category: BadgeCategory.achievement,
    rarity: BadgeRarity.epic,
    displayOrder: 17,
  );

  static const Badge streakMaster = Badge(
    badgeId: 'streak_master_badge',
    name: 'Streak Master',
    description: '30-day login streak',
    iconUrl: 'assets/badges/streak_master.png',
    category: BadgeCategory.achievement,
    rarity: BadgeRarity.legendary,
    displayOrder: 18,
  );

  static const Badge earlyBird = Badge(
    badgeId: 'early_bird_badge',
    name: 'Early Bird',
    description: 'One of the first 1000 users',
    iconUrl: 'assets/badges/early_bird.png',
    category: BadgeCategory.special,
    rarity: BadgeRarity.legendary,
    displayOrder: 19,
  );

  // Seasonal Badges
  static const Badge cupid = Badge(
    badgeId: 'cupid_badge',
    name: 'Cupid',
    description: 'Valentine\'s event participant',
    iconUrl: 'assets/badges/cupid.png',
    category: BadgeCategory.seasonal,
    rarity: BadgeRarity.rare,
    displayOrder: 50,
  );

  static const Badge summerLove = Badge(
    badgeId: 'summer_love_badge',
    name: 'Summer Love',
    description: 'Summer event participant',
    iconUrl: 'assets/badges/summer_love.png',
    category: BadgeCategory.seasonal,
    rarity: BadgeRarity.rare,
    displayOrder: 51,
  );

  static const Badge santa = Badge(
    badgeId: 'santa_badge',
    name: 'Santa\'s Helper',
    description: 'Holiday event participant',
    iconUrl: 'assets/badges/santa.png',
    category: BadgeCategory.seasonal,
    rarity: BadgeRarity.rare,
    displayOrder: 52,
  );

  // Special Badges
  static const Badge referralChampion = Badge(
    badgeId: 'referral_champion_badge',
    name: 'Referral Champion',
    description: 'Referred 10+ friends',
    iconUrl: 'assets/badges/referral_champion.png',
    category: BadgeCategory.special,
    rarity: BadgeRarity.epic,
    displayOrder: 60,
  );

  static const Badge languageMaster = Badge(
    badgeId: 'language_master_badge',
    name: 'Language Master',
    description: 'Completed language learning',
    iconUrl: 'assets/badges/language_master.png',
    category: BadgeCategory.special,
    rarity: BadgeRarity.rare,
    displayOrder: 61,
  );

  static const Badge leaderboardChampion = Badge(
    badgeId: 'leaderboard_champion_badge',
    name: 'Leaderboard Champion',
    description: 'Top 10 on leaderboard',
    iconUrl: 'assets/badges/leaderboard_champion.png',
    category: BadgeCategory.special,
    rarity: BadgeRarity.legendary,
    isAnimated: true,
    animationUrl: 'assets/badges/leaderboard_champion.json',
    displayOrder: 62,
  );

  /// Get all badges
  static List<Badge> get all => [
        bronzeFrame,
        silverFrame,
        goldFrame,
        platinumFrame,
        diamondFrame,
        legendaryFrame,
        verifiedUser,
        premiumMember,
        vipCrown,
        socialButterfly,
        heartbreaker,
        globeTrotter,
        videoStar,
        superStar,
        centurion,
        millennium,
        perfectWeek,
        streakMaster,
        earlyBird,
        cupid,
        summerLove,
        santa,
        referralChampion,
        languageMaster,
        leaderboardChampion,
      ];

  /// Get badge by ID
  static Badge? getById(String badgeId) {
    try {
      return all.firstWhere((b) => b.badgeId == badgeId);
    } catch (e) {
      return null;
    }
  }

  /// Get badges by category
  static List<Badge> getByCategory(BadgeCategory category) {
    return all.where((b) => b.category == category).toList();
  }

  /// Get badges by rarity
  static List<Badge> getByRarity(BadgeRarity rarity) {
    return all.where((b) => b.rarity == rarity).toList();
  }
}

extension BadgeCategoryExtension on BadgeCategory {
  String get displayName {
    switch (this) {
      case BadgeCategory.achievement:
        return 'Achievement';
      case BadgeCategory.level:
        return 'Level';
      case BadgeCategory.seasonal:
        return 'Seasonal';
      case BadgeCategory.premium:
        return 'Premium';
      case BadgeCategory.special:
        return 'Special';
      case BadgeCategory.verified:
        return 'Verified';
    }
  }
}

extension BadgeRarityExtension on BadgeRarity {
  String get displayName {
    switch (this) {
      case BadgeRarity.common:
        return 'Common';
      case BadgeRarity.uncommon:
        return 'Uncommon';
      case BadgeRarity.rare:
        return 'Rare';
      case BadgeRarity.epic:
        return 'Epic';
      case BadgeRarity.legendary:
        return 'Legendary';
      case BadgeRarity.mythic:
        return 'Mythic';
    }
  }

  int get colorValue {
    switch (this) {
      case BadgeRarity.common:
        return 0xFF9E9E9E; // Gray
      case BadgeRarity.uncommon:
        return 0xFF4CAF50; // Green
      case BadgeRarity.rare:
        return 0xFF2196F3; // Blue
      case BadgeRarity.epic:
        return 0xFF9C27B0; // Purple
      case BadgeRarity.legendary:
        return 0xFFFFD700; // Gold
      case BadgeRarity.mythic:
        return 0xFFFF4500; // Orange-Red
    }
  }
}
