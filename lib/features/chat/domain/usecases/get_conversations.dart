import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/conversation.dart';
import '../repositories/chat_repository.dart';

/// Get Conversations Stream Use Case
class GetConversations {
  final ChatRepository repository;

  GetConversations(this.repository);

  Stream<Either<Failure, List<Conversation>>> call(String userId) {
    return repository.getConversationsStream(userId);
  }
}
