import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/conversation_expiry.dart';
import '../repositories/conversation_expiry_repository.dart';

/// Get expiry for a conversation
class GetConversationExpiry {
  final ConversationExpiryRepository repository;

  GetConversationExpiry(this.repository);

  Future<Either<Failure, ConversationExpiry?>> call(String conversationId) {
    return repository.getExpiry(conversationId);
  }
}

/// Get all user expiries
class GetUserExpiries {
  final ConversationExpiryRepository repository;

  GetUserExpiries(this.repository);

  Future<Either<Failure, List<ConversationExpiry>>> call(String userId) {
    return repository.getUserExpiries(userId);
  }
}

/// Get expiring soon conversations
class GetExpiringSoon {
  final ConversationExpiryRepository repository;

  GetExpiringSoon(this.repository);

  Future<Either<Failure, List<ConversationExpiry>>> call(
    String userId, {
    int withinHours = 24,
  }) {
    return repository.getExpiringSoon(userId, withinHours: withinHours);
  }
}

/// Extend a conversation
class ExtendConversation {
  final ConversationExpiryRepository repository;

  ExtendConversation(this.repository);

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
  final ConversationExpiryRepository repository;

  RecordConversationActivity(this.repository);

  Future<Either<Failure, ConversationExpiry>> call(String conversationId) {
    return repository.recordActivity(conversationId);
  }
}

/// Check if conversation is expired
class CheckConversationExpired {
  final ConversationExpiryRepository repository;

  CheckConversationExpired(this.repository);

  Future<Either<Failure, bool>> call(String conversationId) {
    return repository.isExpired(conversationId);
  }
}

/// Stream expiry updates
class StreamConversationExpiry {
  final ConversationExpiryRepository repository;

  StreamConversationExpiry(this.repository);

  Stream<Either<Failure, ConversationExpiry>> call(String conversationId) {
    return repository.streamExpiry(conversationId);
  }
}
