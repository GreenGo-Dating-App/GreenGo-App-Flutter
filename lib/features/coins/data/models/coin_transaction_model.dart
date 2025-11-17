import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/coin_transaction.dart';

/// Coin Transaction Model for Firestore serialization
class CoinTransactionModel extends CoinTransaction {
  const CoinTransactionModel({
    required super.transactionId,
    required super.userId,
    required super.type,
    required super.amount,
    required super.balanceAfter,
    required super.reason,
    super.relatedId,
    super.relatedUserId,
    super.metadata,
    required super.createdAt,
  });

  /// Create from Firestore document
  factory CoinTransactionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return CoinTransactionModel(
      transactionId: doc.id,
      userId: data['userId'] as String,
      type: _parseType(data['type'] as String),
      amount: (data['amount'] as num).toInt(),
      balanceAfter: (data['balanceAfter'] as num).toInt(),
      reason: CoinTransactionReasonExtension.fromString(data['reason'] as String),
      relatedId: data['relatedId'] as String?,
      relatedUserId: data['relatedUserId'] as String?,
      metadata: data['metadata'] as Map<String, dynamic>?,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.name,
      'amount': amount,
      'balanceAfter': balanceAfter,
      'reason': reason.toString().split('.').last,
      'relatedId': relatedId,
      'relatedUserId': relatedUserId,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Parse transaction type
  static CoinTransactionType _parseType(String value) {
    switch (value.toLowerCase()) {
      case 'credit':
        return CoinTransactionType.credit;
      case 'debit':
        return CoinTransactionType.debit;
      default:
        return CoinTransactionType.credit;
    }
  }
}
