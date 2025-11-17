import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../repositories/chat_repository.dart';

/// Mute Conversation Use Case
///
/// Point 119: Mute notifications for a conversation
class MuteConversation {
  final ChatRepository repository;

  MuteConversation(this.repository);

  Future<Either<Failure, void>> call({
    required String conversationId,
    required bool isMuted,
    DateTime? mutedUntil, // null = mute indefinitely
  }) async {
    return await repository.muteConversation(
      conversationId: conversationId,
      isMuted: isMuted,
      mutedUntil: mutedUntil,
    );
  }
}
