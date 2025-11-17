import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/conversation.dart';
import '../entities/message.dart';

/// Chat Repository
///
/// Contract for chat data operations
abstract class ChatRepository {
  /// Get conversation for a match
  /// Returns existing conversation or creates new one
  Future<Either<Failure, Conversation>> getConversation(String matchId);

  /// Stream of messages for a conversation (real-time)
  Stream<Either<Failure, List<Message>>> getMessagesStream({
    required String conversationId,
    int? limit,
  });

  /// Send a text message
  Future<Either<Failure, Message>> sendMessage({
    required String matchId,
    required String senderId,
    required String receiverId,
    required String content,
    required MessageType type,
  });

  /// Mark message as read
  Future<Either<Failure, void>> markMessageAsRead({
    required String messageId,
    required String conversationId,
  });

  /// Mark all messages in conversation as read
  Future<Either<Failure, void>> markConversationAsRead({
    required String conversationId,
    required String userId,
  });

  /// Stream of user's conversations (real-time)
  Stream<Either<Failure, List<Conversation>>> getConversationsStream(
      String userId);

  /// Set typing indicator
  Future<Either<Failure, void>> setTypingIndicator({
    required String conversationId,
    required String userId,
    required bool isTyping,
  });

  /// Delete message
  Future<Either<Failure, void>> deleteMessage({
    required String messageId,
    required String conversationId,
  });

  /// Get unread message count
  Future<Either<Failure, int>> getUnreadCount(String userId);

  /// Add reaction to message
  Future<Either<Failure, void>> addReaction({
    required String messageId,
    required String conversationId,
    required String userId,
    required String emoji,
  });

  /// Remove reaction from message
  Future<Either<Failure, void>> removeReaction({
    required String messageId,
    required String conversationId,
    required String userId,
  });

  /// Search messages in conversation
  Stream<Either<Failure, List<Message>>> searchMessages({
    required String conversationId,
    required String query,
    int? limit,
  });

  /// Translate message
  Future<Either<Failure, void>> translateMessage({
    required String messageId,
    required String conversationId,
    required String translatedContent,
    required String detectedLanguage,
  });

  /// Update message status
  Future<Either<Failure, void>> updateMessageStatus({
    required String messageId,
    required String conversationId,
    required MessageStatus status,
  });

  /// Pin/unpin conversation (Point 118)
  Future<Either<Failure, void>> pinConversation({
    required String conversationId,
    required bool isPinned,
  });

  /// Mute/unmute conversation (Point 119)
  Future<Either<Failure, void>> muteConversation({
    required String conversationId,
    required bool isMuted,
    DateTime? mutedUntil,
  });

  /// Archive/unarchive conversation (Point 120)
  Future<Either<Failure, void>> archiveConversation({
    required String conversationId,
    required bool isArchived,
  });

  /// Update conversation theme (Point 117)
  Future<Either<Failure, void>> updateConversationTheme({
    required String conversationId,
    required ChatTheme theme,
  });
}
