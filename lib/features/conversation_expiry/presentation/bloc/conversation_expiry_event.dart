import 'package:equatable/equatable.dart';

/// Conversation Expiry Events
abstract class ConversationExpiryEvent extends Equatable {
  const ConversationExpiryEvent();

  @override
  List<Object?> get props => [];
}

/// Load expiry for a conversation
class LoadConversationExpiry extends ConversationExpiryEvent {

  const LoadConversationExpiry(this.conversationId);
  final String conversationId;

  @override
  List<Object?> get props => [conversationId];
}

/// Load all user expiries
class LoadUserExpiries extends ConversationExpiryEvent {

  const LoadUserExpiries(this.userId);
  final String userId;

  @override
  List<Object?> get props => [userId];
}

/// Load expiring soon conversations
class LoadExpiringSoon extends ConversationExpiryEvent {

  const LoadExpiringSoon({
    required this.userId,
    this.withinHours = 24,
  });
  final String userId;
  final int withinHours;

  @override
  List<Object?> get props => [userId, withinHours];
}

/// Extend a conversation
class ExtendConversationEvent extends ConversationExpiryEvent {

  const ExtendConversationEvent({
    required this.conversationId,
    required this.userId,
  });
  final String conversationId;
  final String userId;

  @override
  List<Object?> get props => [conversationId, userId];
}

/// Subscribe to expiry updates
class SubscribeToExpiry extends ConversationExpiryEvent {

  const SubscribeToExpiry(this.conversationId);
  final String conversationId;

  @override
  List<Object?> get props => [conversationId];
}

/// Record conversation activity
class RecordActivity extends ConversationExpiryEvent {

  const RecordActivity(this.conversationId);
  final String conversationId;

  @override
  List<Object?> get props => [conversationId];
}

/// Update expiry timer (triggered periodically)
class UpdateExpiryTimer extends ConversationExpiryEvent {
  const UpdateExpiryTimer();
}
