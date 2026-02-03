import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/chat_repository.dart';

/// Pin Conversation Use Case
///
/// Point 118: Pin important conversations to the top
class PinConversation {
  final ChatRepository repository;

  PinConversation(this.repository);

  Future<Either<Failure, void>> call({
    required String conversationId,
    required String userId,
    required bool isPinned,
  }) async {
    return await repository.pinConversation(
      conversationId: conversationId,
      userId: userId,
      isPinned: isPinned,
    );
  }
}
