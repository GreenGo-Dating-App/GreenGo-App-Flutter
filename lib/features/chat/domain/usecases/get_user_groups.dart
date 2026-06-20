import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/conversation.dart';
import '../repositories/group_chat_repository.dart';

/// Stream the current user's group inbox (per-user indexed, paginated).
class GetUserGroups {
  GetUserGroups(this.repository);
  final GroupChatRepository repository;

  Stream<Either<Failure, List<Conversation>>> call(String userId) {
    return repository.getUserGroupsStream(userId);
  }
}
