import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// What a buyer <-> organizer chat is about (2026-10-17): the event or
/// experience the conversation was last opened from.
///
/// Stored on the conversation as
/// `context: {type: 'event'|'experience', id, title, startAt, buyer?, buyerId?}`.
/// `buyer: true` is written ONLY by the `openListingChat` callable after it
/// verified a ticket / booking (the rules refuse it from a client), so the
/// organizer's "Ticket holder" / "Booked" tag can be trusted. Opening the chat
/// from another listing replaces the context; the message history is kept.
class ConversationListingContext extends Equatable {
  const ConversationListingContext({
    required this.type,
    required this.id,
    required this.title,
    this.startAt,
    this.buyer = false,
    this.buyerId,
  });

  static const String event = 'event';
  static const String experience = 'experience';

  /// [event] or [experience].
  final String type;
  final String id;
  final String title;
  final DateTime? startAt;

  /// Server-verified ticket holder / booked guest.
  final bool buyer;

  /// Who the verified buyer is (the organizer sees the tag, not the buyer).
  final String? buyerId;

  /// "Ticket holder" / "Booked" tag for [viewerId] (the other side only).
  bool showsBuyerTagFor(String viewerId) =>
      buyer && buyerId != null && buyerId != viewerId;

  bool get isEvent => type == event;

  static DateTime? _date(Object? v) {
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
    return null;
  }

  /// Parses the stored / callable map; null when unusable.
  static ConversationListingContext? fromMap(Object? raw) {
    if (raw is! Map) return null;
    final type = raw['type'];
    final id = raw['id'];
    if ((type != event && type != experience) || id is! String || id.isEmpty) {
      return null;
    }
    return ConversationListingContext(
      type: type as String,
      id: id,
      title: (raw['title'] as String?)?.trim() ?? '',
      startAt: _date(raw['startAt']),
      buyer: raw['buyer'] == true,
      buyerId: raw['buyerId'] as String?,
    );
  }

  /// Same listing (the topic did not change).
  bool sameListing(ConversationListingContext? other) =>
      other != null && other.type == type && other.id == id;

  /// What a CLIENT may write: never `buyer` (server-only).
  Map<String, dynamic> toClientMap() => {
        'type': type,
        'id': id,
        'title': title,
        'startAt': startAt != null ? Timestamp.fromDate(startAt!) : null,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  ConversationListingContext copyWith({bool? buyer, DateTime? startAt}) =>
      ConversationListingContext(
        type: type,
        id: id,
        title: title,
        startAt: startAt ?? this.startAt,
        buyer: buyer ?? this.buyer,
        buyerId: (buyer ?? this.buyer) ? buyerId : null,
      );

  @override
  List<Object?> get props => [type, id, title, startAt, buyer, buyerId];
}
