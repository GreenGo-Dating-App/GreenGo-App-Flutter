import '../../domain/entities/group_info.dart';
import '../../domain/entities/message.dart';

/// Single-group chat events.
abstract class GroupChatEvent {
  const GroupChatEvent();
}

/// Open a group: subscribe to its messages and mark it read.
class GroupChatStarted extends GroupChatEvent {
  const GroupChatStarted({required this.groupId, required this.userId});
  final String groupId;
  final String userId;
}

class GroupChatMessageSent extends GroupChatEvent {
  const GroupChatMessageSent({
    required this.content,
    this.type = MessageType.text,
    this.metadata,
    this.detectedLanguage,
  });
  final String content;
  final MessageType type;
  final Map<String, dynamic>? metadata;
  final String? detectedLanguage;
}

class GroupChatMarkedRead extends GroupChatEvent {
  const GroupChatMarkedRead();
}

class GroupChatReactionAdded extends GroupChatEvent {
  const GroupChatReactionAdded({required this.messageId, required this.emoji});
  final String messageId;
  final String emoji;
}

class GroupChatReactionRemoved extends GroupChatEvent {
  const GroupChatReactionRemoved({required this.messageId});
  final String messageId;
}

class GroupChatMembersAdded extends GroupChatEvent {
  const GroupChatMembersAdded(this.memberIds);
  final List<String> memberIds;
}

class GroupChatMemberRemoved extends GroupChatEvent {
  const GroupChatMemberRemoved(this.memberId);
  final String memberId;
}

class GroupChatLeft extends GroupChatEvent {
  const GroupChatLeft();
}

class GroupChatInfoUpdated extends GroupChatEvent {
  const GroupChatInfoUpdated({
    this.name,
    this.photoUrl,
    this.description,
    this.language,
  });
  final String? name;
  final String? photoUrl;
  final String? description;
  final String? language;
}

class GroupChatRoleChanged extends GroupChatEvent {
  const GroupChatRoleChanged({required this.memberId, required this.role});
  final String memberId;
  final GroupRole role;
}
