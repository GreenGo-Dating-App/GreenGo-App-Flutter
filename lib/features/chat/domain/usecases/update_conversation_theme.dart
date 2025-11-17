import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/conversation.dart';
import '../repositories/chat_repository.dart';

/// Update Conversation Theme Use Case
///
/// Point 117: Change chat theme (gold, silver, dark, light, rose, ocean)
class UpdateConversationTheme {
  final ChatRepository repository;

  UpdateConversationTheme(this.repository);

  Future<Either<Failure, void>> call({
    required String conversationId,
    required ChatTheme theme,
  }) async {
    return await repository.updateConversationTheme(
      conversationId: conversationId,
      theme: theme,
    );
  }
}
