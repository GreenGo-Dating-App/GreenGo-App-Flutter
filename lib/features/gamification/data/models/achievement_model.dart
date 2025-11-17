/**
 * Achievement Data Models
 * Points 176-185: Firestore serialization for achievements
 */

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/achievement.dart';

class UserAchievementProgressModel extends UserAchievementProgress {
  const UserAchievementProgressModel({
    required super.userId,
    required super.achievementId,
    required super.progress,
    required super.requiredCount,
    required super.isUnlocked,
    super.unlockedAt,
    super.rewardsClaimed,
  });

  factory UserAchievementProgressModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserAchievementProgressModel(
      userId: data['userId'] as String,
      achievementId: data['achievementId'] as String,
      progress: data['progress'] as int,
      requiredCount: data['requiredCount'] as int,
      isUnlocked: data['isUnlocked'] as bool,
      unlockedAt: data['unlockedAt'] != null
          ? (data['unlockedAt'] as Timestamp).toDate()
          : null,
      rewardsClaimed: data['rewardsClaimed'] as bool? ?? false,
    );
  }

  factory UserAchievementProgressModel.fromMap(Map<String, dynamic> map) {
    return UserAchievementProgressModel(
      userId: map['userId'] as String,
      achievementId: map['achievementId'] as String,
      progress: map['progress'] as int,
      requiredCount: map['requiredCount'] as int,
      isUnlocked: map['isUnlocked'] as bool,
      unlockedAt: map['unlockedAt'] != null
          ? (map['unlockedAt'] as Timestamp).toDate()
          : null,
      rewardsClaimed: map['rewardsClaimed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'achievementId': achievementId,
      'progress': progress,
      'requiredCount': requiredCount,
      'isUnlocked': isUnlocked,
      'unlockedAt':
          unlockedAt != null ? Timestamp.fromDate(unlockedAt!) : null,
      'rewardsClaimed': rewardsClaimed,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory UserAchievementProgressModel.fromEntity(
    UserAchievementProgress entity,
  ) {
    return UserAchievementProgressModel(
      userId: entity.userId,
      achievementId: entity.achievementId,
      progress: entity.progress,
      requiredCount: entity.requiredCount,
      isUnlocked: entity.isUnlocked,
      unlockedAt: entity.unlockedAt,
      rewardsClaimed: entity.rewardsClaimed,
    );
  }

  UserAchievementProgressModel copyWith({
    String? userId,
    String? achievementId,
    int? progress,
    int? requiredCount,
    bool? isUnlocked,
    DateTime? unlockedAt,
    bool? rewardsClaimed,
  }) {
    return UserAchievementProgressModel(
      userId: userId ?? this.userId,
      achievementId: achievementId ?? this.achievementId,
      progress: progress ?? this.progress,
      requiredCount: requiredCount ?? this.requiredCount,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      rewardsClaimed: rewardsClaimed ?? this.rewardsClaimed,
    );
  }
}
