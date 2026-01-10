import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/chat_repository.dart';

/// Set Typing Indicator Use Case
class SetTypingIndicator {
  final ChatRepository repository;

  SetTypingIndicator(this.repository);

  Future<Either<Failure, void>> call(SetTypingIndicatorParams params) {
    return repository.setTypingIndicator(
      conversationId: params.conversationId,
      userId: params.userId,
      isTyping: params.isTyping,
    );
  }
}

/// Parameters for SetTypingIndicator use case
class SetTypingIndicatorParams {
  final String conversationId;
  final String userId;
  final bool isTyping;

  SetTypingIndicatorParams({
    required this.conversationId,
    required this.userId,
    required this.isTyping,
  });
}
