import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/chat_repository.dart';

/// Forward Message Use Case
class ForwardMessage {
  final ChatRepository repository;

  ForwardMessage(this.repository);

  Future<Either<Failure, void>> call(ForwardMessageParams params) {
    return repository.forwardMessage(
      messageId: params.messageId,
      fromConversationId: params.fromConversationId,
      senderId: params.senderId,
      toMatchIds: params.toMatchIds,
    );
  }
}

/// Parameters for ForwardMessage use case
class ForwardMessageParams {
  final String messageId;
  final String fromConversationId;
  final String senderId;
  final List<String> toMatchIds;

  ForwardMessageParams({
    required this.messageId,
    required this.fromConversationId,
    required this.senderId,
    required this.toMatchIds,
  });
}
