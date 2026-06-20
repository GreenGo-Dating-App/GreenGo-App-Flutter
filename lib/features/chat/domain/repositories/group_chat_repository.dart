import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/conversation.dart';
import '../entities/group_info.dart';
import '../entities/message.dart';

/// Group Chat Repository
///
/// Contract for group ("Culture Circle") conversations. Isolated from the
/// legacy 1:1 [ChatRepository] and the `conversations` collection.
abstract class GroupChatRepository {
  Future<Either<Failure, Conversation>> createGroup({
    required String creatorId,
    required String name,
    required List<String> memberIds,
    String? photoUrl,
    String? description,
    String? language,
  });

  Stream<Either<Failure, List<Conversation>>> getUserGroupsStream(
    String userId,
  );

  Stream<Either<Failure, List<Message>>> getGroupMessagesStream({
    required String groupId,
    int? limit,
  });

  Future<Either<Failure, List<Message>>> getGroupMessagesPage({
    required String groupId,
    required DateTime before,
    int? limit,
  });

  Future<Either<Failure, Message>> sendGroupMessage({
    required String groupId,
    required String senderId,
    required String content,
    required MessageType type,
    Map<String, dynamic>? metadata,
    String? detectedLanguage,
  });

  Future<Either<Failure, void>> markGroupRead({
    required String groupId,
    required String userId,
  });

  Stream<Either<Failure, List<GroupMember>>> getGroupMembersStream(
    String groupId,
  );

  Future<Either<Failure, void>> addMembers({
    required String groupId,
    required String actorId,
    required List<String> memberIds,
  });

  Future<Either<Failure, void>> removeMember({
    required String groupId,
    required String actorId,
    required String memberId,
  });

  Future<Either<Failure, void>> leaveGroup({
    required String groupId,
    required String userId,
  });

  Future<Either<Failure, void>> updateGroupInfo({
    required String groupId,
    String? name,
    String? photoUrl,
    String? description,
    String? language,
  });

  Future<Either<Failure, void>> changeMemberRole({
    required String groupId,
    required String actorId,
    required String memberId,
    required GroupRole role,
  });

  Future<Either<Failure, void>> addReaction({
    required String groupId,
    required String messageId,
    required String userId,
    required String emoji,
  });

  Future<Either<Failure, void>> removeReaction({
    required String groupId,
    required String messageId,
    required String userId,
  });

  Future<Either<Failure, void>> deleteMessageForEveryone({
    required String groupId,
    required String messageId,
    required String actorId,
  });
}
