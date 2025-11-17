import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/chat_repository.dart';

/// Remove Message Reaction Use Case
///
/// Removes a user's emoji reaction from a message
class RemoveMessageReaction {
  final ChatRepository repository;

  RemoveMessageReaction(this.repository);

  Future<Either<Failure, void>> call({
    required String messageId,
    required String conversationId,
    required String userId,
  }) async {
    return await repository.removeReaction(
      messageId: messageId,
      conversationId: conversationId,
      userId: userId,
    );
  }
}
