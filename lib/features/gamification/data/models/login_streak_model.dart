import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/login_streak.dart';

/// Login Streak Model for Firestore serialization
class LoginStreakModel extends LoginStreak {
  const LoginStreakModel({
    required super.userId,
    super.currentStreak,
    super.longestStreak,
    super.lastLoginDate,
    super.totalDaysLoggedIn,
    super.claimedMilestones,
    required super.createdAt,
    required super.updatedAt,
  });

  /// Create from Firestore document
  factory LoginStreakModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return LoginStreakModel.fromMap(data, doc.id);
  }

  /// Create from Map
  factory LoginStreakModel.fromMap(Map<String, dynamic> map, String oderId) {
    final claimedMilestonesData =
        (map['claimedMilestones'] as List<dynamic>?) ?? [];

    return LoginStreakModel(
      userId: oderId,
      currentStreak: map['currentStreak'] as int? ?? 0,
      longestStreak: map['longestStreak'] as int? ?? 0,
      lastLoginDate: (map['lastLoginDate'] as Timestamp?)?.toDate(),
      totalDaysLoggedIn: map['totalDaysLoggedIn'] as int? ?? 0,
      claimedMilestones: claimedMilestonesData
          .map((m) => StreakMilestoneModel.fromMap(m as Map<String, dynamic>))
          .toList(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Create from entity
  factory LoginStreakModel.fromEntity(LoginStreak entity) {
    return LoginStreakModel(
      userId: entity.userId,
      currentStreak: entity.currentStreak,
      longestStreak: entity.longestStreak,
      lastLoginDate: entity.lastLoginDate,
      totalDaysLoggedIn: entity.totalDaysLoggedIn,
      claimedMilestones: entity.claimedMilestones,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastLoginDate':
          lastLoginDate != null ? Timestamp.fromDate(lastLoginDate!) : null,
      'totalDaysLoggedIn': totalDaysLoggedIn,
      'claimedMilestones': claimedMilestones
          .map((m) => StreakMilestoneModel.toMap(m))
          .toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Convert to entity
  LoginStreak toEntity() {
    return LoginStreak(
      userId: userId,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      lastLoginDate: lastLoginDate,
      totalDaysLoggedIn: totalDaysLoggedIn,
      claimedMilestones: claimedMilestones,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

/// Streak Milestone Model for serialization
class StreakMilestoneModel {
  static StreakMilestone fromMap(Map<String, dynamic> map) {
    return StreakMilestone(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      daysRequired: map['daysRequired'] as int,
      coinReward: map['coinReward'] as int,
      xpReward: map['xpReward'] as int,
      badgeId: map['badgeId'] as String?,
      iconAsset: map['iconAsset'] as String,
    );
  }

  static Map<String, dynamic> toMap(StreakMilestone milestone) {
    return {
      'id': milestone.id,
      'name': milestone.name,
      'description': milestone.description,
      'daysRequired': milestone.daysRequired,
      'coinReward': milestone.coinReward,
      'xpReward': milestone.xpReward,
      'badgeId': milestone.badgeId,
      'iconAsset': milestone.iconAsset,
    };
  }
}

/// Daily Login Reward Model
class DailyLoginRewardModel extends DailyLoginReward {
  const DailyLoginRewardModel({
    required super.coins,
    required super.xp,
    required super.streakDay,
    super.bonusCoins,
    super.specialReward,
  });

  factory DailyLoginRewardModel.fromMap(Map<String, dynamic> map) {
    return DailyLoginRewardModel(
      coins: map['coins'] as int,
      xp: map['xp'] as int,
      streakDay: map['streakDay'] as int,
      bonusCoins: map['bonusCoins'] as int? ?? 0,
      specialReward: map['specialReward'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'coins': coins,
      'xp': xp,
      'streakDay': streakDay,
      'bonusCoins': bonusCoins,
      'specialReward': specialReward,
    };
  }
}
