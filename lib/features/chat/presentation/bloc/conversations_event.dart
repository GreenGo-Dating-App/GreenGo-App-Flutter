/// Conversations Events
abstract class ConversationsEvent {
  const ConversationsEvent();
}

/// Load user's conversations
class ConversationsLoadRequested extends ConversationsEvent {
  final String userId;

  const ConversationsLoadRequested(this.userId);
}

/// Refresh conversations
class ConversationsRefreshRequested extends ConversationsEvent {
  const ConversationsRefreshRequested();
}
