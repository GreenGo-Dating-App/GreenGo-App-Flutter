import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/chat_repository.dart';

/// Mute Conversation Use Case
///
/// Point 119: Mute notifications for a conversation
class MuteConversation {

  MuteConversation(this.repository);
  final ChatRepository repository;

  Future<Either<Failure, void>> call({
    required String conversationId,
    required String userId,
    required bool isMuted,
    DateTime? mutedUntil, // null = mute indefinitely
  }) async {
    return repository.muteConversation(
      conversationId: conversationId,
      userId: userId,
      isMuted: isMuted,
      mutedUntil: mutedUntil,
    );
  }
}
