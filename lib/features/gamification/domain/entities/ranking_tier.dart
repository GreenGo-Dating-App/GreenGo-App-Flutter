import 'package:equatable/equatable.dart';

/// Ranking Tier Entity - Competitive ranking system
class RankingTier extends Equatable {
  final String tierId;
  final String name;
  final String description;
  final String iconUrl;
  final RankDivision division;
  final int tier; // 1-5 within division (5 = highest)
  final int minPoints;
  final int maxPoints;
  final List<TierPerk> perks;
  final int colorValue;

  const RankingTier({
    required this.tierId,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.division,
    required this.tier,
    required this.minPoints,
    required this.maxPoints,
    required this.perks,
    required this.colorValue,
  });

  /// Get full tier name (e.g., "Gold III")
  String get fullName => '$name ${_romanNumeral(tier)}';

  String _romanNumeral(int num) {
    switch (num) {
      case 1:
        return 'I';
      case 2:
        return 'II';
      case 3:
        return 'III';
      case 4:
        return 'IV';
      case 5:
        return 'V';
      default:
        return '';
    }
  }

  @override
  List<Object?> get props => [
        tierId,
        name,
        description,
        iconUrl,
        division,
        tier,
        minPoints,
        maxPoints,
        perks,
        colorValue,
      ];
}

/// Rank Divisions
enum RankDivision {
  bronze,
  silver,
  gold,
  platinum,
  diamond,
  master,
  grandmaster,
  legend,
}

/// Tier Perk
class TierPerk extends Equatable {
  final String perkId;
  final String name;
  final String description;
  final String iconName;

  const TierPerk({
    required this.perkId,
    required this.name,
    required this.description,
    required this.iconName,
  });

  @override
  List<Object?> get props => [perkId, name, description, iconName];
}

/// User Rank
class UserRank extends Equatable {
  final String odId;
  final RankDivision division;
  final int tier;
  final int rankPoints;
  final int globalRank;
  final int regionalRank;
  final String region;
  final int wins;
  final int losses;
  final int currentWinStreak;
  final int bestWinStreak;
  final DateTime seasonStartDate;
  final DateTime? lastRankUpdate;

  const UserRank({
    required this.odId,
    required this.division,
    required this.tier,
    required this.rankPoints,
    this.globalRank = 0,
    this.regionalRank = 0,
    this.region = 'global',
    this.wins = 0,
    this.losses = 0,
    this.currentWinStreak = 0,
    this.bestWinStreak = 0,
    required this.seasonStartDate,
    this.lastRankUpdate,
  });

  /// Get win rate
  double get winRate {
    final total = wins + losses;
    if (total == 0) return 0.0;
    return wins / total;
  }

  /// Get win rate percentage
  String get winRatePercent => '${(winRate * 100).toStringAsFixed(1)}%';

  /// Get tier ID
  String get tierId => '${division.name}_$tier';

  @override
  List<Object?> get props => [
        odId,
        division,
        tier,
        rankPoints,
        globalRank,
        regionalRank,
        region,
        wins,
        losses,
        currentWinStreak,
        bestWinStreak,
        seasonStartDate,
        lastRankUpdate,
      ];
}

/// Rank Season
class RankSeason extends Equatable {
  final String seasonId;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final List<SeasonReward> rewards;
  final bool isActive;

  const RankSeason({
    required this.seasonId,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.rewards,
    this.isActive = true,
  });

  /// Get days remaining
  int get daysRemaining {
    final now = DateTime.now();
    if (now.isAfter(endDate)) return 0;
    return endDate.difference(now).inDays;
  }

  /// Get progress percentage
  double get progressPercent {
    final now = DateTime.now();
    final total = endDate.difference(startDate).inDays;
    final elapsed = now.difference(startDate).inDays;
    return (elapsed / total * 100).clamp(0.0, 100.0);
  }

  @override
  List<Object?> get props => [
        seasonId,
        name,
        startDate,
        endDate,
        rewards,
        isActive,
      ];
}

/// Season Reward
class SeasonReward extends Equatable {
  final RankDivision requiredDivision;
  final String rewardType;
  final int amount;
  final String? itemId;
  final String description;

  const SeasonReward({
    required this.requiredDivision,
    required this.rewardType,
    required this.amount,
    this.itemId,
    required this.description,
  });

  @override
  List<Object?> get props => [requiredDivision, rewardType, amount, itemId, description];
}

/// Standard Ranking Tiers
class RankingTiers {
  // Bronze Tiers
  static RankingTier bronze(int tier) => RankingTier(
        tierId: 'bronze_$tier',
        name: 'Bronze',
        description: 'Starting rank for new players',
        iconUrl: 'assets/ranks/bronze.png',
        division: RankDivision.bronze,
        tier: tier,
        minPoints: (tier - 1) * 100,
        maxPoints: tier * 100 - 1,
        perks: const [],
        colorValue: 0xFFCD7F32,
      );

  // Silver Tiers
  static RankingTier silver(int tier) => RankingTier(
        tierId: 'silver_$tier',
        name: 'Silver',
        description: 'Intermediate rank',
        iconUrl: 'assets/ranks/silver.png',
        division: RankDivision.silver,
        tier: tier,
        minPoints: 500 + (tier - 1) * 100,
        maxPoints: 500 + tier * 100 - 1,
        perks: const [
          TierPerk(
            perkId: 'silver_badge',
            name: 'Silver Badge',
            description: 'Display silver badge on profile',
            iconName: 'military_tech',
          ),
        ],
        colorValue: 0xFFC0C0C0,
      );

  // Gold Tiers
  static RankingTier gold(int tier) => RankingTier(
        tierId: 'gold_$tier',
        name: 'Gold',
        description: 'Skilled player rank',
        iconUrl: 'assets/ranks/gold.png',
        division: RankDivision.gold,
        tier: tier,
        minPoints: 1000 + (tier - 1) * 150,
        maxPoints: 1000 + tier * 150 - 1,
        perks: const [
          TierPerk(
            perkId: 'gold_badge',
            name: 'Gold Badge',
            description: 'Display gold badge on profile',
            iconName: 'military_tech',
          ),
          TierPerk(
            perkId: 'gold_frame',
            name: 'Gold Frame',
            description: 'Exclusive gold profile frame',
            iconName: 'crop_free',
          ),
        ],
        colorValue: 0xFFFFD700,
      );

  // Platinum Tiers
  static RankingTier platinum(int tier) => RankingTier(
        tierId: 'platinum_$tier',
        name: 'Platinum',
        description: 'Expert rank',
        iconUrl: 'assets/ranks/platinum.png',
        division: RankDivision.platinum,
        tier: tier,
        minPoints: 1750 + (tier - 1) * 200,
        maxPoints: 1750 + tier * 200 - 1,
        perks: const [
          TierPerk(
            perkId: 'platinum_badge',
            name: 'Platinum Badge',
            description: 'Display platinum badge on profile',
            iconName: 'military_tech',
          ),
          TierPerk(
            perkId: 'platinum_frame',
            name: 'Platinum Frame',
            description: 'Exclusive platinum profile frame',
            iconName: 'crop_free',
          ),
          TierPerk(
            perkId: 'priority_matching',
            name: 'Priority Matching',
            description: 'Higher priority in match queue',
            iconName: 'priority_high',
          ),
        ],
        colorValue: 0xFFE5E4E2,
      );

  // Diamond Tiers
  static RankingTier diamond(int tier) => RankingTier(
        tierId: 'diamond_$tier',
        name: 'Diamond',
        description: 'Elite rank',
        iconUrl: 'assets/ranks/diamond.png',
        division: RankDivision.diamond,
        tier: tier,
        minPoints: 2750 + (tier - 1) * 250,
        maxPoints: 2750 + tier * 250 - 1,
        perks: const [
          TierPerk(
            perkId: 'diamond_badge',
            name: 'Diamond Badge',
            description: 'Display diamond badge on profile',
            iconName: 'diamond',
          ),
          TierPerk(
            perkId: 'diamond_frame',
            name: 'Diamond Frame',
            description: 'Exclusive animated diamond frame',
            iconName: 'crop_free',
          ),
          TierPerk(
            perkId: 'vip_matching',
            name: 'VIP Matching',
            description: 'Match with other diamond+ players',
            iconName: 'stars',
          ),
          TierPerk(
            perkId: 'exclusive_events',
            name: 'Exclusive Events',
            description: 'Access to diamond-only events',
            iconName: 'event',
          ),
        ],
        colorValue: 0xFFB9F2FF,
      );

  // Master Tier
  static RankingTier master(int tier) => RankingTier(
        tierId: 'master_$tier',
        name: 'Master',
        description: 'Top 1% of players',
        iconUrl: 'assets/ranks/master.png',
        division: RankDivision.master,
        tier: tier,
        minPoints: 4000 + (tier - 1) * 300,
        maxPoints: 4000 + tier * 300 - 1,
        perks: const [
          TierPerk(
            perkId: 'master_badge',
            name: 'Master Badge',
            description: 'Prestigious master badge',
            iconName: 'workspace_premium',
          ),
          TierPerk(
            perkId: 'master_frame',
            name: 'Master Frame',
            description: 'Exclusive animated master frame',
            iconName: 'crop_free',
          ),
          TierPerk(
            perkId: 'weekly_coins',
            name: 'Weekly Coins',
            description: '100 free coins weekly',
            iconName: 'monetization_on',
          ),
        ],
        colorValue: 0xFF9C27B0,
      );

  // Grandmaster Tier
  static RankingTier grandmaster(int tier) => RankingTier(
        tierId: 'grandmaster_$tier',
        name: 'Grandmaster',
        description: 'Top 0.1% of players',
        iconUrl: 'assets/ranks/grandmaster.png',
        division: RankDivision.grandmaster,
        tier: tier,
        minPoints: 5500 + (tier - 1) * 400,
        maxPoints: 5500 + tier * 400 - 1,
        perks: const [
          TierPerk(
            perkId: 'gm_badge',
            name: 'Grandmaster Badge',
            description: 'Legendary grandmaster badge',
            iconName: 'stars',
          ),
          TierPerk(
            perkId: 'gm_frame',
            name: 'Grandmaster Frame',
            description: 'Exclusive legendary frame',
            iconName: 'crop_free',
          ),
          TierPerk(
            perkId: 'monthly_premium',
            name: 'Free Premium',
            description: '7 days free premium monthly',
            iconName: 'card_membership',
          ),
        ],
        colorValue: 0xFFFF4500,
      );

  // Legend Tier (Top 100)
  static const RankingTier legend = RankingTier(
    tierId: 'legend',
    name: 'Legend',
    description: 'Top 100 players worldwide',
    iconUrl: 'assets/ranks/legend.png',
    division: RankDivision.legend,
    tier: 1,
    minPoints: 7500,
    maxPoints: 999999,
    perks: [
      TierPerk(
        perkId: 'legend_badge',
        name: 'Legend Badge',
        description: 'Mythical animated badge',
        iconName: 'auto_awesome',
      ),
      TierPerk(
        perkId: 'legend_frame',
        name: 'Legend Frame',
        description: 'Exclusive rainbow animated frame',
        iconName: 'crop_free',
      ),
      TierPerk(
        perkId: 'free_premium',
        name: 'Free Premium',
        description: 'Permanent premium status',
        iconName: 'card_membership',
      ),
      TierPerk(
        perkId: 'global_leaderboard',
        name: 'Leaderboard Fame',
        description: 'Featured on global leaderboard',
        iconName: 'leaderboard',
      ),
    ],
    colorValue: 0xFFFFD700,
  );

  /// Get all tiers
  static List<RankingTier> get all {
    final tiers = <RankingTier>[];

    // Bronze I-V
    for (int i = 1; i <= 5; i++) {
      tiers.add(bronze(i));
    }
    // Silver I-V
    for (int i = 1; i <= 5; i++) {
      tiers.add(silver(i));
    }
    // Gold I-V
    for (int i = 1; i <= 5; i++) {
      tiers.add(gold(i));
    }
    // Platinum I-V
    for (int i = 1; i <= 5; i++) {
      tiers.add(platinum(i));
    }
    // Diamond I-V
    for (int i = 1; i <= 5; i++) {
      tiers.add(diamond(i));
    }
    // Master I-V
    for (int i = 1; i <= 5; i++) {
      tiers.add(master(i));
    }
    // Grandmaster I-V
    for (int i = 1; i <= 5; i++) {
      tiers.add(grandmaster(i));
    }
    // Legend
    tiers.add(legend);

    return tiers;
  }

  /// Get tier by points
  static RankingTier getTierByPoints(int points) {
    for (final tier in all.reversed) {
      if (points >= tier.minPoints) {
        return tier;
      }
    }
    return bronze(1);
  }

  /// Get tier by ID
  static RankingTier? getById(String tierId) {
    try {
      return all.firstWhere((t) => t.tierId == tierId);
    } catch (e) {
      return null;
    }
  }
}

extension RankDivisionExtension on RankDivision {
  String get displayName {
    switch (this) {
      case RankDivision.bronze:
        return 'Bronze';
      case RankDivision.silver:
        return 'Silver';
      case RankDivision.gold:
        return 'Gold';
      case RankDivision.platinum:
        return 'Platinum';
      case RankDivision.diamond:
        return 'Diamond';
      case RankDivision.master:
        return 'Master';
      case RankDivision.grandmaster:
        return 'Grandmaster';
      case RankDivision.legend:
        return 'Legend';
    }
  }

  int get colorValue {
    switch (this) {
      case RankDivision.bronze:
        return 0xFFCD7F32;
      case RankDivision.silver:
        return 0xFFC0C0C0;
      case RankDivision.gold:
        return 0xFFFFD700;
      case RankDivision.platinum:
        return 0xFFE5E4E2;
      case RankDivision.diamond:
        return 0xFFB9F2FF;
      case RankDivision.master:
        return 0xFF9C27B0;
      case RankDivision.grandmaster:
        return 0xFFFF4500;
      case RankDivision.legend:
        return 0xFFFFD700;
    }
  }
}
