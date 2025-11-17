/**
 * User Level Data Models
 * Points 186-195: Firestore serialization for levels and XP
 */

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_level.dart';

class UserLevelModel extends UserLevel {
  const UserLevelModel({
    required super.userId,
    required super.level,
    required super.currentXP,
    required super.totalXP,
    super.regionalRank,
    super.globalRank,
    super.isVIP,
  });

  factory UserLevelModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserLevelModel(
      userId: data['userId'] as String,
      level: data['level'] as int,
      currentXP: data['currentXP'] as int,
      totalXP: data['totalXP'] as int,
      regionalRank: data['regionalRank'] as int?,
      globalRank: data['globalRank'] as int?,
      isVIP: data['isVIP'] as bool? ?? false,
    );
  }

  factory UserLevelModel.fromMap(Map<String, dynamic> map) {
    return UserLevelModel(
      userId: map['userId'] as String,
      level: map['level'] as int,
      currentXP: map['currentXP'] as int,
      totalXP: map['totalXP'] as int,
      regionalRank: map['regionalRank'] as int?,
      globalRank: map['globalRank'] as int?,
      isVIP: map['isVIP'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'level': level,
      'currentXP': currentXP,
      'totalXP': totalXP,
      'regionalRank': regionalRank,
      'globalRank': globalRank,
      'isVIP': isVIP,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory UserLevelModel.fromEntity(UserLevel entity) {
    return UserLevelModel(
      userId: entity.userId,
      level: entity.level,
      currentXP: entity.currentXP,
      totalXP: entity.totalXP,
      regionalRank: entity.regionalRank,
      globalRank: entity.globalRank,
      isVIP: entity.isVIP,
    );
  }

  UserLevelModel copyWith({
    String? userId,
    int? level,
    int? currentXP,
    int? totalXP,
    int? regionalRank,
    int? globalRank,
    bool? isVIP,
  }) {
    return UserLevelModel(
      userId: userId ?? this.userId,
      level: level ?? this.level,
      currentXP: currentXP ?? this.currentXP,
      totalXP: totalXP ?? this.totalXP,
      regionalRank: regionalRank ?? this.regionalRank,
      globalRank: globalRank ?? this.globalRank,
      isVIP: isVIP ?? this.isVIP,
    );
  }
}

/// XP Transaction Model
class XPTransactionModel extends XPTransaction {
  const XPTransactionModel({
    required super.transactionId,
    required super.userId,
    required super.xpAmount,
    required super.reason,
    required super.timestamp,
    super.levelBefore,
    super.levelAfter,
  });

  factory XPTransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return XPTransactionModel(
      transactionId: doc.id,
      userId: data['userId'] as String,
      xpAmount: data['xpAmount'] as int,
      reason: data['reason'] as String,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      levelBefore: data['levelBefore'] as int?,
      levelAfter: data['levelAfter'] as int?,
    );
  }

  factory XPTransactionModel.fromMap(Map<String, dynamic> map) {
    return XPTransactionModel(
      transactionId: map['transactionId'] as String,
      userId: map['userId'] as String,
      xpAmount: map['xpAmount'] as int,
      reason: map['reason'] as String,
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      levelBefore: map['levelBefore'] as int?,
      levelAfter: map['levelAfter'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'xpAmount': xpAmount,
      'reason': reason,
      'timestamp': Timestamp.fromDate(timestamp),
      'levelBefore': levelBefore,
      'levelAfter': levelAfter,
    };
  }
}

/// Leaderboard Entry Model
class LeaderboardEntryModel extends LeaderboardEntry {
  const LeaderboardEntryModel({
    required super.rank,
    required super.userId,
    required super.level,
    required super.totalXP,
    required super.region,
    super.isVIP,
    super.displayName,
    super.photoUrl,
  });

  factory LeaderboardEntryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return LeaderboardEntryModel(
      rank: data['rank'] as int,
      userId: data['userId'] as String,
      level: data['level'] as int,
      totalXP: data['totalXP'] as int,
      region: data['region'] as String,
      isVIP: data['isVIP'] as bool? ?? false,
      displayName: data['displayName'] as String?,
      photoUrl: data['photoUrl'] as String?,
    );
  }

  factory LeaderboardEntryModel.fromMap(Map<String, dynamic> map) {
    return LeaderboardEntryModel(
      rank: map['rank'] as int,
      userId: map['userId'] as String,
      level: map['level'] as int,
      totalXP: map['totalXP'] as int,
      region: map['region'] as String,
      isVIP: map['isVIP'] as bool? ?? false,
      displayName: map['displayName'] as String?,
      photoUrl: map['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'rank': rank,
      'userId': userId,
      'level': level,
      'totalXP': totalXP,
      'region': region,
      'isVIP': isVIP,
      'displayName': displayName,
      'photoUrl': photoUrl,
    };
  }
}
