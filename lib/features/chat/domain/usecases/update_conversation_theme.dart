import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/conversation.dart';
import '../repositories/chat_repository.dart';

/// Update Conversation Theme Use Case
///
/// Point 117: Change chat theme (gold, silver, dark, light, rose, ocean)
class UpdateConversationTheme {

  UpdateConversationTheme(this.repository);
  final ChatRepository repository;

  Future<Either<Failure, void>> call({
    required String conversationId,
    required ChatTheme theme,
  }) async {
    return repository.updateConversationTheme(
      conversationId: conversationId,
      theme: theme,
    );
  }
}
