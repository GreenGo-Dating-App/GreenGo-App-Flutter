import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/chat_repository.dart';
import '../datasources/chat_remote_datasource.dart';

/// Chat Repository Implementation
class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;

  ChatRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, Conversation>> getConversation(String matchId) async {
    try {
      final conversation = await remoteDataSource.getConversation(matchId);
      return Right(conversation.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<Message>>> getMessagesStream({
    required String conversationId,
    String? userId,
    int? limit,
  }) {
    try {
      return remoteDataSource
          .getMessagesStream(
            conversationId: conversationId,
            userId: userId,
            limit: limit,
          )
          .map((messages) =>
              Right<Failure, List<Message>>(messages.map((m) => m.toEntity()).toList()))
          .handleError((error) {
        return Left<Failure, List<Message>>(ServerFailure(error.toString()));
      });
    } catch (e) {
      return Stream.value(Left(ServerFailure(e.toString())));
    }
  }

  @override
  Future<Either<Failure, Message>> sendMessage({
    required String matchId,
    required String senderId,
    required String receiverId,
    required String content,
    required MessageType type,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final message = await remoteDataSource.sendMessage(
        matchId: matchId,
        senderId: senderId,
        receiverId: receiverId,
        content: content,
        type: type,
        metadata: metadata,
      );
      return Right(message.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markMessageAsRead({
    required String messageId,
    required String conversationId,
  }) async {
    try {
      await remoteDataSource.markMessageAsRead(
        messageId: messageId,
        conversationId: conversationId,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markConversationAsRead({
    required String conversationId,
    required String userId,
  }) async {
    try {
      await remoteDataSource.markConversationAsRead(
        conversationId: conversationId,
        userId: userId,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<Conversation>>> getConversationsStream(
      String userId) {
    try {
      return remoteDataSource
          .getConversationsStream(userId)
          .map((conversations) => Right<Failure, List<Conversation>>(
              conversations.map((c) => c.toEntity()).toList()))
          .handleError((error) {
        return Left<Failure, List<Conversation>>(
            ServerFailure(error.toString()));
      });
    } catch (e) {
      return Stream.value(Left(ServerFailure(e.toString())));
    }
  }

  @override
  Future<Either<Failure, void>> setTypingIndicator({
    required String conversationId,
    required String userId,
    required bool isTyping,
  }) async {
    try {
      await remoteDataSource.setTypingIndicator(
        conversationId: conversationId,
        userId: userId,
        isTyping: isTyping,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMessage({
    required String messageId,
    required String conversationId,
  }) async {
    try {
      await remoteDataSource.deleteMessage(
        messageId: messageId,
        conversationId: conversationId,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> getUnreadCount(String userId) async {
    try {
      final count = await remoteDataSource.getUnreadCount(userId);
      return Right(count);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addReaction({
    required String messageId,
    required String conversationId,
    required String userId,
    required String emoji,
  }) async {
    try {
      await remoteDataSource.addReaction(
        messageId: messageId,
        conversationId: conversationId,
        userId: userId,
        emoji: emoji,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> removeReaction({
    required String messageId,
    required String conversationId,
    required String userId,
  }) async {
    try {
      await remoteDataSource.removeReaction(
        messageId: messageId,
        conversationId: conversationId,
        userId: userId,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<Message>>> searchMessages({
    required String conversationId,
    required String query,
    int? limit,
  }) {
    try {
      return remoteDataSource
          .searchMessages(
            conversationId: conversationId,
            query: query,
            limit: limit,
          )
          .map((messages) =>
              Right<Failure, List<Message>>(messages.map((m) => m.toEntity()).toList()))
          .handleError((error) {
        return Left<Failure, List<Message>>(ServerFailure(error.toString()));
      });
    } catch (e) {
      return Stream.value(Left(ServerFailure(e.toString())));
    }
  }

  @override
  Future<Either<Failure, void>> translateMessage({
    required String messageId,
    required String conversationId,
    required String translatedContent,
    required String detectedLanguage,
  }) async {
    try {
      await remoteDataSource.translateMessage(
        messageId: messageId,
        conversationId: conversationId,
        translatedContent: translatedContent,
        detectedLanguage: detectedLanguage,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateMessageStatus({
    required String messageId,
    required String conversationId,
    required MessageStatus status,
  }) async {
    try {
      await remoteDataSource.updateMessageStatus(
        messageId: messageId,
        conversationId: conversationId,
        status: status,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> pinConversation({
    required String conversationId,
    required String userId,
    required bool isPinned,
  }) async {
    try {
      await remoteDataSource.pinConversation(
        conversationId: conversationId,
        userId: userId,
        isPinned: isPinned,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> muteConversation({
    required String conversationId,
    required String userId,
    required bool isMuted,
    DateTime? mutedUntil,
  }) async {
    try {
      await remoteDataSource.muteConversation(
        conversationId: conversationId,
        userId: userId,
        isMuted: isMuted,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> archiveConversation({
    required String conversationId,
    required String userId,
    required bool isArchived,
  }) async {
    try {
      await remoteDataSource.archiveConversation(
        conversationId: conversationId,
        userId: userId,
        isArchived: isArchived,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateConversationTheme({
    required String conversationId,
    required ChatTheme theme,
  }) async {
    try {
      await remoteDataSource.updateConversationTheme(
        conversationId: conversationId,
        theme: theme.name,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> blockUser({
    required String blockerId,
    required String blockedUserId,
    required String reason,
  }) async {
    try {
      await remoteDataSource.blockUser(
        blockerId: blockerId,
        blockedUserId: blockedUserId,
        reason: reason,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> unblockUser({
    required String blockerId,
    required String blockedUserId,
  }) async {
    try {
      await remoteDataSource.unblockUser(
        blockerId: blockerId,
        blockedUserId: blockedUserId,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> isUserBlocked({
    required String userId,
    required String otherUserId,
  }) async {
    try {
      final isBlocked = await remoteDataSource.isUserBlocked(
        userId: userId,
        otherUserId: otherUserId,
      );
      return Right(isBlocked);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> reportUser({
    required String reporterId,
    required String reportedUserId,
    required String reason,
    String? conversationId,
    String? messageId,
    String? additionalDetails,
  }) async {
    try {
      await remoteDataSource.reportUser(
        reporterId: reporterId,
        reportedUserId: reportedUserId,
        reason: reason,
        conversationId: conversationId,
        messageId: messageId,
        additionalDetails: additionalDetails,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> starMessage({
    required String messageId,
    required String conversationId,
    required String userId,
    required bool isStarred,
  }) async {
    try {
      await remoteDataSource.starMessage(
        messageId: messageId,
        conversationId: conversationId,
        userId: userId,
        isStarred: isStarred,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Message>>> getStarredMessages({
    required String userId,
    int? limit,
  }) async {
    try {
      final messages = await remoteDataSource.getStarredMessages(
        userId: userId,
        limit: limit,
      );
      return Right(messages.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> forwardMessage({
    required String messageId,
    required String fromConversationId,
    required String senderId,
    required List<String> toMatchIds,
  }) async {
    try {
      await remoteDataSource.forwardMessage(
        messageId: messageId,
        fromConversationId: fromConversationId,
        senderId: senderId,
        toMatchIds: toMatchIds,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteConversationForMe({
    required String conversationId,
    required String userId,
  }) async {
    try {
      await remoteDataSource.deleteConversationForMe(
        conversationId: conversationId,
        userId: userId,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteConversationForBoth({
    required String conversationId,
    required String userId,
  }) async {
    try {
      await remoteDataSource.deleteConversationForBoth(
        conversationId: conversationId,
        userId: userId,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMessageForMe({
    required String messageId,
    required String conversationId,
    required String userId,
  }) async {
    try {
      await remoteDataSource.deleteMessageForMe(
        messageId: messageId,
        conversationId: conversationId,
        userId: userId,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteMessageForBoth({
    required String messageId,
    required String conversationId,
    required String userId,
  }) async {
    try {
      await remoteDataSource.deleteMessageForBoth(
        messageId: messageId,
        conversationId: conversationId,
        userId: userId,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Conversation>> getOrCreateSearchConversation({
    required String currentUserId,
    required String otherUserId,
  }) async {
    try {
      final conversation = await remoteDataSource.getOrCreateSearchConversation(
        currentUserId: currentUserId,
        otherUserId: otherUserId,
      );
      return Right(conversation.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
