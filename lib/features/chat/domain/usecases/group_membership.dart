import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/group_info.dart';
import '../repositories/group_chat_repository.dart';

/// Cohesive group administration use cases (membership + info + roles).
/// Grouped in one file as they share the same actor/permission semantics.

class AddGroupMembers {
  AddGroupMembers(this.repository);
  final GroupChatRepository repository;

  Future<Either<Failure, void>> call({
    required String groupId,
    required String actorId,
    required List<String> memberIds,
  }) {
    return repository.addMembers(
      groupId: groupId,
      actorId: actorId,
      memberIds: memberIds,
    );
  }
}

class RemoveGroupMember {
  RemoveGroupMember(this.repository);
  final GroupChatRepository repository;

  Future<Either<Failure, void>> call({
    required String groupId,
    required String actorId,
    required String memberId,
  }) {
    return repository.removeMember(
      groupId: groupId,
      actorId: actorId,
      memberId: memberId,
    );
  }
}

class LeaveGroup {
  LeaveGroup(this.repository);
  final GroupChatRepository repository;

  Future<Either<Failure, void>> call({
    required String groupId,
    required String userId,
  }) {
    return repository.leaveGroup(groupId: groupId, userId: userId);
  }
}

class UpdateGroupInfo {
  UpdateGroupInfo(this.repository);
  final GroupChatRepository repository;

  Future<Either<Failure, void>> call({
    required String groupId,
    String? name,
    String? photoUrl,
    String? description,
    String? language,
  }) {
    return repository.updateGroupInfo(
      groupId: groupId,
      name: name,
      photoUrl: photoUrl,
      description: description,
      language: language,
    );
  }
}

class ChangeGroupRole {
  ChangeGroupRole(this.repository);
  final GroupChatRepository repository;

  Future<Either<Failure, void>> call({
    required String groupId,
    required String actorId,
    required String memberId,
    required GroupRole role,
  }) {
    return repository.changeMemberRole(
      groupId: groupId,
      actorId: actorId,
      memberId: memberId,
      role: role,
    );
  }
}
