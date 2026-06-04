import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/chat_repository.dart';

/// Set Typing Indicator Use Case
class SetTypingIndicator {

  SetTypingIndicator(this.repository);
  final ChatRepository repository;

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

  SetTypingIndicatorParams({
    required this.conversationId,
    required this.userId,
    required this.isTyping,
  });
  final String conversationId;
  final String userId;
  final bool isTyping;
}
