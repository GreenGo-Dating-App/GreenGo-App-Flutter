import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/group_info.dart';
import '../../domain/entities/message.dart';
import '../../domain/repositories/group_chat_repository.dart';
import '../datasources/group_chat_remote_datasource.dart';

/// Implementation of [GroupChatRepository] backed by Firestore.
class GroupChatRepositoryImpl implements GroupChatRepository {
  GroupChatRepositoryImpl({required this.remoteDataSource});

  final GroupChatRemoteDataSource remoteDataSource;

  @override
  Future<Either<Failure, Conversation>> createGroup({
    required String creatorId,
    required String name,
    required List<String> memberIds,
    String? photoUrl,
    String? description,
    String? language,
  }) async {
    try {
      final group = await remoteDataSource.createGroup(
        creatorId: creatorId,
        name: name,
        memberIds: memberIds,
        photoUrl: photoUrl,
        description: description,
        language: language,
      );
      return Right(group.toEntity());
    } catch (e) {
      return Left(ServerFailure('Failed to create group: $e'));
    }
  }

  @override
  Stream<Either<Failure, List<Conversation>>> getUserGroupsStream(
    String userId,
  ) {
    return remoteDataSource
        .getUserGroupsStream(userId)
        .map<Either<Failure, List<Conversation>>>(
          (groups) => Right(groups.map((g) => g.toEntity()).toList()),
        )
        .handleError((Object e) => Left<Failure, List<Conversation>>(
              ServerFailure('Failed to load groups: $e'),
            ));
  }

  @override
  Stream<Either<Failure, List<Message>>> getGroupMessagesStream({
    required String groupId,
    int? limit,
  }) {
    return remoteDataSource
        .getGroupMessagesStream(
          groupId: groupId,
          limit: limit ?? GroupChatRemoteDataSourceImpl.defaultMessageLimit,
        )
        .map<Either<Failure, List<Message>>>(
          (messages) => Right(messages.map((m) => m.toEntity()).toList()),
        )
        .handleError((Object e) => Left<Failure, List<Message>>(
              ServerFailure('Failed to load messages: $e'),
            ));
  }

  @override
  Future<Either<Failure, List<Message>>> getGroupMessagesPage({
    required String groupId,
    required DateTime before,
    int? limit,
  }) async {
    try {
      final page = await remoteDataSource.getGroupMessagesPage(
        groupId: groupId,
        before: before,
        limit: limit ?? GroupChatRemoteDataSourceImpl.defaultMessageLimit,
      );
      return Right(page.map((m) => m.toEntity()).toList());
    } catch (e) {
      return Left(ServerFailure('Failed to load older messages: $e'));
    }
  }

  @override
  Future<Either<Failure, Message>> sendGroupMessage({
    required String groupId,
    required String senderId,
    required String content,
    required MessageType type,
    Map<String, dynamic>? metadata,
    String? detectedLanguage,
  }) async {
    try {
      final message = await remoteDataSource.sendGroupMessage(
        groupId: groupId,
        senderId: senderId,
        content: content,
        type: type,
        metadata: metadata,
        detectedLanguage: detectedLanguage,
      );
      return Right(message.toEntity());
    } catch (e) {
      return Left(ServerFailure('Failed to send message: $e'));
    }
  }

  @override
  Future<Either<Failure, void>> markGroupRead({
    required String groupId,
    required String userId,
  }) =>
      _guard(() =>
          remoteDataSource.markGroupRead(groupId: groupId, userId: userId));

  @override
  Stream<Either<Failure, List<GroupMember>>> getGroupMembersStream(
    String groupId,
  ) {
    return remoteDataSource
        .getGroupMembersStream(groupId)
        .map<Either<Failure, List<GroupMember>>>(Right.new)
        .handleError((Object e) => Left<Failure, List<GroupMember>>(
              ServerFailure('Failed to load members: $e'),
            ));
  }

  @override
  Future<Either<Failure, void>> addMembers({
    required String groupId,
    required String actorId,
    required List<String> memberIds,
  }) =>
      _guard(() => remoteDataSource.addMembers(
            groupId: groupId,
            actorId: actorId,
            memberIds: memberIds,
          ));

  @override
  Future<Either<Failure, void>> removeMember({
    required String groupId,
    required String actorId,
    required String memberId,
  }) =>
      _guard(() => remoteDataSource.removeMember(
            groupId: groupId,
            actorId: actorId,
            memberId: memberId,
          ));

  @override
  Future<Either<Failure, void>> leaveGroup({
    required String groupId,
    required String userId,
  }) =>
      _guard(
          () => remoteDataSource.leaveGroup(groupId: groupId, userId: userId));

  @override
  Future<Either<Failure, void>> deleteGroup({
    required String groupId,
    required String actorId,
  }) =>
      _guard(() =>
          remoteDataSource.deleteGroup(groupId: groupId, actorId: actorId));

  @override
  Future<Either<Failure, void>> updateGroupInfo({
    required String groupId,
    String? name,
    String? photoUrl,
    String? description,
    String? language,
  }) =>
      _guard(() => remoteDataSource.updateGroupInfo(
            groupId: groupId,
            name: name,
            photoUrl: photoUrl,
            description: description,
            language: language,
          ));

  @override
  Future<Either<Failure, void>> changeMemberRole({
    required String groupId,
    required String actorId,
    required String memberId,
    required GroupRole role,
  }) =>
      _guard(() => remoteDataSource.changeMemberRole(
            groupId: groupId,
            actorId: actorId,
            memberId: memberId,
            role: role,
          ));

  @override
  Future<Either<Failure, void>> addReaction({
    required String groupId,
    required String messageId,
    required String userId,
    required String emoji,
  }) =>
      _guard(() => remoteDataSource.addReaction(
            groupId: groupId,
            messageId: messageId,
            userId: userId,
            emoji: emoji,
          ));

  @override
  Future<Either<Failure, void>> removeReaction({
    required String groupId,
    required String messageId,
    required String userId,
  }) =>
      _guard(() => remoteDataSource.removeReaction(
            groupId: groupId,
            messageId: messageId,
            userId: userId,
          ));

  @override
  Future<Either<Failure, void>> deleteMessageForEveryone({
    required String groupId,
    required String messageId,
    required String actorId,
  }) =>
      _guard(() => remoteDataSource.deleteGroupMessageForEveryone(
            groupId: groupId,
            messageId: messageId,
            actorId: actorId,
          ));

  /// Wrap a void Firestore action in Either error handling.
  Future<Either<Failure, void>> _guard(Future<void> Function() action) async {
    try {
      await action();
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('$e'));
    }
  }
}
