import '../../domain/entities/conversation.dart';

/// Conversations States
abstract class ConversationsState {
  const ConversationsState();
}

/// Initial state
class ConversationsInitial extends ConversationsState {
  const ConversationsInitial();
}

/// Loading conversations
class ConversationsLoading extends ConversationsState {
  const ConversationsLoading();
}

/// Conversations loaded
class ConversationsLoaded extends ConversationsState {
  final List<Conversation> conversations;
  final int totalUnreadCount;

  const ConversationsLoaded({
    required this.conversations,
    this.totalUnreadCount = 0,
  });

  int get unreadCount {
    return conversations.fold(0, (sum, conv) => sum + conv.unreadCount);
  }
}

/// No conversations
class ConversationsEmpty extends ConversationsState {
  const ConversationsEmpty();
}

/// Error state
class ConversationsError extends ConversationsState {
  final String message;

  const ConversationsError(this.message);
}
