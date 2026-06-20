import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/message.dart';
import '../repositories/group_chat_repository.dart';

/// Send a message to a group (single Firestore write; fan-out handled server-side).
class SendGroupMessage {
  SendGroupMessage(this.repository);
  final GroupChatRepository repository;

  Future<Either<Failure, Message>> call(SendGroupMessageParams params) {
    return repository.sendGroupMessage(
      groupId: params.groupId,
      senderId: params.senderId,
      content: params.content,
      type: params.type,
      metadata: params.metadata,
      detectedLanguage: params.detectedLanguage,
    );
  }
}

class SendGroupMessageParams {
  SendGroupMessageParams({
    required this.groupId,
    required this.senderId,
    required this.content,
    this.type = MessageType.text,
    this.metadata,
    this.detectedLanguage,
  });

  final String groupId;
  final String senderId;
  final String content;
  final MessageType type;
  final Map<String, dynamic>? metadata;
  final String? detectedLanguage;
}
