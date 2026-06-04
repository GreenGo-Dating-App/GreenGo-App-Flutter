/// Conversations Events
abstract class ConversationsEvent {
  const ConversationsEvent();
}

/// Load user's conversations
class ConversationsLoadRequested extends ConversationsEvent {

  const ConversationsLoadRequested(this.userId);
  final String userId;
}

/// Refresh conversations
class ConversationsRefreshRequested extends ConversationsEvent {
  const ConversationsRefreshRequested();
}

/// Delete conversation for current user only
class ConversationDeleteForMeRequested extends ConversationsEvent {

  const ConversationDeleteForMeRequested({
    required this.conversationId,
    required this.userId,
  });
  final String conversationId;
  final String userId;
}

/// Delete conversation for both users
class ConversationDeleteForBothRequested extends ConversationsEvent {

  const ConversationDeleteForBothRequested({
    required this.conversationId,
    required this.userId,
  });
  final String conversationId;
  final String userId;
}

/// Toggle favorite status
class ConversationToggleFavoriteRequested extends ConversationsEvent {

  const ConversationToggleFavoriteRequested({
    required this.conversationId,
    required this.userId,
    required this.isFavorite,
  });
  final String conversationId;
  final String userId;
  final bool isFavorite;
}

/// Accept a super like conversation
class ConversationAcceptSuperLikeRequested extends ConversationsEvent {

  const ConversationAcceptSuperLikeRequested({
    required this.conversationId,
  });
  final String conversationId;
}

/// Reject a super like conversation
class ConversationRejectSuperLikeRequested extends ConversationsEvent {

  const ConversationRejectSuperLikeRequested({
    required this.conversationId,
    required this.userId,
  });
  final String conversationId;
  final String userId;
}
