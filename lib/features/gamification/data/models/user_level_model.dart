/**
 * User Level Data Models
 * Points 186-195: Firestore serialization for levels and XP
 */

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_level.dart';

class UserLevelModel extends UserLevel {
  UserLevelModel({
    required super.userId,
    required super.level,
    required super.currentXP,
    required super.totalXP,
    super.lastUpdated,
    super.region,
    super.regionalRank,
    super.isVIP,
  });

  factory UserLevelModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserLevelModel(
      userId: data['userId'] as String,
      level: data['level'] as int,
      currentXP: data['currentXP'] as int,
      totalXP: data['totalXP'] as int,
      lastUpdated: data['lastUpdated'] != null
          ? (data['lastUpdated'] as Timestamp).toDate()
          : DateTime.now(),
      region: data['region'] as String? ?? 'global',
      regionalRank: data['regionalRank'] as int? ?? 0,
      isVIP: data['isVIP'] as bool? ?? false,
    );
  }

  factory UserLevelModel.fromMap(Map<String, dynamic> map) {
    return UserLevelModel(
      userId: map['userId'] as String,
      level: map['level'] as int,
      currentXP: map['currentXP'] as int,
      totalXP: map['totalXP'] as int,
      lastUpdated: map['lastUpdated'] != null
          ? (map['lastUpdated'] as Timestamp).toDate()
          : DateTime.now(),
      region: map['region'] as String? ?? 'global',
      regionalRank: map['regionalRank'] as int? ?? 0,
      isVIP: map['isVIP'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'level': level,
      'currentXP': currentXP,
      'totalXP': totalXP,
      'lastUpdated': FieldValue.serverTimestamp(),
      'region': region,
      'regionalRank': regionalRank,
      'isVIP': isVIP,
    };
  }

  factory UserLevelModel.fromEntity(UserLevel entity) {
    return UserLevelModel(
      userId: entity.userId,
      level: entity.level,
      currentXP: entity.currentXP,
      totalXP: entity.totalXP,
      lastUpdated: entity.lastUpdated,
      region: entity.region,
      regionalRank: entity.regionalRank,
      isVIP: entity.isVIP,
    );
  }

  UserLevelModel copyWith({
    String? userId,
    int? level,
    int? currentXP,
    int? totalXP,
    DateTime? lastUpdated,
    String? region,
    int? regionalRank,
    bool? isVIP,
  }) {
    return UserLevelModel(
      userId: userId ?? this.userId,
      level: level ?? this.level,
      currentXP: currentXP ?? this.currentXP,
      totalXP: totalXP ?? this.totalXP,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      region: region ?? this.region,
      regionalRank: regionalRank ?? this.regionalRank,
      isVIP: isVIP ?? this.isVIP,
    );
  }
}

/// XP Transaction Model
class XPTransactionModel extends XPTransaction {
  const XPTransactionModel({
    required super.transactionId,
    required super.userId,
    required super.actionType,
    required super.xpAmount,
    required super.levelBefore,
    required super.levelAfter,
    required super.createdAt,
    super.metadata,
  });

  factory XPTransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return XPTransactionModel(
      transactionId: doc.id,
      userId: data['userId'] as String,
      actionType: data['actionType'] as String? ?? data['reason'] as String,
      xpAmount: data['xpAmount'] as int,
      levelBefore: data['levelBefore'] as int? ?? 0,
      levelAfter: data['levelAfter'] as int? ?? 0,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: data['metadata'] as Map<String, dynamic>?,
    );
  }

  factory XPTransactionModel.fromMap(Map<String, dynamic> map) {
    return XPTransactionModel(
      transactionId: map['transactionId'] as String,
      userId: map['userId'] as String,
      actionType: map['actionType'] as String? ?? map['reason'] as String,
      xpAmount: map['xpAmount'] as int,
      levelBefore: map['levelBefore'] as int? ?? 0,
      levelAfter: map['levelAfter'] as int? ?? 0,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'actionType': actionType,
      'xpAmount': xpAmount,
      'levelBefore': levelBefore,
      'levelAfter': levelAfter,
      'createdAt': Timestamp.fromDate(createdAt),
      'metadata': metadata,
    };
  }
}

/// Leaderboard Entry Model
class LeaderboardEntryModel extends LeaderboardEntry {
  const LeaderboardEntryModel({
    required super.rank,
    required super.userId,
    required super.username,
    required super.level,
    required super.totalXP,
    super.region,
    super.photoUrl,
    super.isVIP,
  });

  factory LeaderboardEntryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return LeaderboardEntryModel(
      rank: data['rank'] as int,
      userId: data['userId'] as String,
      username: data['username'] as String? ?? data['displayName'] as String? ?? 'Unknown',
      level: data['level'] as int,
      totalXP: data['totalXP'] as int,
      region: data['region'] as String? ?? 'global',
      photoUrl: data['photoUrl'] as String?,
      isVIP: data['isVIP'] as bool? ?? false,
    );
  }

  factory LeaderboardEntryModel.fromMap(Map<String, dynamic> map) {
    return LeaderboardEntryModel(
      rank: map['rank'] as int,
      userId: map['userId'] as String,
      username: map['username'] as String? ?? map['displayName'] as String? ?? 'Unknown',
      level: map['level'] as int,
      totalXP: map['totalXP'] as int,
      region: map['region'] as String? ?? 'global',
      photoUrl: map['photoUrl'] as String?,
      isVIP: map['isVIP'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'rank': rank,
      'userId': userId,
      'username': username,
      'level': level,
      'totalXP': totalXP,
      'region': region,
      'photoUrl': photoUrl,
      'isVIP': isVIP,
    };
  }
}
