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
    int? limit,
  }) {
    try {
      return remoteDataSource
          .getMessagesStream(
            conversationId: conversationId,
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
  }) async {
    try {
      final message = await remoteDataSource.sendMessage(
        matchId: matchId,
        senderId: senderId,
        receiverId: receiverId,
        content: content,
        type: type,
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
    required bool isPinned,
  }) async {
    try {
      await remoteDataSource.pinConversation(
        conversationId: conversationId,
        userId: '', // TODO: Get userId from context
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
    required bool isMuted,
    DateTime? mutedUntil,
  }) async {
    try {
      await remoteDataSource.muteConversation(
        conversationId: conversationId,
        userId: '', // TODO: Get userId from context
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
    required bool isArchived,
  }) async {
    try {
      await remoteDataSource.archiveConversation(
        conversationId: conversationId,
        userId: '', // TODO: Get userId from context
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
}
