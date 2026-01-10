import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/chat_repository.dart';

/// Delete Conversation For Me Use Case
class DeleteConversationForMe {
  final ChatRepository repository;

  DeleteConversationForMe(this.repository);

  Future<Either<Failure, void>> call(DeleteConversationForMeParams params) {
    return repository.deleteConversationForMe(
      conversationId: params.conversationId,
      userId: params.userId,
    );
  }
}

/// Parameters for DeleteConversationForMe use case
class DeleteConversationForMeParams {
  final String conversationId;
  final String userId;

  DeleteConversationForMeParams({
    required this.conversationId,
    required this.userId,
  });
}

/// Delete Conversation For Both Use Case
class DeleteConversationForBoth {
  final ChatRepository repository;

  DeleteConversationForBoth(this.repository);

  Future<Either<Failure, void>> call(DeleteConversationForBothParams params) {
    return repository.deleteConversationForBoth(
      conversationId: params.conversationId,
      userId: params.userId,
    );
  }
}

/// Parameters for DeleteConversationForBoth use case
class DeleteConversationForBothParams {
  final String conversationId;
  final String userId;

  DeleteConversationForBothParams({
    required this.conversationId,
    required this.userId,
  });
}
