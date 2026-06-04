import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/chat_repository.dart';

/// Archive Conversation Use Case
///
/// Point 120: Archive old conversations
class ArchiveConversation {

  ArchiveConversation(this.repository);
  final ChatRepository repository;

  Future<Either<Failure, void>> call({
    required String conversationId,
    required String userId,
    required bool isArchived,
  }) async {
    return repository.archiveConversation(
      conversationId: conversationId,
      userId: userId,
      isArchived: isArchived,
    );
  }
}
