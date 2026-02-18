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
    String? userId,
    int? limit,
  });

  /// Send a text message
  Future<Either<Failure, Message>> sendMessage({
    required String matchId,
    required String senderId,
    required String receiverId,
    required String content,
    required MessageType type,
    Map<String, dynamic>? metadata,
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
    required String userId,
    required bool isPinned,
  });

  /// Mute/unmute conversation (Point 119)
  Future<Either<Failure, void>> muteConversation({
    required String conversationId,
    required String userId,
    required bool isMuted,
    DateTime? mutedUntil,
  });

  /// Archive/unarchive conversation (Point 120)
  Future<Either<Failure, void>> archiveConversation({
    required String conversationId,
    required String userId,
    required bool isArchived,
  });

  /// Update conversation theme (Point 117)
  Future<Either<Failure, void>> updateConversationTheme({
    required String conversationId,
    required ChatTheme theme,
  });

  /// Block a user
  Future<Either<Failure, void>> blockUser({
    required String blockerId,
    required String blockedUserId,
    required String reason,
  });

  /// Unblock a user
  Future<Either<Failure, void>> unblockUser({
    required String blockerId,
    required String blockedUserId,
  });

  /// Check if user is blocked
  Future<Either<Failure, bool>> isUserBlocked({
    required String userId,
    required String otherUserId,
  });

  /// Report a user
  Future<Either<Failure, void>> reportUser({
    required String reporterId,
    required String reportedUserId,
    required String reason,
    String? conversationId,
    String? messageId,
    String? additionalDetails,
  });

  /// Star/unstar a message
  Future<Either<Failure, void>> starMessage({
    required String messageId,
    required String conversationId,
    required String userId,
    required bool isStarred,
  });

  /// Get starred messages for a user
  Future<Either<Failure, List<Message>>> getStarredMessages({
    required String userId,
    int? limit,
  });

  /// Forward a message to multiple conversations
  Future<Either<Failure, void>> forwardMessage({
    required String messageId,
    required String fromConversationId,
    required String senderId,
    required List<String> toMatchIds,
  });

  /// Delete conversation for current user only
  Future<Either<Failure, void>> deleteConversationForMe({
    required String conversationId,
    required String userId,
  });

  /// Delete all messages in conversation for both users
  Future<Either<Failure, void>> deleteConversationForBoth({
    required String conversationId,
    required String userId,
  });

  /// Delete a specific message for current user only
  Future<Either<Failure, void>> deleteMessageForMe({
    required String messageId,
    required String conversationId,
    required String userId,
  });

  /// Delete a specific message for both users (within time limit)
  Future<Either<Failure, void>> deleteMessageForBoth({
    required String messageId,
    required String conversationId,
    required String userId,
  });

  /// Get or create a search conversation between two users
  Future<Either<Failure, Conversation>> getOrCreateSearchConversation({
    required String currentUserId,
    required String otherUserId,
  });
}
