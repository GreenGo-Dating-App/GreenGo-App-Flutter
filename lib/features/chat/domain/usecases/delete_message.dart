import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/chat_repository.dart';

/// Delete Message Use Case
class DeleteMessage {

  DeleteMessage(this.repository);
  final ChatRepository repository;

  Future<Either<Failure, void>> call(DeleteMessageParams params) {
    return repository.deleteMessage(
      messageId: params.messageId,
      conversationId: params.conversationId,
    );
  }
}

/// Parameters for DeleteMessage use case
class DeleteMessageParams {

  DeleteMessageParams({
    required this.messageId,
    required this.conversationId,
  });
  final String messageId;
  final String conversationId;
}

/// Delete Message For Me Use Case
class DeleteMessageForMe {

  DeleteMessageForMe(this.repository);
  final ChatRepository repository;

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

  DeleteMessageForMeParams({
    required this.messageId,
    required this.conversationId,
    required this.userId,
  });
  final String messageId;
  final String conversationId;
  final String userId;
}

/// Delete Message For Both Use Case
class DeleteMessageForBoth {

  DeleteMessageForBoth(this.repository);
  final ChatRepository repository;

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

  DeleteMessageForBothParams({
    required this.messageId,
    required this.conversationId,
    required this.userId,
  });
  final String messageId;
  final String conversationId;
  final String userId;
}
