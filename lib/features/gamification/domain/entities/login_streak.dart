import 'package:equatable/equatable.dart';

/// Login Streak Entity
/// Tracks user daily login streaks and rewards
class LoginStreak extends Equatable {
  final String userId;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastLoginDate;
  final int totalDaysLoggedIn;
  final List<StreakMilestone> claimedMilestones;
  final DateTime createdAt;
  final DateTime updatedAt;

  const LoginStreak({
    required this.userId,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastLoginDate,
    this.totalDaysLoggedIn = 0,
    this.claimedMilestones = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  /// Check if user logged in today
  bool get hasLoggedInToday {
    if (lastLoginDate == null) return false;
    final now = DateTime.now();
    return lastLoginDate!.year == now.year &&
        lastLoginDate!.month == now.month &&
        lastLoginDate!.day == now.day;
  }

  /// Check if streak is still valid (logged in yesterday or today)
  bool get isStreakActive {
    if (lastLoginDate == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastLogin = DateTime(
      lastLoginDate!.year,
      lastLoginDate!.month,
      lastLoginDate!.day,
    );
    final difference = today.difference(lastLogin).inDays;
    return difference <= 1;
  }

  /// Get next milestone to achieve
  StreakMilestone? get nextMilestone {
    for (final milestone in StreakMilestones.all) {
      if (currentStreak < milestone.daysRequired &&
          !claimedMilestones.any((m) => m.id == milestone.id)) {
        return milestone;
      }
    }
    return null;
  }

  /// Get available (unclaimed) milestones that user has achieved
  List<StreakMilestone> get unclaimedMilestones {
    return StreakMilestones.all.where((milestone) {
      return currentStreak >= milestone.daysRequired &&
          !claimedMilestones.any((m) => m.id == milestone.id);
    }).toList();
  }

  /// Days until next milestone
  int? get daysUntilNextMilestone {
    final next = nextMilestone;
    if (next == null) return null;
    return next.daysRequired - currentStreak;
  }

  LoginStreak copyWith({
    String? userId,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastLoginDate,
    int? totalDaysLoggedIn,
    List<StreakMilestone>? claimedMilestones,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LoginStreak(
      userId: userId ?? this.userId,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastLoginDate: lastLoginDate ?? this.lastLoginDate,
      totalDaysLoggedIn: totalDaysLoggedIn ?? this.totalDaysLoggedIn,
      claimedMilestones: claimedMilestones ?? this.claimedMilestones,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        userId,
        currentStreak,
        longestStreak,
        lastLoginDate,
        totalDaysLoggedIn,
        claimedMilestones,
        createdAt,
        updatedAt,
      ];
}

/// Streak Milestone Definition
class StreakMilestone extends Equatable {
  final String id;
  final String name;
  final String description;
  final int daysRequired;
  final int coinReward;
  final int xpReward;
  final String? badgeId;
  final String iconAsset;

  const StreakMilestone({
    required this.id,
    required this.name,
    required this.description,
    required this.daysRequired,
    required this.coinReward,
    required this.xpReward,
    this.badgeId,
    required this.iconAsset,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        daysRequired,
        coinReward,
        xpReward,
        badgeId,
        iconAsset,
      ];
}

/// Predefined Streak Milestones
class StreakMilestones {
  static const StreakMilestone threeDays = StreakMilestone(
    id: 'streak_3',
    name: 'Getting Started',
    description: 'Log in for 3 consecutive days',
    daysRequired: 3,
    coinReward: 25,
    xpReward: 30,
    iconAsset: 'assets/icons/streak_3.png',
  );

  static const StreakMilestone sevenDays = StreakMilestone(
    id: 'streak_7',
    name: 'Week Warrior',
    description: 'Log in for 7 consecutive days',
    daysRequired: 7,
    coinReward: 50,
    xpReward: 75,
    badgeId: 'weekly_dedication',
    iconAsset: 'assets/icons/streak_7.png',
  );

  static const StreakMilestone fourteenDays = StreakMilestone(
    id: 'streak_14',
    name: 'Two Week Champ',
    description: 'Log in for 14 consecutive days',
    daysRequired: 14,
    coinReward: 100,
    xpReward: 150,
    iconAsset: 'assets/icons/streak_14.png',
  );

  static const StreakMilestone thirtyDays = StreakMilestone(
    id: 'streak_30',
    name: 'Monthly Master',
    description: 'Log in for 30 consecutive days',
    daysRequired: 30,
    coinReward: 200,
    xpReward: 300,
    badgeId: 'monthly_dedication',
    iconAsset: 'assets/icons/streak_30.png',
  );

  static const StreakMilestone sixtyDays = StreakMilestone(
    id: 'streak_60',
    name: 'Two Month Champion',
    description: 'Log in for 60 consecutive days',
    daysRequired: 60,
    coinReward: 400,
    xpReward: 500,
    iconAsset: 'assets/icons/streak_60.png',
  );

  static const StreakMilestone ninetyDays = StreakMilestone(
    id: 'streak_90',
    name: 'Quarter Year Legend',
    description: 'Log in for 90 consecutive days',
    daysRequired: 90,
    coinReward: 600,
    xpReward: 750,
    badgeId: 'quarterly_dedication',
    iconAsset: 'assets/icons/streak_90.png',
  );

  static const StreakMilestone oneEightyDays = StreakMilestone(
    id: 'streak_180',
    name: 'Half Year Hero',
    description: 'Log in for 180 consecutive days',
    daysRequired: 180,
    coinReward: 1000,
    xpReward: 1200,
    badgeId: 'half_year_dedication',
    iconAsset: 'assets/icons/streak_180.png',
  );

  static const StreakMilestone yearStreak = StreakMilestone(
    id: 'streak_365',
    name: 'Year of Love',
    description: 'Log in for 365 consecutive days',
    daysRequired: 365,
    coinReward: 2500,
    xpReward: 3000,
    badgeId: 'year_dedication',
    iconAsset: 'assets/icons/streak_365.png',
  );

  static const List<StreakMilestone> all = [
    threeDays,
    sevenDays,
    fourteenDays,
    thirtyDays,
    sixtyDays,
    ninetyDays,
    oneEightyDays,
    yearStreak,
  ];

  static StreakMilestone? getById(String id) {
    try {
      return all.firstWhere((m) => m.id == id);
    } catch (e) {
      return null;
    }
  }
}

/// Daily Login Reward
/// Awarded each day the user logs in
class DailyLoginReward extends Equatable {
  final int coins;
  final int xp;
  final int streakDay;
  final int bonusCoins;
  final String? specialReward;

  const DailyLoginReward({
    required this.coins,
    required this.xp,
    required this.streakDay,
    this.bonusCoins = 0,
    this.specialReward,
  });

  int get totalCoins => coins + bonusCoins;

  /// Calculate daily reward based on streak day and tier
  static DailyLoginReward calculate({
    required int streakDay,
    required int baseCoins,
    required int baseXP,
    double tierMultiplier = 1.0,
  }) {
    // Bonus coins for streak milestones (every 7 days)
    final bonusCoins = (streakDay % 7 == 0) ? 20 : 0;

    // Apply tier multiplier
    final coins = (baseCoins * tierMultiplier).round();
    final xp = (baseXP * tierMultiplier).round();

    return DailyLoginReward(
      coins: coins,
      xp: xp,
      streakDay: streakDay,
      bonusCoins: bonusCoins,
    );
  }

  @override
  List<Object?> get props => [coins, xp, streakDay, bonusCoins, specialReward];
}
