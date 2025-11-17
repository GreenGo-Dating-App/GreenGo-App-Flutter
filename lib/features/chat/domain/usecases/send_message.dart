import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/message.dart';
import '../repositories/chat_repository.dart';

/// Send Message Use Case
class SendMessage {
  final ChatRepository repository;

  SendMessage(this.repository);

  Future<Either<Failure, Message>> call(SendMessageParams params) {
    return repository.sendMessage(
      matchId: params.matchId,
      senderId: params.senderId,
      receiverId: params.receiverId,
      content: params.content,
      type: params.type,
    );
  }
}

/// Parameters for SendMessage use case
class SendMessageParams {
  final String matchId;
  final String senderId;
  final String receiverId;
  final String content;
  final MessageType type;

  SendMessageParams({
    required this.matchId,
    required this.senderId,
    required this.receiverId,
    required this.content,
    this.type = MessageType.text,
  });
}
