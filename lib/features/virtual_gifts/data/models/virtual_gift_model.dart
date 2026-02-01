import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/virtual_gift.dart';

/// Virtual Gift Model for Firestore serialization
class VirtualGiftModel extends VirtualGift {
  const VirtualGiftModel({
    required super.id,
    required super.name,
    required super.emoji,
    required super.price,
    required super.category,
    required super.animationUrl,
    super.soundUrl,
    super.isActive = true,
    super.isPremium = false,
    super.sortOrder = 0,
    super.description,
  });

  /// Create from Firestore document
  factory VirtualGiftModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return VirtualGiftModel(
      id: doc.id,
      name: data['name'] as String,
      emoji: data['emoji'] as String,
      price: (data['price'] as num).toInt(),
      category: data['category'] as String,
      animationUrl: data['animationUrl'] as String,
      soundUrl: data['soundUrl'] as String?,
      isActive: data['isActive'] as bool? ?? true,
      isPremium: data['isPremium'] as bool? ?? false,
      sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
      description: data['description'] as String?,
    );
  }

  /// Create from map
  factory VirtualGiftModel.fromMap(Map<String, dynamic> map, String id) {
    return VirtualGiftModel(
      id: id,
      name: map['name'] as String,
      emoji: map['emoji'] as String,
      price: (map['price'] as num).toInt(),
      category: map['category'] as String,
      animationUrl: map['animationUrl'] as String,
      soundUrl: map['soundUrl'] as String?,
      isActive: map['isActive'] as bool? ?? true,
      isPremium: map['isPremium'] as bool? ?? false,
      sortOrder: (map['sortOrder'] as num?)?.toInt() ?? 0,
      description: map['description'] as String?,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'emoji': emoji,
      'price': price,
      'category': category,
      'animationUrl': animationUrl,
      'soundUrl': soundUrl,
      'isActive': isActive,
      'isPremium': isPremium,
      'sortOrder': sortOrder,
      'description': description,
    };
  }
}

/// Sent Virtual Gift Model for Firestore serialization
class SentVirtualGiftModel extends SentVirtualGift {
  const SentVirtualGiftModel({
    required super.id,
    required super.giftId,
    required super.senderId,
    required super.senderName,
    required super.receiverId,
    required super.receiverName,
    super.message,
    required super.sentAt,
    super.isViewed = false,
    super.viewedAt,
    required super.coinsCost,
    super.gift,
  });

  /// Create from Firestore document
  factory SentVirtualGiftModel.fromFirestore(
    DocumentSnapshot doc, {
    VirtualGift? gift,
  }) {
    final data = doc.data() as Map<String, dynamic>;

    return SentVirtualGiftModel(
      id: doc.id,
      giftId: data['giftId'] as String,
      senderId: data['senderId'] as String,
      senderName: data['senderName'] as String,
      receiverId: data['receiverId'] as String,
      receiverName: data['receiverName'] as String,
      message: data['message'] as String?,
      sentAt: (data['sentAt'] as Timestamp).toDate(),
      isViewed: data['isViewed'] as bool? ?? false,
      viewedAt: data['viewedAt'] != null
          ? (data['viewedAt'] as Timestamp).toDate()
          : null,
      coinsCost: (data['coinsCost'] as num).toInt(),
      gift: gift,
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'giftId': giftId,
      'senderId': senderId,
      'senderName': senderName,
      'receiverId': receiverId,
      'receiverName': receiverName,
      'message': message,
      'sentAt': Timestamp.fromDate(sentAt),
      'isViewed': isViewed,
      'viewedAt': viewedAt != null ? Timestamp.fromDate(viewedAt!) : null,
      'coinsCost': coinsCost,
    };
  }
}

/// Gift Stats Model for Firestore serialization
class GiftStatsModel extends GiftStats {
  const GiftStatsModel({
    required super.userId,
    super.totalGiftsSent = 0,
    super.totalGiftsReceived = 0,
    super.totalCoinsSpent = 0,
    super.totalCoinsReceived = 0,
    super.giftsSentByType = const {},
    super.giftsReceivedByType = const {},
    super.mostSentGiftId,
    super.mostReceivedGiftId,
  });

  /// Create from Firestore document
  factory GiftStatsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return GiftStatsModel(
      userId: doc.id,
      totalGiftsSent: (data['totalGiftsSent'] as num?)?.toInt() ?? 0,
      totalGiftsReceived: (data['totalGiftsReceived'] as num?)?.toInt() ?? 0,
      totalCoinsSpent: (data['totalCoinsSpent'] as num?)?.toInt() ?? 0,
      totalCoinsReceived: (data['totalCoinsReceived'] as num?)?.toInt() ?? 0,
      giftsSentByType:
          Map<String, int>.from(data['giftsSentByType'] as Map? ?? {}),
      giftsReceivedByType:
          Map<String, int>.from(data['giftsReceivedByType'] as Map? ?? {}),
      mostSentGiftId: data['mostSentGiftId'] as String?,
      mostReceivedGiftId: data['mostReceivedGiftId'] as String?,
    );
  }

  /// Create empty stats
  factory GiftStatsModel.empty(String userId) {
    return GiftStatsModel(userId: userId);
  }
}
