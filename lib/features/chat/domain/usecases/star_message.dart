import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/message.dart';
import '../repositories/chat_repository.dart';

/// Star Message Use Case
class StarMessage {
  final ChatRepository repository;

  StarMessage(this.repository);

  Future<Either<Failure, void>> call(StarMessageParams params) {
    return repository.starMessage(
      messageId: params.messageId,
      conversationId: params.conversationId,
      userId: params.userId,
      isStarred: params.isStarred,
    );
  }
}

/// Parameters for StarMessage use case
class StarMessageParams {
  final String messageId;
  final String conversationId;
  final String userId;
  final bool isStarred;

  StarMessageParams({
    required this.messageId,
    required this.conversationId,
    required this.userId,
    required this.isStarred,
  });
}

/// Get Starred Messages Use Case
class GetStarredMessages {
  final ChatRepository repository;

  GetStarredMessages(this.repository);

  Future<Either<Failure, List<Message>>> call(GetStarredMessagesParams params) {
    return repository.getStarredMessages(
      userId: params.userId,
      limit: params.limit,
    );
  }
}

/// Parameters for GetStarredMessages use case
class GetStarredMessagesParams {
  final String userId;
  final int? limit;

  GetStarredMessagesParams({
    required this.userId,
    this.limit,
  });
}
