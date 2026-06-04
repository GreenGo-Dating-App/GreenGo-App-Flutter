import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/chat_repository.dart';

/// Mark Messages As Read Use Case
class MarkAsRead {

  MarkAsRead(this.repository);
  final ChatRepository repository;

  Future<Either<Failure, void>> call(MarkAsReadParams params) {
    return repository.markConversationAsRead(
      conversationId: params.conversationId,
      userId: params.userId,
    );
  }
}

/// Parameters for MarkAsRead use case
class MarkAsReadParams {

  MarkAsReadParams({
    required this.conversationId,
    required this.userId,
  });
  final String conversationId;
  final String userId;
}
