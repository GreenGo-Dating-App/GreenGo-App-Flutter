import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/group_chat_repository.dart';

/// Mark a group as read for a user (resets their unread counter).
class MarkGroupRead {
  MarkGroupRead(this.repository);
  final GroupChatRepository repository;

  Future<Either<Failure, void>> call(MarkGroupReadParams params) {
    return repository.markGroupRead(
      groupId: params.groupId,
      userId: params.userId,
    );
  }
}

class MarkGroupReadParams {
  MarkGroupReadParams({required this.groupId, required this.userId});
  final String groupId;
  final String userId;
}
