import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/message.dart';
import '../entities/message_page.dart';
import '../repositories/group_chat_repository.dart';

/// Stream the latest messages of a group (newest first, paginated).
class GetGroupMessages {
  GetGroupMessages(this.repository);
  final GroupChatRepository repository;

  Stream<Either<Failure, List<Message>>> call(GetGroupMessagesParams params) {
    return repository.getGroupMessagesStream(
      groupId: params.groupId,
      limit: params.limit,
    );
  }

  /// Live window of the newest [GetGroupMessagesParams.limit] messages.
  Stream<Either<Failure, MessagePage>> latest(GetGroupMessagesParams params) {
    return repository.watchLatestGroupMessages(
      groupId: params.groupId,
      limit: params.limit,
    );
  }

  /// One older page, sent before [before] (loaded on scroll).
  Future<Either<Failure, MessagePage>> older(
    GetGroupMessagesParams params, {
    required DateTime before,
  }) {
    return repository.getOlderGroupMessages(
      groupId: params.groupId,
      before: before,
      limit: params.limit,
    );
  }
}

class GetGroupMessagesParams {
  GetGroupMessagesParams({required this.groupId, this.limit});
  final String groupId;
  final int? limit;
}
