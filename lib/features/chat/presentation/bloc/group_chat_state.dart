import '../../domain/entities/message.dart';

/// Single-group chat states.
abstract class GroupChatState {
  const GroupChatState();
}

class GroupChatInitial extends GroupChatState {
  const GroupChatInitial();
}

class GroupChatLoading extends GroupChatState {
  const GroupChatLoading();
}

class GroupChatLoaded extends GroupChatState {
  const GroupChatLoaded({
    required this.groupId,
    required this.userId,
    required this.messages,
  });
  final String groupId;
  final String userId;
  final List<Message> messages;
}

class GroupChatError extends GroupChatState {
  const GroupChatError(this.message);
  final String message;
}

/// Transient: an action (send/admin) failed; the message stream remains valid.
class GroupChatActionFailure extends GroupChatState {
  const GroupChatActionFailure(this.message);
  final String message;
}

/// Emitted after the current user leaves the group so the UI can pop.
class GroupChatLeftSuccess extends GroupChatState {
  const GroupChatLeftSuccess();
}
