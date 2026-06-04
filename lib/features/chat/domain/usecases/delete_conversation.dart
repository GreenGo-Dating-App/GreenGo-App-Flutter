import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/chat_repository.dart';

/// Delete Conversation For Me Use Case
class DeleteConversationForMe {

  DeleteConversationForMe(this.repository);
  final ChatRepository repository;

  Future<Either<Failure, void>> call(DeleteConversationForMeParams params) {
    return repository.deleteConversationForMe(
      conversationId: params.conversationId,
      userId: params.userId,
    );
  }
}

/// Parameters for DeleteConversationForMe use case
class DeleteConversationForMeParams {

  DeleteConversationForMeParams({
    required this.conversationId,
    required this.userId,
  });
  final String conversationId;
  final String userId;
}

/// Delete Conversation For Both Use Case
class DeleteConversationForBoth {

  DeleteConversationForBoth(this.repository);
  final ChatRepository repository;

  Future<Either<Failure, void>> call(DeleteConversationForBothParams params) {
    return repository.deleteConversationForBoth(
      conversationId: params.conversationId,
      userId: params.userId,
    );
  }
}

/// Parameters for DeleteConversationForBoth use case
class DeleteConversationForBothParams {

  DeleteConversationForBothParams({
    required this.conversationId,
    required this.userId,
  });
  final String conversationId;
  final String userId;
}
