import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/message.dart';
import '../entities/message_page.dart';
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

  /// Live window of the newest [GetMessagesParams.limit] messages.
  Stream<Either<Failure, MessagePage>> latest(GetMessagesParams params) {
    return repository.watchLatestMessages(
      conversationId: params.conversationId,
      userId: params.userId,
      limit: params.limit,
    );
  }

  /// One older page, sent before [before] (loaded on scroll).
  Future<Either<Failure, MessagePage>> older(
    GetMessagesParams params, {
    required DateTime before,
  }) {
    return repository.getOlderMessages(
      conversationId: params.conversationId,
      before: before,
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
