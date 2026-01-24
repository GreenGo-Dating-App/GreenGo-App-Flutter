import 'package:equatable/equatable.dart';
import '../../../membership/domain/entities/membership.dart';

/// Tier Configuration Entity
/// Admin-configurable tier rules stored in Firestore
class TierConfig extends Equatable {
  final String configId;
  final MembershipTier tier;
  final MembershipRules rules;
  final String? updatedBy;
  final DateTime updatedAt;
  final DateTime createdAt;
  final bool isActive;

  const TierConfig({
    required this.configId,
    required this.tier,
    required this.rules,
    this.updatedBy,
    required this.updatedAt,
    required this.createdAt,
    this.isActive = true,
  });

  /// Create config with default rules for a tier
  factory TierConfig.withDefaults(MembershipTier tier) {
    final now = DateTime.now();
    return TierConfig(
      configId: 'tier_${tier.value.toLowerCase()}',
      tier: tier,
      rules: MembershipRules.getDefaultsForTier(tier),
      updatedAt: now,
      createdAt: now,
      isActive: true,
    );
  }

  TierConfig copyWith({
    String? configId,
    MembershipTier? tier,
    MembershipRules? rules,
    String? updatedBy,
    DateTime? updatedAt,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return TierConfig(
      configId: configId ?? this.configId,
      tier: tier ?? this.tier,
      rules: rules ?? this.rules,
      updatedBy: updatedBy ?? this.updatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  List<Object?> get props => [
        configId,
        tier,
        rules,
        updatedBy,
        updatedAt,
        createdAt,
        isActive,
      ];
}

/// Singleton provider for tier configurations
/// Caches tier configs loaded from Firestore at app startup
class TierConfigProvider {
  static final TierConfigProvider _instance = TierConfigProvider._internal();
  factory TierConfigProvider() => _instance;
  TierConfigProvider._internal();

  final Map<MembershipTier, TierConfig> _configs = {};
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  /// Load configurations from a list
  void loadConfigs(List<TierConfig> configs) {
    _configs.clear();
    for (final config in configs) {
      if (config.isActive) {
        _configs[config.tier] = config;
      }
    }
    _isLoaded = true;
  }

  /// Get rules for a specific tier
  MembershipRules getRulesForTier(MembershipTier tier) {
    if (_configs.containsKey(tier)) {
      return _configs[tier]!.rules;
    }
    // Fall back to hardcoded defaults if not loaded
    return MembershipRules.getDefaultsForTier(tier);
  }

  /// Get full config for a tier
  TierConfig? getConfig(MembershipTier tier) {
    return _configs[tier];
  }

  /// Get all loaded configs
  List<TierConfig> getAllConfigs() {
    return _configs.values.toList();
  }

  /// Update a single config in cache
  void updateConfig(TierConfig config) {
    _configs[config.tier] = config;
  }

  /// Clear all configs
  void clear() {
    _configs.clear();
    _isLoaded = false;
  }

  /// Check if tier has specific feature enabled
  bool hasFeature(MembershipTier tier, String feature) {
    final rules = getRulesForTier(tier);
    switch (feature) {
      case 'seeWhoLiked':
        return rules.canSeeWhoLiked;
      case 'advancedFilters':
        return rules.canUseAdvancedFilters;
      case 'locationFilter':
        return rules.canFilterByLocation;
      case 'interestFilter':
        return rules.canFilterByInterests;
      case 'languageFilter':
        return rules.canFilterByLanguage;
      case 'verificationFilter':
        return rules.canFilterByVerification;
      case 'boostProfile':
        return rules.canBoostProfile;
      case 'undoSwipe':
        return rules.canUndoSwipe;
      case 'sendMedia':
        return rules.canSendMedia;
      case 'readReceipts':
        return rules.canSeeReadReceipts;
      case 'incognitoMode':
        return rules.canUseIncognitoMode;
      case 'profileVisitors':
        return rules.canSeeProfileVisitors;
      case 'videoChat':
        return rules.canUseVideoChat;
      default:
        return false;
    }
  }

  /// Get limit value for tier
  int getLimit(MembershipTier tier, String limitType) {
    final rules = getRulesForTier(tier);
    switch (limitType) {
      case 'dailyMessages':
        return rules.dailyMessageLimit;
      case 'dailySwipes':
        return rules.dailySwipeLimit;
      case 'dailySuperLikes':
        return rules.dailySuperLikeLimit;
      case 'monthlyBoosts':
        return rules.monthlyFreeBoosts;
      case 'matchPriority':
        return rules.matchPriority;
      default:
        return 0;
    }
  }

  /// Check if limit is unlimited (-1)
  bool isUnlimited(MembershipTier tier, String limitType) {
    return getLimit(tier, limitType) == -1;
  }
}

/// Reward configuration for tiers
/// Admin-configurable coin allowances and rewards per tier
class TierRewardConfig extends Equatable {
  final MembershipTier tier;
  final int monthlyCoins;
  final int dailyLoginCoins;
  final int dailyLoginXP;
  final double xpMultiplier;
  final int referralBonus;

  const TierRewardConfig({
    required this.tier,
    this.monthlyCoins = 0,
    this.dailyLoginCoins = 10,
    this.dailyLoginXP = 5,
    this.xpMultiplier = 1.0,
    this.referralBonus = 100,
  });

  /// Default reward configs per tier
  static TierRewardConfig getDefaults(MembershipTier tier) {
    switch (tier) {
      case MembershipTier.free:
        return const TierRewardConfig(
          tier: MembershipTier.free,
          monthlyCoins: 0,
          dailyLoginCoins: 5,
          dailyLoginXP: 5,
          xpMultiplier: 1.0,
          referralBonus: 50,
        );
      case MembershipTier.silver:
        return const TierRewardConfig(
          tier: MembershipTier.silver,
          monthlyCoins: 50,
          dailyLoginCoins: 10,
          dailyLoginXP: 10,
          xpMultiplier: 1.25,
          referralBonus: 100,
        );
      case MembershipTier.gold:
        return const TierRewardConfig(
          tier: MembershipTier.gold,
          monthlyCoins: 100,
          dailyLoginCoins: 15,
          dailyLoginXP: 15,
          xpMultiplier: 1.5,
          referralBonus: 150,
        );
      case MembershipTier.platinum:
        return const TierRewardConfig(
          tier: MembershipTier.platinum,
          monthlyCoins: 200,
          dailyLoginCoins: 25,
          dailyLoginXP: 25,
          xpMultiplier: 2.0,
          referralBonus: 250,
        );
      case MembershipTier.test:
        // Test users get same rewards as Platinum
        return const TierRewardConfig(
          tier: MembershipTier.test,
          monthlyCoins: 200,
          dailyLoginCoins: 25,
          dailyLoginXP: 25,
          xpMultiplier: 2.0,
          referralBonus: 250,
        );
    }
  }

  @override
  List<Object?> get props => [
        tier,
        monthlyCoins,
        dailyLoginCoins,
        dailyLoginXP,
        xpMultiplier,
        referralBonus,
      ];
}
