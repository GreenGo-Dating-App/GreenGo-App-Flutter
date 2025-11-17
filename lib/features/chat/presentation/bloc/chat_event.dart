import '../../domain/entities/message.dart';

/// Chat Events
abstract class ChatEvent {
  const ChatEvent();
}

/// Load conversation and start listening to messages
class ChatConversationLoaded extends ChatEvent {
  final String matchId;
  final String currentUserId;
  final String otherUserId;

  const ChatConversationLoaded({
    required this.matchId,
    required this.currentUserId,
    required this.otherUserId,
  });
}

/// Send a message
class ChatMessageSent extends ChatEvent {
  final String content;
  final MessageType type;

  const ChatMessageSent({
    required this.content,
    this.type = MessageType.text,
  });
}

/// Mark messages as read
class ChatMessagesMarkedAsRead extends ChatEvent {
  const ChatMessagesMarkedAsRead();
}

/// Typing indicator changed
class ChatTypingIndicatorChanged extends ChatEvent {
  final bool isTyping;

  const ChatTypingIndicatorChanged(this.isTyping);
}

/// Delete a message
class ChatMessageDeleted extends ChatEvent {
  final String messageId;

  const ChatMessageDeleted(this.messageId);
}
