import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/conversation_expiry.dart';
import '../repositories/conversation_expiry_repository.dart';

/// Get expiry for a conversation
class GetConversationExpiry {

  GetConversationExpiry(this.repository);
  final ConversationExpiryRepository repository;

  Future<Either<Failure, ConversationExpiry?>> call(String conversationId) {
    return repository.getExpiry(conversationId);
  }
}

/// Get all user expiries
class GetUserExpiries {

  GetUserExpiries(this.repository);
  final ConversationExpiryRepository repository;

  Future<Either<Failure, List<ConversationExpiry>>> call(String userId) {
    return repository.getUserExpiries(userId);
  }
}

/// Get expiring soon conversations
class GetExpiringSoon {

  GetExpiringSoon(this.repository);
  final ConversationExpiryRepository repository;

  Future<Either<Failure, List<ConversationExpiry>>> call(
    String userId, {
    int withinHours = 24,
  }) {
    return repository.getExpiringSoon(userId, withinHours: withinHours);
  }
}

/// Extend a conversation
class ExtendConversation {

  ExtendConversation(this.repository);
  final ConversationExpiryRepository repository;

  Future<Either<Failure, ExtensionResult>> call({
    required String conversationId,
    required String userId,
  }) {
    return repository.extendConversation(
      conversationId: conversationId,
      userId: userId,
    );
  }
}

/// Record activity in conversation
class RecordConversationActivity {

  RecordConversationActivity(this.repository);
  final ConversationExpiryRepository repository;

  Future<Either<Failure, ConversationExpiry>> call(String conversationId) {
    return repository.recordActivity(conversationId);
  }
}

/// Check if conversation is expired
class CheckConversationExpired {

  CheckConversationExpired(this.repository);
  final ConversationExpiryRepository repository;

  Future<Either<Failure, bool>> call(String conversationId) {
    return repository.isExpired(conversationId);
  }
}

/// Stream expiry updates
class StreamConversationExpiry {

  StreamConversationExpiry(this.repository);
  final ConversationExpiryRepository repository;

  Stream<Either<Failure, ConversationExpiry>> call(String conversationId) {
    return repository.streamExpiry(conversationId);
  }
}
