import 'package:equatable/equatable.dart';

/// Who wrote a Buddy chat message.
enum BuddyMessageRole { user, buddy }

/// `chat` = normal reply, `checkin` = the Buddy wrote first (free),
/// `safety` = fixed caring reply with helplines.
enum BuddyMessageKind { chat, checkin, safety }

/// Local delivery state of a message the user typed (server messages are
/// always [sent]).
enum BuddyDelivery { sent, sending, failed }

/// One message in `ai_buddies/{uid}/buddies/{id}/messages`.
class BuddyMessage extends Equatable {
  const BuddyMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
    this.kind = BuddyMessageKind.chat,
    this.charged = 'none',
    this.delivery = BuddyDelivery.sent,
    this.requestId,
  });

  final String id;
  final BuddyMessageRole role;
  final String text;
  final BuddyMessageKind kind;

  /// `free`, `coin` or `none`.
  final String charged;
  final DateTime createdAt;
  final BuddyDelivery delivery;

  /// Local messages only: the idempotency id reused when retrying.
  final String? requestId;

  bool get isBuddy => role == BuddyMessageRole.buddy;
  bool get isLocal => delivery != BuddyDelivery.sent || id.startsWith('local_');

  static BuddyMessageRole roleFrom(Object? v) =>
      v == 'user' ? BuddyMessageRole.user : BuddyMessageRole.buddy;

  static BuddyMessageKind kindFrom(Object? v) {
    switch (v) {
      case 'checkin':
        return BuddyMessageKind.checkin;
      case 'safety':
        return BuddyMessageKind.safety;
      default:
        return BuddyMessageKind.chat;
    }
  }

  BuddyMessage copyWith({BuddyDelivery? delivery}) => BuddyMessage(
        id: id,
        role: role,
        text: text,
        createdAt: createdAt,
        kind: kind,
        charged: charged,
        delivery: delivery ?? this.delivery,
        requestId: requestId,
      );

  @override
  List<Object?> get props => [id, role, text, kind, charged, createdAt, delivery, requestId];
}

/// A page of messages, oldest first, plus whether older ones exist.
class BuddyMessagePage extends Equatable {
  const BuddyMessagePage({required this.messages, required this.hasMore});

  final List<BuddyMessage> messages;
  final bool hasMore;

  @override
  List<Object?> get props => [messages, hasMore];
}
