import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/conversation.dart';
import '../repositories/chat_repository.dart';

/// Get Conversation Use Case
class GetConversation {

  GetConversation(this.repository);
  final ChatRepository repository;

  Future<Either<Failure, Conversation>> call(String matchId) {
    return repository.getConversation(matchId);
  }
}
