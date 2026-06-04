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

  const LoadGiftsByCategory(this.category);
  final String category;

  @override
  List<Object?> get props => [category];
}

/// Send a gift
class SendGiftEvent extends VirtualGiftEvent {

  const SendGiftEvent({
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.receiverName,
    required this.giftId,
    this.message,
  });
  final String senderId;
  final String senderName;
  final String receiverId;
  final String receiverName;
  final String giftId;
  final String? message;

  @override
  List<Object?> get props =>
      [senderId, senderName, receiverId, receiverName, giftId, message];
}

/// Load received gifts
class LoadReceivedGifts extends VirtualGiftEvent {

  const LoadReceivedGifts({
    required this.userId,
    this.limit = 20,
    this.lastGiftId,
  });
  final String userId;
  final int limit;
  final String? lastGiftId;

  @override
  List<Object?> get props => [userId, limit, lastGiftId];
}

/// Subscribe to received gifts stream
class SubscribeToReceivedGifts extends VirtualGiftEvent {

  const SubscribeToReceivedGifts(this.userId);
  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Load sent gifts
class LoadSentGifts extends VirtualGiftEvent {

  const LoadSentGifts({
    required this.userId,
    this.limit = 20,
    this.lastGiftId,
  });
  final String userId;
  final int limit;
  final String? lastGiftId;

  @override
  List<Object?> get props => [userId, limit, lastGiftId];
}

/// Mark gift as viewed
class MarkGiftViewedEvent extends VirtualGiftEvent {

  const MarkGiftViewedEvent(this.giftId);
  final String giftId;

  @override
  List<Object?> get props => [giftId];
}

/// Load gift stats
class LoadGiftStats extends VirtualGiftEvent {

  const LoadGiftStats(this.userId);
  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Load unviewed gift count
class LoadUnviewedGiftCount extends VirtualGiftEvent {

  const LoadUnviewedGiftCount(this.userId);
  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Select a gift for sending
class SelectGift extends VirtualGiftEvent {

  const SelectGift(this.giftId);
  final String giftId;

  @override
  List<Object?> get props => [giftId];
}

/// Clear gift selection
class ClearGiftSelection extends VirtualGiftEvent {
  const ClearGiftSelection();
}
