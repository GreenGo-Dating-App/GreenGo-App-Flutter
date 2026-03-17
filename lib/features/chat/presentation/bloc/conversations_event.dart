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

/// Delete conversation for current user only
class ConversationDeleteForMeRequested extends ConversationsEvent {
  final String conversationId;
  final String userId;

  const ConversationDeleteForMeRequested({
    required this.conversationId,
    required this.userId,
  });
}

/// Delete conversation for both users
class ConversationDeleteForBothRequested extends ConversationsEvent {
  final String conversationId;
  final String userId;

  const ConversationDeleteForBothRequested({
    required this.conversationId,
    required this.userId,
  });
}

/// Toggle favorite status
class ConversationToggleFavoriteRequested extends ConversationsEvent {
  final String conversationId;
  final String userId;
  final bool isFavorite;

  const ConversationToggleFavoriteRequested({
    required this.conversationId,
    required this.userId,
    required this.isFavorite,
  });
}

/// Accept a super like conversation
class ConversationAcceptSuperLikeRequested extends ConversationsEvent {
  final String conversationId;

  const ConversationAcceptSuperLikeRequested({
    required this.conversationId,
  });
}

/// Reject a super like conversation
class ConversationRejectSuperLikeRequested extends ConversationsEvent {
  final String conversationId;
  final String userId;

  const ConversationRejectSuperLikeRequested({
    required this.conversationId,
    required this.userId,
  });
}
