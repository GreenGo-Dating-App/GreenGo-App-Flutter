import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/conversation.dart';
import '../repositories/chat_repository.dart';

/// Get or Create Search Conversation Use Case
class GetSearchConversation {
  final ChatRepository repository;

  GetSearchConversation(this.repository);

  Future<Either<Failure, Conversation>> call({
    required String currentUserId,
    required String otherUserId,
  }) {
    return repository.getOrCreateSearchConversation(
      currentUserId: currentUserId,
      otherUserId: otherUserId,
    );
  }
}
