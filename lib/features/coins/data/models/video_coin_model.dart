import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/video_coin.dart';

/// Video Coin Balance Model for Firestore
class VideoCoinBalanceModel extends VideoCoinBalance {
  const VideoCoinBalanceModel({
    required super.userId,
    required super.totalVideoCoins,
    required super.usedVideoCoins,
    required super.lastUpdated,
  });

  /// Create from Firestore document
  factory VideoCoinBalanceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VideoCoinBalanceModel(
      userId: doc.id,
      totalVideoCoins: (data['totalVideoCoins'] as num?)?.toInt() ?? 0,
      usedVideoCoins: (data['usedVideoCoins'] as num?)?.toInt() ?? 0,
      lastUpdated: data['lastUpdated'] != null
          ? (data['lastUpdated'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  /// Create empty balance
  factory VideoCoinBalanceModel.empty(String userId) {
    return VideoCoinBalanceModel(
      userId: userId,
      totalVideoCoins: 0,
      usedVideoCoins: 0,
      lastUpdated: DateTime.now(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'totalVideoCoins': totalVideoCoins,
      'usedVideoCoins': usedVideoCoins,
      'lastUpdated': Timestamp.fromDate(lastUpdated),
    };
  }
}

/// Video Coin Transaction Model for Firestore
class VideoCoinTransactionModel extends VideoCoinTransaction {
  const VideoCoinTransactionModel({
    required super.transactionId,
    required super.userId,
    required super.type,
    required super.minutes,
    required super.balanceAfter,
    super.relatedUserId,
    super.callId,
    required super.createdAt,
  });

  /// Create from Firestore document
  factory VideoCoinTransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return VideoCoinTransactionModel(
      transactionId: doc.id,
      userId: data['userId'] as String,
      type: VideoCoinTransactionType.values.firstWhere(
        (t) => t.name == data['type'],
        orElse: () => VideoCoinTransactionType.purchase,
      ),
      minutes: (data['minutes'] as num).toInt(),
      balanceAfter: (data['balanceAfter'] as num).toInt(),
      relatedUserId: data['relatedUserId'] as String?,
      callId: data['callId'] as String?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.name,
      'minutes': minutes,
      'balanceAfter': balanceAfter,
      'relatedUserId': relatedUserId,
      'callId': callId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
