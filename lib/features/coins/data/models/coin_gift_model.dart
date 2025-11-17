import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/coin_gift.dart';

/// Coin Gift Model for Firestore serialization
class CoinGiftModel extends CoinGift {
  const CoinGiftModel({
    required super.giftId,
    required super.senderId,
    required super.receiverId,
    required super.amount,
    super.message,
    required super.status,
    required super.sentAt,
    super.receivedAt,
    super.expiresAt,
  });

  /// Create from Firestore document
  factory CoinGiftModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return CoinGiftModel(
      giftId: doc.id,
      senderId: data['senderId'] as String,
      receiverId: data['receiverId'] as String,
      amount: (data['amount'] as num).toInt(),
      message: data['message'] as String?,
      status: CoinGiftStatusExtension.fromString(data['status'] as String),
      sentAt: (data['sentAt'] as Timestamp).toDate(),
      receivedAt: data['receivedAt'] != null
          ? (data['receivedAt'] as Timestamp).toDate()
          : null,
      expiresAt: data['expiresAt'] != null
          ? (data['expiresAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'amount': amount,
      'message': message,
      'status': status.name,
      'sentAt': Timestamp.fromDate(sentAt),
      'receivedAt': receivedAt != null ? Timestamp.fromDate(receivedAt!) : null,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
    };
  }
}
