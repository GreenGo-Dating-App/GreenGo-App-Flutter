import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/chat_repository.dart';

/// Delete Message Use Case
class DeleteMessage {
  final ChatRepository repository;

  DeleteMessage(this.repository);

  Future<Either<Failure, void>> call(DeleteMessageParams params) {
    return repository.deleteMessage(
      messageId: params.messageId,
      conversationId: params.conversationId,
    );
  }
}

/// Parameters for DeleteMessage use case
class DeleteMessageParams {
  final String messageId;
  final String conversationId;

  DeleteMessageParams({
    required this.messageId,
    required this.conversationId,
  });
}

/// Delete Message For Me Use Case
class DeleteMessageForMe {
  final ChatRepository repository;

  DeleteMessageForMe(this.repository);

  Future<Either<Failure, void>> call(DeleteMessageForMeParams params) {
    return repository.deleteMessageForMe(
      messageId: params.messageId,
      conversationId: params.conversationId,
      userId: params.userId,
    );
  }
}

/// Parameters for DeleteMessageForMe use case
class DeleteMessageForMeParams {
  final String messageId;
  final String conversationId;
  final String userId;

  DeleteMessageForMeParams({
    required this.messageId,
    required this.conversationId,
    required this.userId,
  });
}

/// Delete Message For Both Use Case
class DeleteMessageForBoth {
  final ChatRepository repository;

  DeleteMessageForBoth(this.repository);

  Future<Either<Failure, void>> call(DeleteMessageForBothParams params) {
    return repository.deleteMessageForBoth(
      messageId: params.messageId,
      conversationId: params.conversationId,
      userId: params.userId,
    );
  }
}

/// Parameters for DeleteMessageForBoth use case
class DeleteMessageForBothParams {
  final String messageId;
  final String conversationId;
  final String userId;

  DeleteMessageForBothParams({
    required this.messageId,
    required this.conversationId,
    required this.userId,
  });
}
