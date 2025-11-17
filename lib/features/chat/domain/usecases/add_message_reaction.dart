import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/chat_repository.dart';

/// Add Message Reaction Use Case
///
/// Adds an emoji reaction to a message
class AddMessageReaction {
  final ChatRepository repository;

  AddMessageReaction(this.repository);

  Future<Either<Failure, void>> call({
    required String messageId,
    required String conversationId,
    required String userId,
    required String emoji,
  }) async {
    return await repository.addReaction(
      messageId: messageId,
      conversationId: conversationId,
      userId: userId,
      emoji: emoji,
    );
  }
}
