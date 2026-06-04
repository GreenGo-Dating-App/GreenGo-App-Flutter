import 'package:equatable/equatable.dart';
import '../../domain/entities/virtual_gift.dart';

/// Virtual Gift States
abstract class VirtualGiftState extends Equatable {
  const VirtualGiftState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class VirtualGiftInitial extends VirtualGiftState {
  const VirtualGiftInitial();
}

/// Loading state
class VirtualGiftLoading extends VirtualGiftState {
  const VirtualGiftLoading();
}

/// Error state
class VirtualGiftError extends VirtualGiftState {

  const VirtualGiftError(this.message);
  final String message;

  @override
  List<Object?> get props => [message];
}

/// Gift catalog loaded
class GiftCatalogLoaded extends VirtualGiftState {

  GiftCatalogLoaded({
    required this.gifts,
    Map<String, List<VirtualGift>>? giftsByCategory,
    this.selectedGiftId,
    this.userCoins,
  }) : giftsByCategory = giftsByCategory ?? _groupByCategory(gifts);
  final List<VirtualGift> gifts;
  final Map<String, List<VirtualGift>> giftsByCategory;
  final String? selectedGiftId;
  final int? userCoins;

  static Map<String, List<VirtualGift>> _groupByCategory(
      List<VirtualGift> gifts) {
    final grouped = <String, List<VirtualGift>>{};
    for (final gift in gifts) {
      if (!grouped.containsKey(gift.category)) {
        grouped[gift.category] = [];
      }
      grouped[gift.category]!.add(gift);
    }
    return grouped;
  }

  /// Get selected gift object
  VirtualGift? get selectedGift {
    if (selectedGiftId == null) return null;
    try {
      return gifts.firstWhere((g) => g.id == selectedGiftId);
    } catch (_) {
      return null;
    }
  }

  /// Check if user can afford a gift
  bool canAfford(String giftId) {
    if (userCoins == null) return true;
    try {
      final gift = gifts.firstWhere((g) => g.id == giftId);
      return gift.isAffordable(userCoins!);
    } catch (_) {
      return false;
    }
  }

  /// Create copy with new selection
  GiftCatalogLoaded copyWith({
    List<VirtualGift>? gifts,
    Map<String, List<VirtualGift>>? giftsByCategory,
    String? selectedGiftId,
    int? userCoins,
    bool clearSelection = false,
  }) {
    return GiftCatalogLoaded(
      gifts: gifts ?? this.gifts,
      giftsByCategory: giftsByCategory ?? this.giftsByCategory,
      selectedGiftId: clearSelection ? null : (selectedGiftId ?? this.selectedGiftId),
      userCoins: userCoins ?? this.userCoins,
    );
  }

  @override
  List<Object?> get props =>
      [gifts, giftsByCategory, selectedGiftId, userCoins];
}

/// Gift sent successfully
class GiftSent extends VirtualGiftState {

  const GiftSent(this.sentGift);
  final SentVirtualGift sentGift;

  @override
  List<Object?> get props => [sentGift];
}

/// Received gifts loaded
class ReceivedGiftsLoaded extends VirtualGiftState {

  const ReceivedGiftsLoaded({
    required this.gifts,
    this.hasMore = false,
    this.unviewedCount = 0,
  });
  final List<SentVirtualGift> gifts;
  final bool hasMore;
  final int unviewedCount;

  /// Get new (unviewed) gifts
  List<SentVirtualGift> get newGifts => gifts.where((g) => g.isNew).toList();

  @override
  List<Object?> get props => [gifts, hasMore, unviewedCount];
}

/// Sent gifts loaded
class SentGiftsLoaded extends VirtualGiftState {

  const SentGiftsLoaded({
    required this.gifts,
    this.hasMore = false,
  });
  final List<SentVirtualGift> gifts;
  final bool hasMore;

  @override
  List<Object?> get props => [gifts, hasMore];
}

/// Gift marked as viewed
class GiftMarkedViewed extends VirtualGiftState {

  const GiftMarkedViewed(this.giftId);
  final String giftId;

  @override
  List<Object?> get props => [giftId];
}

/// Gift statistics loaded
class GiftStatsLoaded extends VirtualGiftState {

  const GiftStatsLoaded(this.stats);
  final GiftStats stats;

  @override
  List<Object?> get props => [stats];
}

/// Unviewed gift count loaded
class UnviewedGiftCountLoaded extends VirtualGiftState {

  const UnviewedGiftCountLoaded(this.count);
  final int count;

  @override
  List<Object?> get props => [count];
}

/// Gift sending in progress
class GiftSending extends VirtualGiftState {

  const GiftSending({
    required this.giftId,
    required this.receiverId,
  });
  final String giftId;
  final String receiverId;

  @override
  List<Object?> get props => [giftId, receiverId];
}

/// Insufficient coins to send gift
class InsufficientCoins extends VirtualGiftState {

  const InsufficientCoins({
    required this.required,
    required this.available,
  });
  final int required;
  final int available;

  int get shortfall => required - available;

  @override
  List<Object?> get props => [required, available];
}
