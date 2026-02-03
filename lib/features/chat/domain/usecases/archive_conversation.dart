import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/chat_repository.dart';

/// Archive Conversation Use Case
///
/// Point 120: Archive old conversations
class ArchiveConversation {
  final ChatRepository repository;

  ArchiveConversation(this.repository);

  Future<Either<Failure, void>> call({
    required String conversationId,
    required String userId,
    required bool isArchived,
  }) async {
    return await repository.archiveConversation(
      conversationId: conversationId,
      userId: userId,
      isArchived: isArchived,
    );
  }
}
