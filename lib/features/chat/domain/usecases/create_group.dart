import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/conversation.dart';
import '../repositories/group_chat_repository.dart';

/// Create a new group ("Culture Circle").
class CreateGroup {
  CreateGroup(this.repository);
  final GroupChatRepository repository;

  Future<Either<Failure, Conversation>> call(CreateGroupParams params) {
    return repository.createGroup(
      creatorId: params.creatorId,
      name: params.name,
      memberIds: params.memberIds,
      photoUrl: params.photoUrl,
      description: params.description,
      language: params.language,
    );
  }
}

class CreateGroupParams {
  CreateGroupParams({
    required this.creatorId,
    required this.name,
    required this.memberIds,
    this.photoUrl,
    this.description,
    this.language,
  });

  final String creatorId;
  final String name;
  final List<String> memberIds;
  final String? photoUrl;
  final String? description;
  final String? language;
}
