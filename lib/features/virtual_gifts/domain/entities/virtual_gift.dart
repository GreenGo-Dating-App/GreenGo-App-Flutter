import 'package:equatable/equatable.dart';

/// Virtual Gift Entity
/// Animated Lottie gifts (roses, coffee, champagne, etc.)
class VirtualGift extends Equatable {
  final String id;
  final String name;
  final String emoji;
  final int price;
  final String category;
  final String animationUrl;
  final String? soundUrl;
  final bool isActive;
  final bool isPremium;
  final int sortOrder;
  final String? description;

  const VirtualGift({
    required this.id,
    required this.name,
    required this.emoji,
    required this.price,
    required this.category,
    required this.animationUrl,
    this.soundUrl,
    this.isActive = true,
    this.isPremium = false,
    this.sortOrder = 0,
    this.description,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        emoji,
        price,
        category,
        animationUrl,
        soundUrl,
        isActive,
        isPremium,
        sortOrder,
        description,
      ];

  /// Get display name with emoji
  String get displayText => '$emoji $name';

  /// Check if gift is affordable
  bool isAffordable(int userCoins) => userCoins >= price;
}

/// Gift Category
enum GiftCategory {
  romantic,
  fun,
  luxury,
  seasonal,
  special,
}

extension GiftCategoryExtension on GiftCategory {
  String get displayName {
    switch (this) {
      case GiftCategory.romantic:
        return 'Romantic';
      case GiftCategory.fun:
        return 'Fun';
      case GiftCategory.luxury:
        return 'Luxury';
      case GiftCategory.seasonal:
        return 'Seasonal';
      case GiftCategory.special:
        return 'Special';
    }
  }

  static GiftCategory fromString(String value) {
    switch (value.toLowerCase()) {
      case 'romantic':
        return GiftCategory.romantic;
      case 'fun':
        return GiftCategory.fun;
      case 'luxury':
        return GiftCategory.luxury;
      case 'seasonal':
        return GiftCategory.seasonal;
      case 'special':
        return GiftCategory.special;
      default:
        return GiftCategory.fun;
    }
  }
}

/// Sent Virtual Gift - a gift sent from one user to another
class SentVirtualGift extends Equatable {
  final String id;
  final String giftId;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String receiverName;
  final String? message;
  final DateTime sentAt;
  final bool isViewed;
  final DateTime? viewedAt;
  final int coinsCost;
  final VirtualGift? gift;

  const SentVirtualGift({
    required this.id,
    required this.giftId,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.receiverName,
    this.message,
    required this.sentAt,
    this.isViewed = false,
    this.viewedAt,
    required this.coinsCost,
    this.gift,
  });

  @override
  List<Object?> get props => [
        id,
        giftId,
        senderId,
        senderName,
        receiverId,
        receiverName,
        message,
        sentAt,
        isViewed,
        viewedAt,
        coinsCost,
        gift,
      ];

  /// Check if gift is new (unviewed)
  bool get isNew => !isViewed;

  /// Get time since sent
  Duration get timeSinceSent => DateTime.now().difference(sentAt);
}

/// Gift Statistics
class GiftStats extends Equatable {
  final String userId;
  final int totalGiftsSent;
  final int totalGiftsReceived;
  final int totalCoinsSpent;
  final int totalCoinsReceived;
  final Map<String, int> giftsSentByType;
  final Map<String, int> giftsReceivedByType;
  final String? mostSentGiftId;
  final String? mostReceivedGiftId;

  const GiftStats({
    required this.userId,
    this.totalGiftsSent = 0,
    this.totalGiftsReceived = 0,
    this.totalCoinsSpent = 0,
    this.totalCoinsReceived = 0,
    this.giftsSentByType = const {},
    this.giftsReceivedByType = const {},
    this.mostSentGiftId,
    this.mostReceivedGiftId,
  });

  @override
  List<Object?> get props => [
        userId,
        totalGiftsSent,
        totalGiftsReceived,
        totalCoinsSpent,
        totalCoinsReceived,
        giftsSentByType,
        giftsReceivedByType,
        mostSentGiftId,
        mostReceivedGiftId,
      ];
}

/// Gift Price Ranges
class GiftPriceRange {
  static const int minPrice = 10;
  static const int maxPrice = 500;

  /// Budget gifts (10-50 coins)
  static const int budgetMax = 50;

  /// Standard gifts (51-100 coins)
  static const int standardMax = 100;

  /// Premium gifts (101-250 coins)
  static const int premiumMax = 250;

  /// Luxury gifts (251-500 coins)
  static const int luxuryMax = 500;

  static String getPriceCategory(int price) {
    if (price <= budgetMax) return 'Budget';
    if (price <= standardMax) return 'Standard';
    if (price <= premiumMax) return 'Premium';
    return 'Luxury';
  }
}
