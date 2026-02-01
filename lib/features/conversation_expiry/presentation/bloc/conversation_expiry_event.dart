import 'package:equatable/equatable.dart';

/// Conversation Expiry Events
abstract class ConversationExpiryEvent extends Equatable {
  const ConversationExpiryEvent();

  @override
  List<Object?> get props => [];
}

/// Load expiry for a conversation
class LoadConversationExpiry extends ConversationExpiryEvent {
  final String conversationId;

  const LoadConversationExpiry(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

/// Load all user expiries
class LoadUserExpiries extends ConversationExpiryEvent {
  final String userId;

  const LoadUserExpiries(this.userId);

  @override
  List<Object?> get props => [userId];
}

/// Load expiring soon conversations
class LoadExpiringSoon extends ConversationExpiryEvent {
  final String userId;
  final int withinHours;

  const LoadExpiringSoon({
    required this.userId,
    this.withinHours = 24,
  });

  @override
  List<Object?> get props => [userId, withinHours];
}

/// Extend a conversation
class ExtendConversationEvent extends ConversationExpiryEvent {
  final String conversationId;
  final String userId;

  const ExtendConversationEvent({
    required this.conversationId,
    required this.userId,
  });

  @override
  List<Object?> get props => [conversationId, userId];
}

/// Subscribe to expiry updates
class SubscribeToExpiry extends ConversationExpiryEvent {
  final String conversationId;

  const SubscribeToExpiry(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

/// Record conversation activity
class RecordActivity extends ConversationExpiryEvent {
  final String conversationId;

  const RecordActivity(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

/// Update expiry timer (triggered periodically)
class UpdateExpiryTimer extends ConversationExpiryEvent {
  const UpdateExpiryTimer();
}
