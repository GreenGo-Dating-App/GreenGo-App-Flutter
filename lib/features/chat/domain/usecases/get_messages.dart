import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/message.dart';
import '../repositories/chat_repository.dart';

/// Get Messages Stream Use Case
class GetMessages {

  GetMessages(this.repository);
  final ChatRepository repository;

  Stream<Either<Failure, List<Message>>> call(GetMessagesParams params) {
    return repository.getMessagesStream(
      conversationId: params.conversationId,
      userId: params.userId,
      limit: params.limit,
    );
  }
}

/// Parameters for GetMessages use case
class GetMessagesParams {

  GetMessagesParams({
    required this.conversationId,
    this.userId,
    this.limit,
  });
  final String conversationId;
  final String? userId;
  final int? limit;
}
