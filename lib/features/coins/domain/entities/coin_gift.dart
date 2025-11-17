import 'package:equatable/equatable.dart';

/// Coin Gift Entity
/// Point 162: Coin gifting system
class CoinGift extends Equatable {
  final String giftId;
  final String senderId;
  final String receiverId;
  final int amount;
  final String? message;
  final CoinGiftStatus status;
  final DateTime sentAt;
  final DateTime? receivedAt;
  final DateTime? expiresAt;

  const CoinGift({
    required this.giftId,
    required this.senderId,
    required this.receiverId,
    required this.amount,
    this.message,
    required this.status,
    required this.sentAt,
    this.receivedAt,
    this.expiresAt,
  });

  /// Check if gift has expired
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Check if gift is pending
  bool get isPending => status == CoinGiftStatus.pending;

  /// Check if gift is accepted
  bool get isAccepted => status == CoinGiftStatus.accepted;

  @override
  List<Object?> get props => [
        giftId,
        senderId,
        receiverId,
        amount,
        message,
        status,
        sentAt,
        receivedAt,
        expiresAt,
      ];
}

/// Gift status
enum CoinGiftStatus {
  pending,   // Sent but not yet received
  accepted,  // Received by recipient
  declined,  // Declined by recipient
  expired,   // Expired before being accepted
  cancelled, // Cancelled by sender
}

extension CoinGiftStatusExtension on CoinGiftStatus {
  String get displayName {
    switch (this) {
      case CoinGiftStatus.pending:
        return 'Pending';
      case CoinGiftStatus.accepted:
        return 'Accepted';
      case CoinGiftStatus.declined:
        return 'Declined';
      case CoinGiftStatus.expired:
        return 'Expired';
      case CoinGiftStatus.cancelled:
        return 'Cancelled';
    }
  }

  static CoinGiftStatus fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return CoinGiftStatus.pending;
      case 'accepted':
        return CoinGiftStatus.accepted;
      case 'declined':
        return CoinGiftStatus.declined;
      case 'expired':
        return CoinGiftStatus.expired;
      case 'cancelled':
        return CoinGiftStatus.cancelled;
      default:
        return CoinGiftStatus.pending;
    }
  }
}

/// Gift constraints
class CoinGiftConstraints {
  /// Minimum gift amount
  static const int minAmount = 10;

  /// Maximum gift amount
  static const int maxAmount = 1000;

  /// Gift expiration period (7 days)
  static const Duration expirationPeriod = Duration(days: 7);

  /// Maximum pending gifts per user
  static const int maxPendingGifts = 10;

  /// Validate gift amount
  static bool isValidAmount(int amount) {
    return amount >= minAmount && amount <= maxAmount;
  }

  /// Get suggested gift amounts
  static List<int> get suggestedAmounts => [10, 25, 50, 100, 250, 500];
}
