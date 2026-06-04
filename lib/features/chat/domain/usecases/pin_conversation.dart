import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/chat_repository.dart';

/// Pin Conversation Use Case
///
/// Point 118: Pin important conversations to the top
class PinConversation {

  PinConversation(this.repository);
  final ChatRepository repository;

  Future<Either<Failure, void>> call({
    required String conversationId,
    required String userId,
    required bool isPinned,
  }) async {
    return repository.pinConversation(
      conversationId: conversationId,
      userId: userId,
      isPinned: isPinned,
    );
  }
}
