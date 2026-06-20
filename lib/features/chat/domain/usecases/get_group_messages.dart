import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/message.dart';
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
}

class GetGroupMessagesParams {
  GetGroupMessagesParams({required this.groupId, this.limit});
  final String groupId;
  final int? limit;
}
