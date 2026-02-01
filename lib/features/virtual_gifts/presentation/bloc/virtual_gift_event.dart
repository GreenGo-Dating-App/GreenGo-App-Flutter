import 'package:equatable/equatable.dart';

/// Virtual Gift Events
abstract class VirtualGiftEvent extends Equatable {
  const VirtualGiftEvent();

  @override
  List<Object?> get props => [];
}

/// Load gift catalog
class LoadGiftCatalog extends VirtualGiftEvent {
  const LoadGiftCatalog();
}

/// Load gifts by category
class LoadGiftsByCategory extends VirtualGiftEvent {
  final String category;

  const LoadGiftsByCategory(this.category);

  @override
  List<Object?> get props => [category];
}

/// Send a gift
class SendGiftEvent extends VirtualGiftEvent {
  final String senderId;
  final String senderName;
  final String receiverId;
  final String receiverName;
  final String giftId;
  final String? message;

  const SendGiftEvent({
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.receiverName,
    required this.giftId,
    this.message,
  });

  @override
  List<Object?> get props =>
      [senderId, senderName, receiverId, receiverName, giftId, message];
}

/// Load received gifts
class LoadReceivedGifts extends VirtualGiftEvent {
  final String userId;
  final int limit;
  final String? lastGiftId;

  const LoadReceivedGifts({
    required this.userId,
    this.limit = 20,
    this.lastGiftId,
  });

  @override
  List<Object?> get props => [userId, limit, lastGiftId];
}

/// Subscribe to received gifts stream
class SubscribeToReceivedGifts extends VirtualGiftEvent {
  final String userId;

  const SubscribeToReceivedGifts(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Load sent gifts
class LoadSentGifts extends VirtualGiftEvent {
  final String userId;
  final int limit;
  final String? lastGiftId;

  const LoadSentGifts({
    required this.userId,
    this.limit = 20,
    this.lastGiftId,
  });

  @override
  List<Object?> get props => [userId, limit, lastGiftId];
}

/// Mark gift as viewed
class MarkGiftViewedEvent extends VirtualGiftEvent {
  final String giftId;

  const MarkGiftViewedEvent(this.giftId);

  @override
  List<Object?> get props => [giftId];
}

/// Load gift stats
class LoadGiftStats extends VirtualGiftEvent {
  final String userId;

  const LoadGiftStats(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Load unviewed gift count
class LoadUnviewedGiftCount extends VirtualGiftEvent {
  final String userId;

  const LoadUnviewedGiftCount(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Select a gift for sending
class SelectGift extends VirtualGiftEvent {
  final String giftId;

  const SelectGift(this.giftId);

  @override
  List<Object?> get props => [giftId];
}

/// Clear gift selection
class ClearGiftSelection extends VirtualGiftEvent {
  const ClearGiftSelection();
}
