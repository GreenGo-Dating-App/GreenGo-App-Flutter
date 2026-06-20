import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/group_info.dart';
import '../repositories/group_chat_repository.dart';

/// Stream the members of a group.
class GetGroupMembers {
  GetGroupMembers(this.repository);
  final GroupChatRepository repository;

  Stream<Either<Failure, List<GroupMember>>> call(String groupId) {
    return repository.getGroupMembersStream(groupId);
  }
}
