import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../../../../core/services/usage_limit_service.dart';
import '../../../membership/domain/entities/membership.dart';

/// Chat States
abstract class ChatState {
  const ChatState();
}

/// Initial state
class ChatInitial extends ChatState {
  const ChatInitial();
}

/// Loading conversation
class ChatLoading extends ChatState {
  const ChatLoading();
}

/// Chat loaded with messages
class ChatLoaded extends ChatState {
  final Conversation conversation;
  final List<Message> messages;
  final String currentUserId;
  final String otherUserId;
  final bool isOtherUserTyping;

  const ChatLoaded({
    required this.conversation,
    required this.messages,
    required this.currentUserId,
    required this.otherUserId,
    this.isOtherUserTyping = false,
  });

  ChatLoaded copyWith({
    Conversation? conversation,
    List<Message>? messages,
    String? currentUserId,
    String? otherUserId,
    bool? isOtherUserTyping,
  }) {
    return ChatLoaded(
      conversation: conversation ?? this.conversation,
      messages: messages ?? this.messages,
      currentUserId: currentUserId ?? this.currentUserId,
      otherUserId: otherUserId ?? this.otherUserId,
      isOtherUserTyping: isOtherUserTyping ?? this.isOtherUserTyping,
    );
  }
}

/// Sending message
class ChatSending extends ChatState {
  final Conversation conversation;
  final List<Message> messages;
  final String currentUserId;
  final String otherUserId;

  const ChatSending({
    required this.conversation,
    required this.messages,
    required this.currentUserId,
    required this.otherUserId,
  });
}

/// Error state
class ChatError extends ChatState {
  final String message;

  const ChatError(this.message);
}

/// Message action success (star, forward, delete, etc.)
class ChatMessageActionSuccess extends ChatState {
  final String message;

  const ChatMessageActionSuccess(this.message);
}

/// Conversation deleted state
class ChatConversationDeleted extends ChatState {
  const ChatConversationDeleted();
}

/// User blocked successfully
class ChatUserBlockedSuccess extends ChatState {
  final String blockedUserId;

  const ChatUserBlockedSuccess(this.blockedUserId);
}

/// User reported successfully
class ChatUserReportedSuccess extends ChatState {
  const ChatUserReportedSuccess();
}

/// Message limit reached state
class ChatMessageLimitReached extends ChatState {
  final Conversation conversation;
  final List<Message> messages;
  final String currentUserId;
  final String otherUserId;
  final UsageLimitResult limitResult;

  const ChatMessageLimitReached({
    required this.conversation,
    required this.messages,
    required this.currentUserId,
    required this.otherUserId,
    required this.limitResult,
  });
}

/// Media sending not allowed state
class ChatMediaNotAllowed extends ChatState {
  final Conversation conversation;
  final List<Message> messages;
  final String currentUserId;
  final String otherUserId;
  final MembershipTier currentTier;
  final MembershipTier requiredTier;

  const ChatMediaNotAllowed({
    required this.conversation,
    required this.messages,
    required this.currentUserId,
    required this.otherUserId,
    required this.currentTier,
    required this.requiredTier,
  });
}
