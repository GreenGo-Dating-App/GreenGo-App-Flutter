import 'package:equatable/equatable.dart';

/// Combo System - Rewards for consecutive actions
class ComboSystem extends Equatable {
  final String odId;
  final int currentCombo;
  final int maxCombo;
  final ComboType activeComboType;
  final DateTime? comboStartedAt;
  final DateTime? lastActionAt;
  final int comboTimeoutMinutes;

  const ComboSystem({
    required this.odId,
    this.currentCombo = 0,
    this.maxCombo = 0,
    this.activeComboType = ComboType.none,
    this.comboStartedAt,
    this.lastActionAt,
    this.comboTimeoutMinutes = 5,
  });

  /// Check if combo is still active
  bool get isComboActive {
    if (lastActionAt == null) return false;
    final now = DateTime.now();
    return now.difference(lastActionAt!).inMinutes < comboTimeoutMinutes;
  }

  /// Get combo multiplier
  double get comboMultiplier {
    if (currentCombo < 2) return 1.0;
    if (currentCombo < 5) return 1.25;
    if (currentCombo < 10) return 1.5;
    if (currentCombo < 20) return 2.0;
    if (currentCombo < 50) return 2.5;
    return 3.0;
  }

  /// Get XP bonus from combo
  int getXPBonus(int baseXP) {
    return (baseXP * comboMultiplier).round() - baseXP;
  }

  @override
  List<Object?> get props => [
        odId,
        currentCombo,
        maxCombo,
        activeComboType,
        comboStartedAt,
        lastActionAt,
        comboTimeoutMinutes,
      ];
}

/// Combo Types
enum ComboType {
  none,
  swipe,      // Consecutive swipes
  message,    // Consecutive messages sent
  match,      // Consecutive matches
  login,      // Consecutive daily logins (streak)
  challenge,  // Consecutive challenges completed
}

/// Combo Milestone - Rewards at certain combo levels
class ComboMilestone extends Equatable {
  final int comboCount;
  final String name;
  final String rewardType;
  final int rewardAmount;
  final String? badgeId;

  const ComboMilestone({
    required this.comboCount,
    required this.name,
    required this.rewardType,
    required this.rewardAmount,
    this.badgeId,
  });

  @override
  List<Object?> get props => [comboCount, name, rewardType, rewardAmount, badgeId];
}

/// Standard Combo Milestones
class ComboMilestones {
  static const List<ComboMilestone> swipeMilestones = [
    ComboMilestone(
      comboCount: 10,
      name: 'Swipe Streak 10',
      rewardType: 'xp',
      rewardAmount: 25,
    ),
    ComboMilestone(
      comboCount: 25,
      name: 'Swipe Streak 25',
      rewardType: 'xp',
      rewardAmount: 50,
    ),
    ComboMilestone(
      comboCount: 50,
      name: 'Swipe Master',
      rewardType: 'coins',
      rewardAmount: 25,
    ),
    ComboMilestone(
      comboCount: 100,
      name: 'Swipe Legend',
      rewardType: 'coins',
      rewardAmount: 50,
    ),
  ];

  static const List<ComboMilestone> messageMilestones = [
    ComboMilestone(
      comboCount: 5,
      name: 'Chat Streak 5',
      rewardType: 'xp',
      rewardAmount: 15,
    ),
    ComboMilestone(
      comboCount: 15,
      name: 'Chat Streak 15',
      rewardType: 'xp',
      rewardAmount: 35,
    ),
    ComboMilestone(
      comboCount: 30,
      name: 'Chat Master',
      rewardType: 'coins',
      rewardAmount: 30,
    ),
  ];

  static const List<ComboMilestone> loginMilestones = [
    ComboMilestone(
      comboCount: 3,
      name: '3-Day Streak',
      rewardType: 'xp',
      rewardAmount: 30,
    ),
    ComboMilestone(
      comboCount: 7,
      name: 'Week Warrior',
      rewardType: 'coins',
      rewardAmount: 50,
    ),
    ComboMilestone(
      comboCount: 14,
      name: 'Two Week Champion',
      rewardType: 'coins',
      rewardAmount: 100,
    ),
    ComboMilestone(
      comboCount: 30,
      name: 'Monthly Master',
      rewardType: 'coins',
      rewardAmount: 250,
      badgeId: 'streak_master_badge',
    ),
    ComboMilestone(
      comboCount: 90,
      name: 'Quarter Legend',
      rewardType: 'coins',
      rewardAmount: 500,
    ),
    ComboMilestone(
      comboCount: 365,
      name: 'Year of Dedication',
      rewardType: 'coins',
      rewardAmount: 2500,
      badgeId: 'year_dedication_badge',
    ),
  ];

  /// Get milestones for combo type
  static List<ComboMilestone> getMilestones(ComboType type) {
    switch (type) {
      case ComboType.swipe:
        return swipeMilestones;
      case ComboType.message:
        return messageMilestones;
      case ComboType.login:
        return loginMilestones;
      default:
        return [];
    }
  }

  /// Get next milestone for combo
  static ComboMilestone? getNextMilestone(ComboType type, int currentCombo) {
    final milestones = getMilestones(type);
    for (final milestone in milestones) {
      if (milestone.comboCount > currentCombo) {
        return milestone;
      }
    }
    return null;
  }
}

/// Power-Up Entity
class PowerUp extends Equatable {
  final String powerUpId;
  final String name;
  final String description;
  final String iconUrl;
  final PowerUpType type;
  final int durationMinutes;
  final double effectMultiplier;
  final int coinCost;
  final bool isPremiumOnly;

  const PowerUp({
    required this.powerUpId,
    required this.name,
    required this.description,
    required this.iconUrl,
    required this.type,
    required this.durationMinutes,
    this.effectMultiplier = 1.0,
    required this.coinCost,
    this.isPremiumOnly = false,
  });

  @override
  List<Object?> get props => [
        powerUpId,
        name,
        description,
        iconUrl,
        type,
        durationMinutes,
        effectMultiplier,
        coinCost,
        isPremiumOnly,
      ];
}

/// Power-Up Types
enum PowerUpType {
  xpBoost,         // Increase XP gain
  coinBoost,       // Increase coin gain
  profileBoost,    // Increase profile visibility
  superLikeBoost,  // Extra super likes
  matchBoost,      // Higher match rate
  invisibleMode,   // Browse without being seen
  rewind,          // Undo last swipe
  spotlight,       // Top profile in area
}

/// Active Power-Up
class ActivePowerUp extends Equatable {
  final String id;
  final String odId;
  final String powerUpId;
  final DateTime activatedAt;
  final DateTime expiresAt;
  final bool isActive;

  const ActivePowerUp({
    required this.id,
    required this.odId,
    required this.powerUpId,
    required this.activatedAt,
    required this.expiresAt,
    this.isActive = true,
  });

  /// Get remaining time
  Duration get timeRemaining {
    final now = DateTime.now();
    if (now.isAfter(expiresAt)) return Duration.zero;
    return expiresAt.difference(now);
  }

  /// Check if expired
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  @override
  List<Object?> get props => [
        id,
        odId,
        powerUpId,
        activatedAt,
        expiresAt,
        isActive,
      ];
}

/// User Power-Up Inventory
class UserPowerUpInventory extends Equatable {
  final String odId;
  final Map<String, int> powerUps; // powerUpId -> quantity
  final List<ActivePowerUp> activePowerUps;

  const UserPowerUpInventory({
    required this.odId,
    required this.powerUps,
    this.activePowerUps = const [],
  });

  /// Get quantity of a power-up
  int getQuantity(String powerUpId) => powerUps[powerUpId] ?? 0;

  /// Check if has power-up
  bool hasPowerUp(String powerUpId) => getQuantity(powerUpId) > 0;

  /// Check if power-up is active
  bool isPowerUpActive(String powerUpId) {
    return activePowerUps.any((p) => p.powerUpId == powerUpId && !p.isExpired);
  }

  @override
  List<Object?> get props => [odId, powerUps, activePowerUps];
}

/// Standard Power-Ups
class PowerUps {
  static const PowerUp xpBoost2x = PowerUp(
    powerUpId: 'xp_boost_2x',
    name: 'Double XP',
    description: 'Earn 2x XP for 30 minutes',
    iconUrl: 'assets/powerups/xp_boost.png',
    type: PowerUpType.xpBoost,
    durationMinutes: 30,
    effectMultiplier: 2.0,
    coinCost: 50,
  );

  static const PowerUp xpBoost3x = PowerUp(
    powerUpId: 'xp_boost_3x',
    name: 'Triple XP',
    description: 'Earn 3x XP for 30 minutes',
    iconUrl: 'assets/powerups/xp_boost_3x.png',
    type: PowerUpType.xpBoost,
    durationMinutes: 30,
    effectMultiplier: 3.0,
    coinCost: 100,
    isPremiumOnly: true,
  );

  static const PowerUp profileBoost = PowerUp(
    powerUpId: 'profile_boost',
    name: 'Profile Boost',
    description: 'Be seen by more people for 30 minutes',
    iconUrl: 'assets/powerups/profile_boost.png',
    type: PowerUpType.profileBoost,
    durationMinutes: 30,
    effectMultiplier: 3.0,
    coinCost: 75,
  );

  static const PowerUp spotlight = PowerUp(
    powerUpId: 'spotlight',
    name: 'Spotlight',
    description: 'Be the top profile in your area for 1 hour',
    iconUrl: 'assets/powerups/spotlight.png',
    type: PowerUpType.spotlight,
    durationMinutes: 60,
    effectMultiplier: 5.0,
    coinCost: 150,
  );

  static const PowerUp invisibleMode = PowerUp(
    powerUpId: 'invisible_mode',
    name: 'Invisible Mode',
    description: 'Browse profiles without being seen for 1 hour',
    iconUrl: 'assets/powerups/invisible.png',
    type: PowerUpType.invisibleMode,
    durationMinutes: 60,
    coinCost: 100,
    isPremiumOnly: true,
  );

  static const PowerUp rewind = PowerUp(
    powerUpId: 'rewind',
    name: 'Rewind',
    description: 'Undo your last swipe',
    iconUrl: 'assets/powerups/rewind.png',
    type: PowerUpType.rewind,
    durationMinutes: 0, // Instant use
    coinCost: 25,
  );

  static const PowerUp matchBoost = PowerUp(
    powerUpId: 'match_boost',
    name: 'Match Boost',
    description: 'Higher chance of matching for 30 minutes',
    iconUrl: 'assets/powerups/match_boost.png',
    type: PowerUpType.matchBoost,
    durationMinutes: 30,
    effectMultiplier: 1.5,
    coinCost: 100,
  );

  static const PowerUp superLikePack = PowerUp(
    powerUpId: 'super_like_pack',
    name: 'Super Like Pack',
    description: '5 extra super likes',
    iconUrl: 'assets/powerups/super_like_pack.png',
    type: PowerUpType.superLikeBoost,
    durationMinutes: 0, // Adds to inventory
    coinCost: 75,
  );

  /// Get all power-ups
  static List<PowerUp> get all => [
        xpBoost2x,
        xpBoost3x,
        profileBoost,
        spotlight,
        invisibleMode,
        rewind,
        matchBoost,
        superLikePack,
      ];

  /// Get power-up by ID
  static PowerUp? getById(String powerUpId) {
    try {
      return all.firstWhere((p) => p.powerUpId == powerUpId);
    } catch (e) {
      return null;
    }
  }

  /// Get free power-ups
  static List<PowerUp> get free => all.where((p) => !p.isPremiumOnly).toList();

  /// Get premium power-ups
  static List<PowerUp> get premium => all.where((p) => p.isPremiumOnly).toList();
}

extension PowerUpTypeExtension on PowerUpType {
  String get displayName {
    switch (this) {
      case PowerUpType.xpBoost:
        return 'XP Boost';
      case PowerUpType.coinBoost:
        return 'Coin Boost';
      case PowerUpType.profileBoost:
        return 'Profile Boost';
      case PowerUpType.superLikeBoost:
        return 'Super Likes';
      case PowerUpType.matchBoost:
        return 'Match Boost';
      case PowerUpType.invisibleMode:
        return 'Invisible';
      case PowerUpType.rewind:
        return 'Rewind';
      case PowerUpType.spotlight:
        return 'Spotlight';
    }
  }
}
