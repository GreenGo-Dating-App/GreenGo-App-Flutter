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
