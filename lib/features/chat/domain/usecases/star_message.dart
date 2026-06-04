import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/message.dart';
import '../repositories/chat_repository.dart';

/// Star Message Use Case
class StarMessage {

  StarMessage(this.repository);
  final ChatRepository repository;

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

  StarMessageParams({
    required this.messageId,
    required this.conversationId,
    required this.userId,
    required this.isStarred,
  });
  final String messageId;
  final String conversationId;
  final String userId;
  final bool isStarred;
}

/// Get Starred Messages Use Case
class GetStarredMessages {

  GetStarredMessages(this.repository);
  final ChatRepository repository;

  Future<Either<Failure, List<Message>>> call(GetStarredMessagesParams params) {
    return repository.getStarredMessages(
      userId: params.userId,
      limit: params.limit,
    );
  }
}

/// Parameters for GetStarredMessages use case
class GetStarredMessagesParams {

  GetStarredMessagesParams({
    required this.userId,
    this.limit,
  });
  final String userId;
  final int? limit;
}
