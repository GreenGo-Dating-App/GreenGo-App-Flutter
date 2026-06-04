import '../../../../core/services/usage_limit_service.dart';
import '../../../membership/domain/entities/membership.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';

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

  const ChatLoaded({
    required this.conversation,
    required this.messages,
    required this.currentUserId,
    required this.otherUserId,
    this.isOtherUserTyping = false,
  });
  final Conversation conversation;
  final List<Message> messages;
  final String currentUserId;
  final String otherUserId;
  final bool isOtherUserTyping;

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

  const ChatSending({
    required this.conversation,
    required this.messages,
    required this.currentUserId,
    required this.otherUserId,
  });
  final Conversation conversation;
  final List<Message> messages;
  final String currentUserId;
  final String otherUserId;
}

/// Error state
class ChatError extends ChatState {

  const ChatError(this.message);
  final String message;
}

/// Message action success (star, forward, delete, etc.)
class ChatMessageActionSuccess extends ChatState {

  const ChatMessageActionSuccess(this.message);
  final String message;
}

/// Conversation deleted state
class ChatConversationDeleted extends ChatState {
  const ChatConversationDeleted();
}

/// User blocked successfully
class ChatUserBlockedSuccess extends ChatState {

  const ChatUserBlockedSuccess(this.blockedUserId);
  final String blockedUserId;
}

/// User reported successfully
class ChatUserReportedSuccess extends ChatState {
  const ChatUserReportedSuccess();
}

/// Message limit reached state
class ChatMessageLimitReached extends ChatState {

  const ChatMessageLimitReached({
    required this.conversation,
    required this.messages,
    required this.currentUserId,
    required this.otherUserId,
    required this.limitResult,
  });
  final Conversation conversation;
  final List<Message> messages;
  final String currentUserId;
  final String otherUserId;
  final UsageLimitResult limitResult;
}

/// Media sending not allowed state
class ChatMediaNotAllowed extends ChatState {

  const ChatMediaNotAllowed({
    required this.conversation,
    required this.messages,
    required this.currentUserId,
    required this.otherUserId,
    required this.currentTier,
    required this.requiredTier,
  });
  final Conversation conversation;
  final List<Message> messages;
  final String currentUserId;
  final String otherUserId;
  final MembershipTier currentTier;
  final MembershipTier requiredTier;
}
