import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/conversation_expiry.dart';

/// Repository interface for conversation expiry
abstract class ConversationExpiryRepository {
  /// Get expiry status for a conversation
  Future<Either<Failure, ConversationExpiry?>> getExpiry(String conversationId);

  /// Get all expiries for a user
  Future<Either<Failure, List<ConversationExpiry>>> getUserExpiries(String userId);

  /// Get expiring soon conversations
  Future<Either<Failure, List<ConversationExpiry>>> getExpiringSoon(
    String userId, {
    int withinHours = 24,
  });

  /// Extend a conversation
  Future<Either<Failure, ExtensionResult>> extendConversation({
    required String conversationId,
    required String userId,
  });

  /// Stream expiry updates for a conversation
  Stream<Either<Failure, ConversationExpiry>> streamExpiry(String conversationId);

  /// Mark conversation as having activity (resets timer)
  Future<Either<Failure, ConversationExpiry>> recordActivity(String conversationId);

  /// Check if conversation is expired
  Future<Either<Failure, bool>> isExpired(String conversationId);
}
